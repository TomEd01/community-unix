from django.conf import settings
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
#Librerias de Google
from google.auth.transport import requests
from google.oauth2 import id_token
#Modelos locales
from .serializers import GoogleAuthSerializer, CompletarPerfilSerializer, PerfilUpdateSerializer
from .models import Usuario, Alumno, Instructor, Externo
#Libreria para crear un JSON Web Token (JWT)
from rest_framework_simplejwt.tokens import RefreshToken
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt

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
@method_decorator(csrf_exempt, name='dispatch')
class CompletarPerfilView(APIView):
    # Se exige el token JWT: Si la petición no trae un token válido, 
    # Django la rechaza automáticamente con un error 401 Unauthorized.
    permission_classes = [IsAuthenticated]
    def post(self, request):
        # Si envían un array, código malicioso o campos ocultos, DRF aborta aquí mismo (raise_exception=True)
        serializer = CompletarPerfilSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        # Se extrae los datos ya limpios y seguros
        safe_data = serializer.validated_data
        
        rol = safe_data.get('rol').capitalize()
        """
            BOLA/IDOR SOLUCIONADO: Ya no buscamos al usuario por el email del JSON.
            request.user es la identidad criptográfica verificada por el Token JWT.
            Es imposible que un usuario modifique a otro.
        """
        user = request.user

        # Resolvemos el nombre modificado
        nuevo_nombre = safe_data.get('nombre_completo')
        if nuevo_nombre:
            user.nombre_completo = nuevo_nombre
        
        # Actualizamos el rol definitivo en su registro principal
        user.rol = rol
        user.save()

        # Lógica de procedencia (aplica para alumno e instructor)
        procedencia_seleccion = safe_data.get('procedencia')
        # Si el combobox dice "Otra institución", guardamos lo que escribió en el campo extra
        if procedencia_seleccion == 'Otra institución':
            procedencia_final = safe_data.get('nombre_institucion', 'No especificada')
        else:
            procedencia_final = procedencia_seleccion

        # Guardado en base de datos (protegido contra asignación masiva)
        if rol == 'Alumno':
            Alumno.objects.update_or_create(
                usuario=user,
                numero_control=safe_data.get('numero_control'),
                procedencia=procedencia_final
            )
        
        elif rol == 'Instructor':
            # Lógica dinámica para el grado académico
            grado_seleccion = safe_data.get('grado_academico')
            if grado_seleccion == 'Otro':
                grado_final = safe_data.get('especifica_grado', 'No especificado')
            else:
                grado_final = grado_seleccion
            Instructor.objects.update_or_create(
                usuario=user,
                numero_control=safe_data.get('numero_control'),
                procedencia=procedencia_final,
                departamento=safe_data.get('departamento'),
                especialidad=safe_data.get('especialidad'),
                grado_academico=grado_final
            )
            
        elif rol == 'Externo':
            tipo_exp = safe_data.get('tipo_experiencia')
            # Si es experiencia propia, ignoramos el campo de texto
            if tipo_exp == 'Experiencia propia':
                org_final = 'Independiente / Autodidacta'
            else:
                org_final = safe_data.get('organizacion')
            Externo.objects.update_or_create(
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
class MiPerfilView(APIView):
    # EXIGIMOS EL TOKEN JWT. Sin él, nadie entra.
    permission_classes = [IsAuthenticated]
    def get(self,request):
        # Devolvemos los datos actuales del usuario para que Flutter rellene los TextFields.
        user = request.user
        # Datos base que todos tienen
        data = {
            "email": user.email,
            "nombre_completo": user.nombre_completo,
            "rol": user.rol,
        }
        try:
            if user.rol == 'Alumno':
                alumno = Alumno.objects.get(usuario=user)
                data['numero_control'] = alumno.numero_control
                data['procedencia'] = alumno.procedencia
                
            elif user.rol == 'Instructor':
                instructor = Instructor.objects.get(usuario=user)
                data['numero_control'] = instructor.numero_control
                data['procedencia'] = instructor.procedencia
                data['departamento'] = instructor.departamento
                data['especialidad'] = instructor.especialidad
                data['grado_academico'] = instructor.grado_academico
                
            elif user.rol == 'Externo':
                externo = Externo.objects.get(usuario=user)
                data['numero_control'] = externo.numero_control # Es el U+UUID
                data['tipo_experiencia'] = externo.tipo_experiencia
                data['organizacion'] = externo.organizacion
        except (Alumno.DoesNotExist, Instructor.DoesNotExist, Externo.DoesNotExist):
            return Response({"error": "Perfil detallado no encontrado"}, status=status.HTTP_404_NOT_FOUND)
        return Response(data, status=status.HTTP_200_OK)
    def patch(self, request):
        # Recibe solo los datos que el usuario modifico y los guarda con la capa de seguridad
        user = request.user
        serializer = PerfilUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        safe_data = serializer.validated_data
        # Actualizamos el nombre base si lo enviaron
        if 'nombre_completo' in safe_data:
            user.nombre_completo = safe_data['nombre_completo']
            user.save()
        # Resolvemos procedencia dinámica (Igual que en el registro)
        procedencia_seleccion = safe_data.get('procedencia')
        if procedencia_seleccion == 'Otra institución':
            procedencia_final = safe_data.get('nombre_institucion', 'No especificada')
        else:
            procedencia_final = procedencia_seleccion
        try:
            if user.rol == 'Alumno':
                alumno = Alumno.objects.get(usuario=user)
                if procedencia_seleccion:
                    alumno.procedencia = procedencia_final
                alumno.save()
            elif user.rol == 'Instructor':
                instructor = Instructor.objects.get(usuario=user)
                if procedencia_seleccion:
                    instructor.procedencia = procedencia_final
                if 'departamento' in safe_data: instructor.departamento = safe_data['departamento']
                if 'especialidad' in safe_data: instructor.especialidad = safe_data['especialidad']
                
                grado_seleccion = safe_data.get('grado_academico')
                if grado_seleccion:
                    instructor.grado_academico = safe_data.get('especifica_grado', 'No especificado') if grado_seleccion == 'Otro' else grado_seleccion
                instructor.save()
            elif user.rol == 'Externo':
                externo = Externo.objects.get(usuario=user)
                tipo_exp = safe_data.get('tipo_experiencia')
                if tipo_exp:
                    externo.tipo_experiencia = tipo_exp
                    externo.organizacion = 'Independiente / Autodidacta' if tipo_exp == 'Experiencia propia' else safe_data.get('organizacion', externo.organizacion)
                externo.save()
        except (Alumno.DoesNotExist, Instructor.DoesNotExist, Externo.DoesNotExist):
            return Response({"error": "No se pudo actualizar el perfil detallado"}, status=status.HTTP_400_BAD_REQUEST)
        return Response({
            "mensaje": "Perfil actualizado correctamente",
            "nombre_actualizado": user.nombre_completo
        }, status=status.HTTP_200_OK)