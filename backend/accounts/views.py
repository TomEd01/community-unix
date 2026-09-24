from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.contrib.auth import get_user_model
from django.conf import settings
# Importación de Google
from google.oauth2 import id_token
from google.auth.transport import requests
from .serializers import GoogleAuthSerializer
# get_user_model() manda llamar al AUTH_USER_MODEL del settings.py de forma segura
Usuario = get_user_model()

class GoogleLoginView(generics.CreateAPIView):
    # Usamos el serializador de Google
    serializer_class = GoogleAuthSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        # Validamos que el JSON entrante tenga el 'id_token'
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        token = serializer.validated_data.get('id_token')
        rol = serializer.validated_data.get('rol', 'Externo') # Valor por defecto

        try:
            # Verificamos el token con Google
            # PISTA 1: Necesitas agregar GOOGLE_CLIENT_ID a tu settings.py (con un string vacío por ahora) y llamarlo aquí.
            idinfo = id_token.verify_oauth2_token(token, requests.Request(), settings.GOOGLE_CLIENT_ID)
            
            # Si Google aprueba el token, nos devuelve un diccionario con los datos
            email = idinfo['email']
            nombre = idinfo.get('name', '')

            # Buscamos si el usuario ya existe o lo creamos
            # PISTA 2: Analiza este bloque. ¿Qué método de tu ManejadorUsuario debes usar si 'created' es True?
            user, created = Usuario.objects.get_or_create(
                email=email,
                defaults={
                    'nombre_completo': nombre,
                    'rol': rol,
                }
            )

            if created:
                # Este usuario NO tiene contraseña local?
                user.set_unusable_password()
                user.save()

            # Generamos los tokens de sesión de nuestro backend (JWT)
            # ..................
            
            return Response({"mensaje": "Autenticación exitosa", "email": user.email}, status=status.HTTP_200_OK)

        except ValueError:
            # Si el token es inválido o expiró
            return Response({"error": "Token de Google inválido"}, status=status.HTTP_400_BAD_REQUEST)