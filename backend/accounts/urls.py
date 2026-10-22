from django.urls import path
from .views import GoogleLoginView, CompletarPerfilView, MiPerfilView, InstructorHorariosView, InstructorHorarioDetailView, CatalogoProfesoresView, MiVinculoAlumnoView

urlpatterns = [
    # Django exige que las vistas basadas en clases usen el método .as_view() al final.
    path('google/', GoogleLoginView.as_view(), name='google_login'),
    path('completar_perfil/', CompletarPerfilView.as_view(), name='completar_perfil'),
    path('perfil/me/', MiPerfilView.as_view(), name='mi_perfil'),

    # Rutas para la Vista del Instructor
    path('api/instructor/horarios/', InstructorHorariosView.as_view(), name='instructor-horarios'),
    path('api/instructor/horarios/<int:horario_id>/', InstructorHorarioDetailView.as_view(), name='instructor-horario-eliminar'),
    
    # Rutas para la Vista del Alumno
    path('api/alumno/profesores/', CatalogoProfesoresView.as_view(), name='catalogo-profesores'),
    path('api/alumno/mi-vinculo/', MiVinculoAlumnoView.as_view(), name='alumno-mi-vinculo'),
]