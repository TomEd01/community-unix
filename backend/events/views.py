from django.db import transaction
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from django.db.models import Q, Count
from rest_framework.response import Response

from accounts.permissions import EsSuperAdmin
from accounts.models import Instructor, Alumno
from .catalogos import LUGARES_ITC
from .models import MacroEvento, Actividad
from .serializers import SuperAdminMacroEventoSerializer, SuperAdminActividadSerializer

def aplicar_geocerca_por_lugar(datos_limpios):
    """
    Si el lugar seleccionado coincide con el combobox de LUGARES_ITC,
    autocompleta latitud, longitud y radio_geocerca_m automáticamente.
    """
    nombre_lugar = (datos_limpios.get('lugar') or '').strip()
    if nombre_lugar in LUGARES_ITC:
        info_sede = LUGARES_ITC[nombre_lugar]
        return {
            "lugar": info_sede["nombre"],
            "latitud_actividad": info_sede["latitud"],
            "longitud_actividad": info_sede["longitud"],
            "radio_geocerca_m": info_sede["radio_geocerca_m"],
        }
    return {
        "lugar": nombre_lugar or None,
        "latitud_actividad": datos_limpios.get("latitud_actividad"),
        "longitud_actividad": datos_limpios.get("longitud_actividad"),
        "radio_geocerca_m": datos_limpios.get("radio_geocerca_m", 50),
    }

def obtener_contenedor_por_defecto(usuario_admin):
    """
    Para cuando en la ventana unificada se crea un Taller, Curso o Exposición suelto
    sin seleccionar un Macro Evento padre, cumpliendo el NOT NULL de Supabase.
    """
    contenedor, _ = MacroEvento.objects.get_or_create(
        titulo="Actividades Generales UNIX",
        defaults={
            "descripcion": "Contenedor general para cursos, talleres y exposiciones individuales.",
            "estado": "publicado",
            "creado_por": usuario_admin,
        }
    )
    return contenedor

class SuperAdminCatalogosEventoView(APIView):
    permission_classes = [IsAuthenticated, EsSuperAdmin]

    def get(self, request):
        # Filtro triple (?q=) para el buscador de "Encargados del evento" (Nombre, ID o Correo)
        busqueda = (request.query_params.get('q') or '').strip()

        instructores_qs = Instructor.objects.select_related('usuario').all().order_by('usuario__nombre_completo')
        alumnos_qs = Alumno.objects.select_related('usuario').all().order_by('usuario__nombre_completo')

        if busqueda:
            instructores_qs = instructores_qs.filter(
                Q(usuario__nombre_completo__icontains=busqueda) |
                Q(usuario__email__icontains=busqueda) |
                Q(numero_control__icontains=busqueda)
            )
            alumnos_qs = alumnos_qs.filter(
                Q(usuario__nombre_completo__icontains=busqueda) |
                Q(usuario__email__icontains=busqueda) |
                Q(numero_control__icontains=busqueda)
            )

        instructores_data = [
            {
                "instructor_id": inst.id,
                "usuario_id": inst.usuario.id,
                "nombre_completo": inst.usuario.nombre_completo,
                "numero_control": inst.numero_control,
                "email": inst.usuario.email,
                "rol_etiqueta": "Instructor",
            }
            for inst in instructores_qs[:30]
        ]

        expositores_data = [
            {
                "expositor_id": alum.id,
                "usuario_id": alum.usuario.id,
                "nombre_completo": alum.usuario.nombre_completo,
                "numero_control": alum.numero_control,
                "email": alum.usuario.email,
                "rol_etiqueta": "Alumno / Expositor",
            }
            for alum in alumnos_qs[:30]
        ]

        return Response({
            "lugares_itc": list(LUGARES_ITC.values()),
            "instructores": instructores_data,
            "alumnos_expositores": expositores_data,
        }, status=status.HTTP_200_OK)

