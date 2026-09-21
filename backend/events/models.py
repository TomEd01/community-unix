from django.db import models
from django.conf import settings
class SolicitudExpositor(models.Model):
    # 1. Menú de opciones (TextChoices): Define los estados internamente
    class Estado(models.TextChoices):
        PENDIENTE = 'PEN', 'Pendiente'
        APROBADA = 'APR', 'Aprobada'
        RECHAZADA = 'REC', 'Rechazada'

    # 2. Relación 1 a 1 con el Usuario
    usuario = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='solicitud_expositor'
    )

    # 3. Campo optimizado para textos largos
    semblanza = models.TextField(
        help_text="Descripción detallada o currículum del expositor."
    )

    # 4. Campo que permite estar vacío explícitamente
    organizacion = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        help_text="Nombre de la empresa o institución (opcional)."
    )

    # 5. Campo de estado restringido por opciones
    estado = models.CharField(
        max_length=30,
        choices=Estado.choices,
        default=Estado.PENDIENTE,
    )

    # 6. JSONField para almacenar diccionarios (ej. redes sociales)
    enlaces_redes = models.JSONField(
        default=dict,
        blank=True,
        help_text="Almacena enlaces en formato clave-valor (ej. {'linkedin': 'url', 'twitter': 'url'})."
    )
    
    # Metadatos para control interno
    fecha_solicitud = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)

    def __str__(self):
        # get_estado_display() es un método automático de Django que devuelve 'Pendiente' en lugar de 'PEN'
        return f"Solicitud de {self.usuario} - {self.get_estado_display()}"
