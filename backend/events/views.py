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
from .serializers import SuperAdminMacroEventoSerializer

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