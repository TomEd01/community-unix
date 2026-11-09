"""
URL configuration for backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from events.views import (
    SuperAdminCatalogosEventoView,
    SuperAdminMacroEventosView,
    SuperAdminMacroEventoDetailView,
    SuperAdminActividadesView,
    SuperAdminActividadDetailView,
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('accounts.urls')),

    # CRUD de Super Admin para Eventos, Actividades y Catálogos
    path('superadmin/eventos/catalogos/', SuperAdminCatalogosEventoView.as_view(), name='superadmin-eventos-catalogos'),
    path('superadmin/macro-eventos/', SuperAdminMacroEventosView.as_view(), name='superadmin-macro-eventos'),
    path('superadmin/macro-eventos/<uuid:macro_evento_id>/', SuperAdminMacroEventoDetailView.as_view(), name='superadmin-macro-evento-detail'),
    path('superadmin/actividades/', SuperAdminActividadesView.as_view(), name='superadmin-actividades'),
    path('superadmin/actividades/<uuid:actividad_id>/', SuperAdminActividadDetailView.as_view(), name='superadmin-actividad-detail'),
]
