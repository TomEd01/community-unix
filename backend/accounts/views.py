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
        rol = data.get('rol','').capitalize()

        try:
            # Verificamos si el usuario que Google creó en el paso anterior
            user = Usuario.objects.get(email=email)
        except Usuario.DoesNotExist:
            return Response({"error": "Usuario no encontrado"}, status=status.HTTP_404_NOT_FOUND)

        #Resolvemos la logica del nombre modificado en el form, lo sobrescribimos. Si no, conservamos el de Google.
        nuevo_nombre = data.get('nombre_completo')
        if nuevo_nombre:
            user.nombre_completo = nuevo_nombre
        
        # Actualizamos el rol definitivo en su registro principal
        user.rol = rol
        user.save()

        # Lógica de procedencia (aplica para alumno e instructor)
        procedencia_seleccion = data.get('procedencia')
        # Si el combobox dice "Otra institución", guardamos lo que escribió en el campo extra
        if procedencia_seleccion == 'Otra institución':
            procedencia_final = data.get('nombre_institucion', 'No especificada')
        else:
            procedencia_final = procedencia_seleccion

        # Guardamos los datos en la tabla específica según lo que eligió el usuario
        if rol == 'Alumno':
            Alumno.objects.create(
                usuario=user,
                numero_control=data.get('numero_control'),
                procedencia=procedencia_final
            )
        
        elif rol == 'Instructor':
            # Lógica dinámica para el grado académico
            grado_seleccion = data.get('grado_academico')
            if grado_seleccion == 'Otro':
                grado_final = data.get('especifica_grado', 'No especificado')
            else:
                grado_final = grado_seleccion
            Instructor.objects.create(
                usuario=user,
                numero_control=data.get('numero_control'),
                procedencia=procedencia_final,
                departamento=data.get('departamento'),
                especialidad=data.get('especialidad'),
                grado_academico=grado_final
            )
            
        elif rol == 'Externo':
            tipo_exp = data.get('tipo_experiencia')
            # Si es experiencia propia, ignoramos el campo de texto
            if tipo_exp == 'Experiencia propia':
                org_final = 'Independiente / Autodidacta'
            else:
                org_final = data.get('organizacion')
            Externo.objects.create(
                usuario=user,
                tipo_experiencia=tipo_exp,
                organizacion=org_final
            )
        else:
            return Response({"error": "Rol inválido"}, status=status.HTTP_400_BAD_REQUEST)

        # Verificamos que todo este en orden y perfectamente guardado
        return Response({
            "mensaje": "Perfil completado exitosamente",
            "rol_confirmado": user.rol,
            "nombre_actualizado": user.nombre_completo
        }, status=status.HTTP_200_OK)