class SuperAdminMacroEventosView(APIView):
    permission_classes = [IsAuthenticated, EsSuperAdmin]

    def get(self, request):
        eventos = MacroEvento.objects.select_related('creado_por').prefetch_related(
            'actividades__instructor__usuario',
            'actividades__expositor__usuario'
        ).annotate(
            total_inscritos=Count('inscritos', distinct=True)
        ).order_by('-created_at')

        resultado = []
        for ev in eventos:
            subeventos = [
                {
                    "actividad_id": str(act.id),
                    "titulo": act.titulo,
                    "descripcion": act.descripcion,
                    "tipo": act.tipo,
                    "estado": act.estado,
                    "lugar": act.lugar,
                    "cupo_ilimitado": act.cupo_maximo is None,
                    "cupo_maximo": act.cupo_maximo,
                    "puntos_xp": act.puntos_xp,
                    "instructor": act.instructor.usuario.nombre_completo if act.instructor else None,
                    "expositor": act.expositor.usuario.nombre_completo if act.expositor else None,
                }
                for act in ev.actividades.all()
            ]
            resultado.append({
                "macro_evento_id": str(ev.id),
                "titulo": ev.titulo,
                "descripcion": ev.descripcion,
                "estado": ev.estado,
                "fecha_inicio": ev.fecha_inicio,
                "fecha_fin": ev.fecha_fin,
                "total_inscritos": ev.total_inscritos,
                "total_subeventos": len(subeventos),
                "subeventos": subeventos,
            })

        return Response(resultado, status=status.HTTP_200_OK)

    def post(self, request):
        serializer = SuperAdminMacroEventoSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        safe_data = serializer.validated_data

        with transaction.atomic():
            nuevo_evento = MacroEvento.objects.create(
                titulo=safe_data['titulo'].strip(),
                descripcion=safe_data.get('descripcion', '').strip(),
                estado=safe_data.get('estado', 'borrador'),
                fecha_inicio=safe_data.get('fecha_inicio'),
                fecha_fin=safe_data.get('fecha_fin'),
                creado_por=request.user,
            )

            # Si el Super Admin agregó subeventos en el modal "Añadir subevento", los creamos de una vez
            subeventos_creados = []
            for sub in safe_data.get('subeventos', []):
                geo = aplicar_geocerca_por_lugar(sub)
                cupo_final = None if sub.get('cupo_ilimitado') else sub.get('cupo_maximo', 30)
                act = Actividad.objects.create(
                    macro_evento=nuevo_evento,
                    titulo=sub['titulo'].strip(),
                    descripcion=sub.get('descripcion', '').strip(),
                    tipo=sub.get('tipo', 'exposicion'),
                    estado=nuevo_evento.estado,
                    cupo_maximo=cupo_final,
                    lugar=geo['lugar'],
                    latitud_actividad=geo['latitud_actividad'],
                    longitud_actividad=geo['longitud_actividad'],
                    radio_geocerca_m=geo['radio_geocerca_m'],
                    puntos_xp=sub.get('puntos_xp', 10),
                    creado_por=request.user,
                )
                subeventos_creados.append(str(act.id))

        return Response({
            "mensaje": "Macro evento creado exitosamente.",
            "macro_evento_id": str(nuevo_evento.id),
            "subeventos_creados": subeventos_creados,
        }, status=status.HTTP_201_CREATED)

