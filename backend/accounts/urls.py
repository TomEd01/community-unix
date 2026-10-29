from django.urls import path
from .views import GoogleLoginView, CompletarPerfilView, MiPerfilView, InstructorHorariosView, InstructorHorarioDetailView, CatalogoProfesoresView, MiVinculoAlumnoView, SuperAdminDashboardView, SuperAdminUsuarioDetailView

urlpatterns = [
    # Django exige que las vistas basadas en clases usen el método .as_view() al final.
    path('google/', GoogleLoginView.as_view(), name='google_login'),
    path('completar_perfil/', CompletarPerfilView.as_view(), name='completar_perfil'),
    path('perfil/me/', MiPerfilView.as_view(), name='mi_perfil'),

    # Rutas para la Vista del Instructor
    path('instructor/horarios/', InstructorHorariosView.as_view(), name='instructor-horarios'),
    path('instructor/horarios/<int:horario_id>/', InstructorHorarioDetailView.as_view(), name='instructor-horario-eliminar'),
    
    # Rutas para la Vista del Alumno
    path('alumno/profesores/', CatalogoProfesoresView.as_view(), name='catalogo-profesores'),
    path('alumno/mi-vinculo/', MiVinculoAlumnoView.as_view(), name='alumno-mi-vinculo'),

    # Rutas para la Vista de Super Admin
    path('superadmin/dashboard/', SuperAdminDashboardView.as_view(), name='superadmin-dashboard'),
    path('superadmin/usuarios/<int:usuario_id>/', SuperAdminUsuarioDetailView.as_view(), name='superadmin-gestionar-usuario'),
]