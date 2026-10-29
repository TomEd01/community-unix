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
    procedencia = models.CharField(max_length=100, default='itc')

class Externo(models.Model):
    usuario = models.OneToOneField(Usuario, on_delete=models.CASCADE)
    numero_control = models.CharField(max_length=50, unique=True, blank=True)
    tipo_experiencia = models.CharField(max_length=50, default='Experiencia propia')
    organizacion = models.CharField(max_length=100)

    # Sobrescribimos el método save para autogenerar el ID del externo
    def save(self, *args, **kwargs):
        # Primero generamos el ID si no existe 
        if not self.numero_control:
            generado = str(uuid.uuid4())[:8] # Genera un código aleatorio de 8 caracteres
            self.numero_control = f"U{generado}"
        super().save(*args, **kwargs)

class HorarioClase(models.Model):
    # Relaciono el bloque de clase con el Instructor; si el instructor borra su cuenta, se limpian sus horarios
    instructor = models.ForeignKey(
        Instructor, 
        on_delete=models.CASCADE, 
        related_name='horarios'
    )
    # Exijo tanto la materia como el horario para evitar confusiones cuando imparten dos grupos a la misma hora
    materia = models.CharField(max_length=120)
    horario = models.CharField(max_length=80)  # Ej. "7:00 am - 9:00 am"
    creado_en = models.DateTimeField(auto_now_add=True)

    class Meta:
        # Evito que el mismo profesor duplique por error la misma materia en el mismo horario
        unique_together = ('instructor', 'materia', 'horario')

    def __str__(self):
        return f"{self.instructor.usuario.nombre_completo} - {self.horario} ({self.materia})"

class VinculoAlumno(models.Model):
    # Uso OneToOneField para asegurar que cada alumno solo esté vinculado a un profesor/horario a la vez
    alumno = models.OneToOneField(
        Alumno, 
        on_delete=models.CASCADE, 
        related_name='vinculo'
    )
    # Uso SET_NULL: si el profesor borra su horario al acabar el semestre, el vínculo queda en NULL sin romper la cuenta del alumno
    horario_clase = models.ForeignKey(
        HorarioClase, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name='alumnos_vinculados'
    )
    # Guardo un respaldo en texto de cuál era el horario/profe por si el profesor lo elimina después
    respaldo_horario = models.CharField(max_length=255, blank=True, default='')
    actualizado_en = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.alumno.numero_control} -> {self.respaldo_horario}"