class SuperAdminMacroEventoDetailView(APIView):
    """
    Vista para que los Super Administradores puedan actualizar (PATCH) 
    o eliminar (DELETE) un Macro Evento específico.
    """
    permission_classes = [IsAuthenticated, EsSuperAdmin]

    # Actualizo parcialmente los detalles de un Macro Evento existente.
    def patch(self, request, macro_evento_id):
        try:
            evento = MacroEvento.objects.get(id=macro_evento_id)
        except MacroEvento.DoesNotExist:
            return Response({"error": "El Macro Evento no existe."}, status=status.HTTP_404_NOT_FOUND)

        # Valido los datos entrantes, permitiendo campos opcionales al ser una petición parcial.
        serializer = SuperAdminMacroEventoSerializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        safe_data = serializer.validated_data

        # Aplico los cambios únicamente a los campos que fueron enviados en la petición.
        if 'titulo' in safe_data:
            evento.titulo = safe_data['titulo'].strip()
        if 'descripcion' in safe_data:
            evento.descripcion = safe_data['descripcion'].strip()
        if 'estado' in safe_data:
            evento.estado = safe_data['estado']
        if 'fecha_inicio' in safe_data:
            evento.fecha_inicio = safe_data['fecha_inicio']
        if 'fecha_fin' in safe_data:
            evento.fecha_fin = safe_data['fecha_fin']

        evento.save()
        return Response({
            "mensaje": "Macro evento actualizado correctamente.",
            "macro_evento_id": str(evento.id),
            "estado": evento.estado,
        }, status=status.HTTP_200_OK)

    # Elimino de manera permanente un Macro Evento específico de la base de datos.
    def delete(self, request, macro_evento_id):
        try:
            evento = MacroEvento.objects.get(id=macro_evento_id)
        except MacroEvento.DoesNotExist:
            return Response({"error": "El Macro Evento no existe."}, status=status.HTTP_404_NOT_FOUND)

        titulo = evento.titulo
        evento.delete()
        return Response({"mensaje": f"El evento '{titulo}' fue eliminado."}, status=status.HTTP_200_OK)

