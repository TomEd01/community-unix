from django.conf import settings
from django.contrib.auth import get_user_model
from django.core import signing
from django.db import IntegrityError, transaction

from google.auth.transport import requests
from google.oauth2 import id_token

from rest_framework import generics, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Alumno, Instructor, Externo
from .serializers import GoogleAuthSerializer


Usuario = get_user_model()

ONBOARDING_TOKEN_SALT = "community-unix-onboarding"
ONBOARDING_TOKEN_MAX_AGE = 60 * 60  # 1 hora


# ============================================================
# GOOGLE LOGIN
# ============================================================

class GoogleLoginView(generics.CreateAPIView):
    serializer_class = GoogleAuthSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        token = serializer.validated_data.get("id_token")
        rol_recibido = serializer.validated_data.get("rol")

        try:
            # ----------------------------------------------------
            # VERIFICAR TOKEN DE GOOGLE
            # ----------------------------------------------------

            idinfo = id_token.verify_oauth2_token(
                token,
                requests.Request(),
                settings.GOOGLE_CLIENT_ID,
            )

            email = idinfo["email"]
            nombre = idinfo.get("name", "")

            # ----------------------------------------------------
            # BUSCAR O CREAR USUARIO
            # ----------------------------------------------------

            user = Usuario.objects.filter(email=email).first()

            nuevo_usuario = user is None

            if nuevo_usuario:
                user = Usuario.objects.create(
                    email=email,
                    nombre_completo=nombre,
                    rol=rol_recibido or "Pendiente",
                )

                user.set_unusable_password()
                user.save()

            elif not user.nombre_completo and nombre:
                user.nombre_completo = nombre
                user.save(
                    update_fields=["nombre_completo"]
                )

            # ----------------------------------------------------
            # COMPROBAR SI YA TIENE PERFIL
            # ----------------------------------------------------

            tiene_alumno = Alumno.objects.filter(
                usuario=user
            ).exists()

            tiene_instructor = Instructor.objects.filter(
                usuario=user
            ).exists()

            tiene_externo = Externo.objects.filter(
                usuario=user
            ).exists()

            perfil_completo = (
                tiene_alumno
                or tiene_instructor
                or tiene_externo
            )

            # ----------------------------------------------------
            # DETERMINAR ROL REAL
            # ----------------------------------------------------

            if tiene_alumno:
                rol_actual = "Alumno"

            elif tiene_instructor:
                rol_actual = "Instructor"

            elif tiene_externo:
                rol_actual = "Externo"

            else:
                rol_actual = user.rol or "Pendiente"

            # Mantener Usuario.rol sincronizado con el perfil.
            if perfil_completo and user.rol != rol_actual:
                user.rol = rol_actual
                user.save(
                    update_fields=["rol"]
                )

            # ----------------------------------------------------
            # TOKEN INTERNO PARA COMPLETAR EL REGISTRO
            # ----------------------------------------------------

            onboarding_token = signing.dumps(
                {
                    "user_id": user.pk,
                    "email": user.email,
                },
                salt=ONBOARDING_TOKEN_SALT,
            )

            # ----------------------------------------------------
            # RESPUESTA
            # ----------------------------------------------------

            return Response(
                {
                    "mensaje": "Autenticacion exitosa",
                    "email": user.email,
                    "nombre_completo": user.nombre_completo,
                    "rol": rol_actual,
                    "nuevo_usuario": nuevo_usuario,
                    "perfil_completo": perfil_completo,
                    "onboarding_token": onboarding_token,
                },
                status=status.HTTP_200_OK,
            )

        except ValueError:
            return Response(
                {
                    "error": "Token de Google invalido",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )


# ============================================================
# COMPLETAR PERFIL
# ============================================================

class CompleteProfileView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        onboarding_token = request.data.get(
            "onboarding_token"
        )

        rol = str(
            request.data.get("rol", "")
        ).strip().lower()

        # --------------------------------------------------------
        # COMPROBAR TOKEN
        # --------------------------------------------------------

        if not onboarding_token:
            return Response(
                {
                    "error": "Falta el token de registro.",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            token_data = signing.loads(
                onboarding_token,
                salt=ONBOARDING_TOKEN_SALT,
                max_age=ONBOARDING_TOKEN_MAX_AGE,
            )

        except signing.SignatureExpired:
            return Response(
                {
                    "error": (
                        "La sesion de registro expiro. "
                        "Inicia sesion con Google nuevamente."
                    ),
                },
                status=status.HTTP_401_UNAUTHORIZED,
            )

        except signing.BadSignature:
            return Response(
                {
                    "error": "Token de registro invalido.",
                },
                status=status.HTTP_401_UNAUTHORIZED,
            )

        # --------------------------------------------------------
        # BUSCAR USUARIO
        # --------------------------------------------------------

        user_id = token_data.get("user_id")

        try:
            user = Usuario.objects.get(
                pk=user_id
            )

        except Usuario.DoesNotExist:
            return Response(
                {
                    "error": "El usuario no existe.",
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        # --------------------------------------------------------
        # EVITAR COMPLETAR EL PERFIL DOS VECES
        # --------------------------------------------------------

        perfil_existente = (
            Alumno.objects.filter(usuario=user).exists()
            or Instructor.objects.filter(usuario=user).exists()
            or Externo.objects.filter(usuario=user).exists()
        )

        if perfil_existente:
            return Response(
                {
                    "mensaje": "El perfil ya estaba completo.",
                    "perfil_completo": True,
                    "rol": user.rol,
                },
                status=status.HTTP_200_OK,
            )

        # --------------------------------------------------------
        # VALIDAR ROL
        # --------------------------------------------------------

        roles_validos = {
            "alumno",
            "instructor",
            "externo",
        }

        if rol not in roles_validos:
            return Response(
                {
                    "error": "Tipo de usuario no valido.",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            with transaction.atomic():

                # ==================================================
                # ALUMNO
                # ==================================================

                if rol == "alumno":
                    numero_control = str(
                        request.data.get(
                            "numero_control",
                            "",
                        )
                    ).strip()

                    # Los alumnos por ahora son únicamente del ITC.
                    procedencia = "itc"

                    if not numero_control:
                        return Response(
                            {
                                "error": (
                                    "El numero de control "
                                    "es obligatorio."
                                ),
                            },
                            status=status.HTTP_400_BAD_REQUEST,
                        )

                    Alumno.objects.create(
                        usuario=user,
                        numero_control=numero_control,
                        procedencia=procedencia,
                    )

                    rol_final = "Alumno"

                # ==================================================
                # INSTRUCTOR
                # ==================================================

                elif rol == "instructor":
                    numero_control = str(
                        request.data.get(
                            "numero_control",
                            "",
                        )
                    ).strip()

                    departamento = str(
                        request.data.get(
                            "departamento",
                            "",
                        )
                    ).strip()

                    especialidad = str(
                        request.data.get(
                            "especialidad",
                            "",
                        )
                    ).strip()

                    grado_academico = str(
                        request.data.get(
                            "grado_academico",
                            "",
                        )
                    ).strip()

                    procedencia = str(
                        request.data.get(
                            "procedencia",
                            "",
                        )
                    ).strip()

                    if not numero_control:
                        return Response(
                            {
                                "error": (
                                    "La matricula del instructor "
                                    "es obligatoria."
                                ),
                            },
                            status=status.HTTP_400_BAD_REQUEST,
                        )

                    if not departamento:
                        return Response(
                            {
                                "error": (
                                    "El departamento es "
                                    "obligatorio."
                                ),
                            },
                            status=status.HTTP_400_BAD_REQUEST,
                        )

                    if not especialidad:
                        return Response(
                            {
                                "error": (
                                    "La especialidad es "
                                    "obligatoria."
                                ),
                            },
                            status=status.HTTP_400_BAD_REQUEST,
                        )

                    if not grado_academico:
                        return Response(
                            {
                                "error": (
                                    "El grado academico es "
                                    "obligatorio."
                                ),
                            },
                            status=status.HTTP_400_BAD_REQUEST,
                        )

                    if not procedencia:
                        return Response(
                            {
                                "error": (
                                    "La procedencia es obligatoria."
                                ),
                            },
                            status=status.HTTP_400_BAD_REQUEST,
                        )

                    Instructor.objects.create(
                        usuario=user,
                        numero_control=numero_control,
                        departamento=departamento,
                        especialidad=especialidad,
                        grado_academico=grado_academico,
                        procedencia=procedencia,
                    )

                    rol_final = "Instructor"

                # ==================================================
                # EXTERNO
                # ==================================================

                else:
                    procedencia = str(
                        request.data.get(
                            "procedencia",
                            "",
                        )
                    ).strip()

                    organizacion = str(
                        request.data.get(
                            "organizacion",
                            "",
                        )
                    ).strip()

                    if not procedencia:
                        return Response(
                            {
                                "error": (
                                    "La procedencia o tipo de "
                                    "experiencia es obligatorio."
                                ),
                            },
                            status=status.HTTP_400_BAD_REQUEST,
                        )

                    Externo.objects.create(
                        usuario=user,
                        procedencia=procedencia,
                        organizacion=organizacion,
                    )

                    rol_final = "Externo"

                # ==================================================
                # ACTUALIZAR USUARIO
                # ==================================================

                user.rol = rol_final
                user.save(
                    update_fields=["rol"]
                )

        except IntegrityError:
            return Response(
                {
                    "error": (
                        "No se pudo completar el registro. "
                        "El numero de control o matricula "
                        "ya esta registrado."
                    ),
                },
                status=status.HTTP_409_CONFLICT,
            )

        # --------------------------------------------------------
        # REGISTRO TERMINADO
        # --------------------------------------------------------

        return Response(
            {
                "mensaje": "Perfil completado correctamente.",
                "email": user.email,
                "rol": rol_final,
                "perfil_completo": True,
            },
            status=status.HTTP_201_CREATED,
        )