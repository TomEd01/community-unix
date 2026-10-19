from rest_framework.permissions import BasePermission

class EsSuperAdmin(BasePermission):
    """
    Permiso estricto con el que bloqueo el acceso a cualquier usuario
    que no tenga activada la bandera is_superuser en Supabase.
    """
    def has_permission(self, request, view):
        # Verifico que el usuario esté autenticado con su JWT y que sea explícitamente Super Admin
        return bool(
            request.user and 
            request.user.is_authenticated and 
            request.user.is_superuser
        )