class SuperAdminActividadesView(APIView):
    """
    Vista para que los Super Administradores gestionen las Actividades.
    Permite listar las actividades existentes (GET) con filtros y crear nuevas (POST).
    """

    permission_classes = [IsAuthenticated, EsSuperAdmin]

    """ 
    Obtengo la lista de todas las actividades. 
    Soporta filtrado por 'tipo' y 'estado' a través de query params.
    """
    def get(self, request):
        filtro_tipo = (request.query_params.get('tipo') or '').strip().lower().replace('ó', 'o')
        filtro_estado = (request.query_params.get('estado') or '').strip().lower()

        # Optimización de base de datos: joins relacionales y conteo de inscritos/solicitudes en una sola consulta.
        actividades_qs = Actividad.objects.select_related(
            'macro_evento', 'instructor__usuario', 'expositor__usuario'
        ).annotate(
            inscritos_actuales=Count('asistencias', distinct=True),
            solicitudes_pendientes=Count(
                'solicitudes_expositor',
                filter=Q(solicitudes_expositor__estado='pendiente'),
                distinct=True
            )
        ).order_by('-created_at')

        if filtro_tipo:
            actividades_qs = actividades_qs.filter(tipo=filtro_tipo)
        if filtro_estado:
            actividades_qs = actividades_qs.filter(estado=filtro_estado)

        lista = []
        for act in actividades_qs:
            lista.append({
                "actividad_id": str(act.id),
                "macro_evento_id": str(act.macro_evento_id),
                "macro_evento_titulo": act.macro_evento.titulo if act.macro_evento else None,
                "titulo": act.titulo,
                "descripcion": act.descripcion,
                "tipo": act.tipo,
                "estado": act.estado,
                "lugar": act.lugar,
                "latitud_actividad": act.latitud_actividad,
                "longitud_actividad": act.longitud_actividad,
                "radio_geocerca_m": act.radio_geocerca_m,
                "fecha_inicio": act.fecha_inicio,
                "fecha_fin": act.fecha_fin,
                "cupo_ilimitado": act.cupo_maximo is None,
                "cupo_maximo": act.cupo_maximo,
                "inscritos_actuales": act.inscritos_actuales,
                "lugares_disponibles": (
                    max(act.cupo_maximo - act.inscritos_actuales, 0)
                    if act.cupo_maximo is not None else None
                ),
                "puntos_xp": act.puntos_xp,
                "pin_asistencia": act.pin_asistencia,
                "contenido_bloques": act.contenido_bloques,
                "instructor": {
                    "instructor_id": act.instructor.id,
                    "nombre_completo": act.instructor.usuario.nombre_completo,
                    "numero_control": act.instructor.numero_control,
                } if act.instructor else None,
                "expositor": {
                    "expositor_id": act.expositor.id,
                    "nombre_completo": act.expositor.usuario.nombre_completo,
                    "numero_control": act.expositor.numero_control,
                } if act.expositor else None,
                "solicitudes_pendientes": act.solicitudes_pendientes,
            })

        return Response(lista, status=status.HTTP_200_OK)

    """ 
    Creo una nueva Actividad. Gestiona la asignación al Macro Evento, 
    encargados (instructor/expositor), cupos y configuración de geocerca.
    """
    def post(self, request):
        serializer = SuperAdminActividadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        safe_data = serializer.validated_data

        # Resuelvo el Macro Evento contenedor (o uso el general si crearon un Taller/Expo suelto)
        macro_id = safe_data.get('macro_evento_id')
        if macro_id:
            try:
                macro_evento = MacroEvento.objects.get(id=macro_id)
            except MacroEvento.DoesNotExist:
                return Response({"error": "El Macro Evento indicado no existe."}, status=status.HTTP_404_NOT_FOUND)
        else:
            macro_evento = obtener_contenedor_por_defecto(request.user)

        # Valido Instructor titular y Alumno Expositor si fueron seleccionados en "Encargados"
        instructor_obj = None
        if safe_data.get('instructor_id'):
            try:
                instructor_obj = Instructor.objects.get(id=safe_data['instructor_id'])
            except Instructor.DoesNotExist:
                return Response({"error": "El Instructor seleccionado no existe."}, status=status.HTTP_404_NOT_FOUND)

        expositor_obj = None
        if safe_data.get('expositor_id'):
            try:
                expositor_obj = Alumno.objects.get(id=safe_data['expositor_id'])
            except Alumno.DoesNotExist:
                return Response({"error": "El Alumno Expositor seleccionado no existe."}, status=status.HTTP_404_NOT_FOUND)

        # Resuelvo el switch de "Cupo ilimitado" y las coordenadas del combobox "Lugar"
        cupo_final = None if safe_data.get('cupo_ilimitado') else safe_data.get('cupo_maximo')
        geo = aplicar_geocerca_por_lugar(safe_data)

        nueva_act = Actividad.objects.create(
            macro_evento=macro_evento,
            titulo=safe_data['titulo'].strip(),
            descripcion=safe_data.get('descripcion', '').strip(),
            tipo=safe_data['tipo'],
            estado=safe_data.get('estado', 'borrador'),
            cupo_maximo=cupo_final,
            fecha_inicio=safe_data.get('fecha_inicio'),
            fecha_fin=safe_data.get('fecha_fin'),
            lugar=geo['lugar'],
            latitud_actividad=geo['latitud_actividad'],
            longitud_actividad=geo['longitud_actividad'],
            radio_geocerca_m=geo['radio_geocerca_m'],
            instructor=instructor_obj,
            expositor=expositor_obj,
            puntos_xp=safe_data.get('puntos_xp', 10),
            pin_asistencia=safe_data.get('pin_asistencia'),
            contenido_bloques=safe_data.get('contenido_bloques', []),
            creado_por=request.user,
        )

        return Response({
            "mensaje": f"Actividad '{nueva_act.titulo}' creada correctamente.",
            "actividad_id": str(nueva_act.id),
            "tipo": nueva_act.tipo,
            "estado": nueva_act.estado,
            "cupo_ilimitado": nueva_act.cupo_maximo is None,
            "cupo_maximo": nueva_act.cupo_maximo,
            "lugar": nueva_act.lugar,
            "radio_geocerca_m": nueva_act.radio_geocerca_m,
        }, status=status.HTTP_201_CREATED)

