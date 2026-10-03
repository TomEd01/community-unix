from django.conf import settings
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework.views import APIView
#Librerias de Google
from google.auth.transport import requests
from google.oauth2 import id_token
#Modelos locales
from .serializers import GoogleAuthSerializer
from .models import Usuario, Alumno, Instructor, Externo
#Libreria para crear un JSON Web Token (JWT)
from rest_framework_simplejwt.tokens import RefreshToken

class GoogleLoginView(generics.CreateAPIView):
    serializer_class = GoogleAuthSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        token = serializer.validated_data.get("id_token")
        rol = serializer.validated_data.get("rol", "Externo")

        try:
            # Verificamos el token con Google
            idinfo = id_token.verify_oauth2_token(token, requests.Request(), settings.GOOGLE_CLIENT_ID)
            
            # Si Google aprueba el token, nos devuelve un diccionario con los datos
            email = idinfo['email']
            nombre = idinfo.get('name', '')

            # Buscamos si el usuario ya existe o lo creamos
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
            refresh = RefreshToken.for_user(user)
            token_acceso = str(refresh.access_token)
            
            return Response({
                "mensaje": "Autenticación exitosa",
                "Email": user.email,
                "Nombre": user.nombre_completo,
                "Rol": user.rol,
                "Nuevo": created,
                "token": token_acceso,
                }, status=status.HTTP_200_OK)

        except ValueError:
            # Si el token es inválido o expiró
            return Response({"error": "Token de Google inválido"}, status=status.HTTP_400_BAD_REQUEST)
class CompletarPerfilView(APIView):
    def post(self, request):
        # Extraemos los datos que nos envían desde Flutter
        data = request.data
        email = data.get('email')
        rol = data.get('rol')

        try:
            # Verificamos si el usuario que Google creó en el paso anterior
            user = Usuario.objects.get(email=email)
        except Usuario.DoesNotExist:
            return Response({"error": "Usuario no encontrado"}, status=status.HTTP_404_NOT_FOUND)

        # Actualizamos el rol definitivo en su registro principal
        user.rol = rol
        user.save()

        # Guardamos los datos en la tabla específica según lo que eligió el usuario
        if rol == 'Alumno':
            Alumno.objects.create(
                usuario=user,
                numero_control=data.get('numero_control'),
                procedencia=data.get('procedencia')
            )
        
        elif rol == 'Instructor':
            Instructor.objects.create(
                usuario=user,
                numero_control=data.get('numero_control'),
                procedencia=data.get('procedencia'),
                departamento=data.get('departamento'),
                especialidad=data.get('especialidad'),
                grado_academico=data.get('grado_academico')
            )
            
        elif rol == 'Externo':
            Externo.objects.create(
                usuario=user,
                tipo_experiencia=data.get('tipo_experiencia'),
                organizacion=data.get('organizacion')
            )
        else:
            return Response({"error": "Rol inválido"}, status=status.HTTP_400_BAD_REQUEST)

        # Verificamos que todo este en orden y perfectamente guardado
        return Response({
            "mensaje": "Perfil completado exitosamente",
            "rol_confirmado": user.rol
        }, status=status.HTTP_200_OK)
