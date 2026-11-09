from django.shortcuts import render
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from django.db.models import Q
from rest_framework.response import Response

from accounts.permissions import EsSuperAdmin
from accounts.models import Instructor, Alumno
from .catalogos import LUGARES_ITC
from .models import MacroEvento

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