class SuperAdminActividadDetailView(APIView):
    """
    Vista para que los Super Administradores gestionen el detalle de una Actividad específica.
    Permite la actualización parcial (PATCH) y la eliminación (DELETE).
    """

    permission_classes = [IsAuthenticated, EsSuperAdmin]

    def patch(self, request, actividad_id):
        """ 
        Se actualiza parcialmente los datos de una actividad existente. 
        Incluye validaciones críticas de negocio, como no reducir el cupo por debajo de los inscritos.
        """
        try:
            actividad = Actividad.objects.annotate(
                inscritos_actuales=Count('asistencias', distinct=True)
            ).get(id=actividad_id)
        except Actividad.DoesNotExist:
            return Response({"error": "La actividad especificada no existe."}, status=status.HTTP_404_NOT_FOUND)

        serializer = SuperAdminActividadSerializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        safe_data = serializer.validated_data

        # Validación de la regla de la interfaz: "El cupo no puede ser menor a los inscritos actuales"
        if 'cupo_ilimitado' in safe_data and safe_data['cupo_ilimitado']:
            actividad.cupo_maximo = None
        elif 'cupo_maximo' in safe_data:
            nuevo_cupo = safe_data['cupo_maximo']
            if nuevo_cupo is not None and nuevo_cupo < actividad.inscritos_actuales:
                return Response({
                    "error": f"El cupo ({nuevo_cupo}) no puede ser menor a los inscritos actuales ({actividad.inscritos_actuales})."
                }, status=status.HTTP_400_BAD_REQUEST)
            actividad.cupo_maximo = nuevo_cupo

        if 'titulo' in safe_data:
            actividad.titulo = safe_data['titulo'].strip()
        if 'descripcion' in safe_data:
            actividad.descripcion = safe_data['descripcion'].strip()
        if 'tipo' in safe_data:
            actividad.tipo = safe_data['tipo']
        if 'estado' in safe_data:
            actividad.estado = safe_data['estado']
        if 'fecha_inicio' in safe_data:
            actividad.fecha_inicio = safe_data['fecha_inicio']
        if 'fecha_fin' in safe_data:
            actividad.fecha_fin = safe_data['fecha_fin']
        if 'puntos_xp' in safe_data:
            actividad.puntos_xp = safe_data['puntos_xp']
        if 'pin_asistencia' in safe_data:
            actividad.pin_asistencia = safe_data['pin_asistencia']
        if 'contenido_bloques' in safe_data:
            actividad.contenido_bloques = safe_data['contenido_bloques']
        
        # Si se cambia el lugar, recalculamos automáticamente los parámetros de la geocerca.
        if 'lugar' in safe_data:
            geo = aplicar_geocerca_por_lugar(safe_data)
            actividad.lugar = geo['lugar']
            actividad.latitud_actividad = geo['latitud_actividad']
            actividad.longitud_actividad = geo['longitud_actividad']
            actividad.radio_geocerca_m = geo['radio_geocerca_m']

        # Actualización de encargados (Instructor y Expositor). Permite desasignarlos enviando None.
        if 'instructor_id' in safe_data:
            if safe_data['instructor_id'] is None:
                actividad.instructor = None
            else:
                try:
                    actividad.instructor = Instructor.objects.get(id=safe_data['instructor_id'])
                except Instructor.DoesNotExist:
                    return Response({"error": "El Instructor no existe."}, status=status.HTTP_404_NOT_FOUND)

        if 'expositor_id' in safe_data:
            if safe_data['expositor_id'] is None:
                actividad.expositor = None
            else:
                try:
                    actividad.expositor = Alumno.objects.get(id=safe_data['expositor_id'])
                except Alumno.DoesNotExist:
                    return Response({"error": "El Alumno Expositor no existe."}, status=status.HTTP_404_NOT_FOUND)

        actividad.save()
        return Response({
            "mensaje": "Actividad actualizada correctamente.",
            "actividad_id": str(actividad.id),
            "estado": actividad.estado,
            "cupo_ilimitado": actividad.cupo_maximo is None,
            "cupo_maximo": actividad.cupo_maximo,
        }, status=status.HTTP_200_OK)

    # Elimino de manera permanente una actividad específica de la base de datos.
    def delete(self, request, actividad_id):
        try:
            actividad = Actividad.objects.get(id=actividad_id)
        except Actividad.DoesNotExist:
            return Response({"error": "La actividad no existe."}, status=status.HTTP_404_NOT_FOUND)

        titulo = actividad.titulo
        actividad.delete()
        return Response({"mensaje": f"La actividad '{titulo}' fue eliminada."}, status=status.HTTP_200_OK)