from django.urls import path
from .views import GoogleLoginView

urlpatterns = [
    # Django exige que las vistas basadas en clases usen el método .as_view() al final.
    path('google/', GoogleLoginView.as_view(), name='google_login'),
]