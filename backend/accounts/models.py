import uuid
from django.contrib.auth.models import BaseUserManager, AbstractBaseUser, PermissionsMixin
from django.db import models
# Create your models here.
class ManejadorUsuario(BaseUserManager):
    def create_user(self, email, nombre_completo, password=None):
        if not email:
            raise ValueError('El usuario debe tener un correo electrónico')
        
        email = self.normalize_email(email)
        user = self.model(email=email, nombre_completo=nombre_completo)
        
        # Encripta la contraseña de forma segura
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, nombre_completo, password=None):
        user = self.create_user(
            email=email,
            password=password,
            nombre_completo=nombre_completo,
        )
        # Otorga permisos de administración
        user.is_staff = True
        user.is_superuser = True
        user.save(using=self._db)
        return user


class Usuario(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(unique=True)
    nombre_completo = models.CharField(max_length=255)
    rol = models.CharField(max_length=50)
    
    # Permisos básicos requeridos por Django
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    
    # Inyectamos el Custom Manager
    objects = ManejadorUsuario()
    
    # Sintaxis de las variables de configuración
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['nombre_completo']

    def __str__(self):
        return self.email
class Alumno(models.Model):
    # CASCADE para evitar registros fantasma
    usuario = models.OneToOneField(Usuario, on_delete=models.CASCADE)
    numero_control = models.CharField(max_length=20, unique=True)
    # Por defecto, asumimos que son del instituto local
    procedencia = models.CharField(max_length=100, default='itc')

class Instructor(models.Model):
    usuario = models.OneToOneField(Usuario, on_delete=models.CASCADE)
    numero_control = models.CharField(max_length=20, unique=True)
    departamento = models.CharField(max_length=100)
    especialidad = models.CharField(max_length=100)
    grado_academico = models.CharField(max_length=50)

class Externo(models.Model):
    usuario = models.OneToOneField(Usuario, on_delete=models.CASCADE)
    numero_control = models.CharField(max_length=50, unique=True, blank=True)
    procedencia = models.CharField(max_length=100)
    organizacion = models.CharField(max_length=100)

    # Sobrescribimos el método save para autogenerar el ID del externo
    def save(self, *args, **kwargs):
        # Primero generamos el ID si no existe 
        if not self.numero_control:
            generado = str(uuid.uuid4())[:8] # Genera un código aleatorio de 8 caracteres
            self.numero_control = f"unix-{generado}"
        super().save(*args, **kwargs)