import uuid
from django.db import models
from accounts.models import Usuario, Instructor, Alumno


class MacroEvento(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    titulo = models.CharField(max_length=255)
    descripcion = models.TextField(blank=True, default='')
    estado = models.CharField(max_length=30, default='borrador')  # borrador, reclutando, publicado
    fecha_inicio = models.DateTimeField(null=True, blank=True)
    fecha_fin = models.DateTimeField(null=True, blank=True)
    creado_por = models.ForeignKey(
        Usuario, on_delete=models.RESTRICT, db_column='creado_por', related_name='macro_eventos_creados'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        managed = False
        db_table = 'macro_eventos'


class Actividad(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    macro_evento = models.ForeignKey(
        MacroEvento, on_delete=models.CASCADE, db_column='macro_evento_id', related_name='actividades'
    )
    titulo = models.CharField(max_length=255)
    descripcion = models.TextField(blank=True, default='')
    tipo = models.CharField(max_length=30)  # curso, exposicion, taller
    estado = models.CharField(max_length=30, default='borrador')  # reclutando, borrador, publicado
    cupo_maximo = models.IntegerField(null=True, blank=True)
    fecha_inicio = models.DateTimeField(null=True, blank=True)
    fecha_fin = models.DateTimeField(null=True, blank=True)
    lugar = models.CharField(max_length=255, null=True, blank=True)
    latitud_actividad = models.FloatField(null=True, blank=True)
    longitud_actividad = models.FloatField(null=True, blank=True)
    radio_geocerca_m = models.IntegerField(default=50)
    creado_por = models.ForeignKey(
        Usuario, on_delete=models.RESTRICT, db_column='creado_por', related_name='actividades_creadas'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    # Llaves foráneas exactas hacia accounts_instructor y accounts_alumno según base de datos
    instructor = models.ForeignKey(
        Instructor, on_delete=models.SET_NULL, null=True, blank=True, db_column='instructor_id', related_name='actividades_titular'
    )
    expositor = models.ForeignKey(
        Alumno, on_delete=models.SET_NULL, null=True, blank=True, db_column='expositor_id', related_name='actividades_expositor'
    )
    puntos_xp = models.IntegerField(null=True, blank=True, default=10)
    pin_asistencia = models.CharField(max_length=20, null=True, blank=True)
    contenido_bloques = models.JSONField(default=list, blank=True)

    class Meta:
        managed = False
        db_table = 'actividades'


class InscripcionMacro(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    usuario = models.ForeignKey(
        Usuario, on_delete=models.CASCADE, db_column='usuario_id', related_name='inscripciones_macro'
    )
    macro_evento = models.ForeignKey(
        MacroEvento, on_delete=models.CASCADE, db_column='macro_evento_id', related_name='inscritos'
    )
    profesor_referencia = models.ForeignKey(
        Usuario, on_delete=models.SET_NULL, null=True, blank=True, db_column='profesor_referencia_id'
    )
    inscrito_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = False
        db_table = 'inscripciones_macro'


class SolicitudExpositor(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    actividad = models.ForeignKey(
        Actividad, on_delete=models.CASCADE, db_column='actividad_id', related_name='solicitudes_expositor'
    )
    usuario = models.ForeignKey(
        Usuario, on_delete=models.CASCADE, db_column='usuario_id', related_name='postulaciones_expositor'
    )
    tema_propuesto = models.CharField(max_length=255)
    objetivo_platica = models.TextField()
    experiencia = models.TextField(null=True, blank=True)
    estado = models.CharField(max_length=30, default='pendiente')  # pendiente, aprobada, rechazada
    revisado_por = models.ForeignKey(
        Usuario, on_delete=models.SET_NULL, null=True, blank=True, db_column='revisado_por', related_name='solicitudes_revisadas'
    )
    revisado_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        managed = False
        db_table = 'solicitudes_expositor'


class AsistenciaActividad(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    usuario = models.ForeignKey(
        Usuario, on_delete=models.CASCADE, db_column='usuario_id', related_name='asistencias_actividades'
    )
    actividad = models.ForeignKey(
        Actividad, on_delete=models.CASCADE, db_column='actividad_id', related_name='asistencias'
    )
    metodo = models.CharField(max_length=30, default='inscripcion')  # inscripcion, check_in, manual
    latitud_alumno = models.FloatField(null=True, blank=True)
    longitud_alumno = models.FloatField(null=True, blank=True)
    distancia_metros = models.FloatField(null=True, blank=True)
    registrada_por = models.ForeignKey(
        Usuario, on_delete=models.SET_NULL, null=True, blank=True, db_column='registrada_por', related_name='asistencias_validadas'
    )
    asistio_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    estado = models.CharField(max_length=30, default='por_asistir')  # por_asistir, cursando, asistido, terminado, ausente

    class Meta:
        managed = False
        db_table = 'asistencias_actividad'


class HistorialXP(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    usuario = models.ForeignKey(
        Usuario, on_delete=models.CASCADE, db_column='usuario_id', related_name='historial_xp'
    )
    cantidad = models.IntegerField()
    tipo = models.CharField(max_length=50)
    referencia_tipo = models.CharField(max_length=50, null=True, blank=True)
    referencia_id = models.UUIDField(null=True, blank=True)
    clave_idempotencia = models.CharField(max_length=255, unique=True, null=True, blank=True)
    descripcion = models.CharField(max_length=255, blank=True, default='')
    creado_por = models.ForeignKey(
        Usuario, on_delete=models.SET_NULL, null=True, blank=True, db_column='creado_por'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = False
        db_table = 'historial_xp'


class Folio(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    codigo = models.CharField(max_length=100, unique=True)
    usuario = models.ForeignKey(
        Usuario, on_delete=models.CASCADE, db_column='usuario_id', related_name='folios'
    )
    actividad = models.ForeignKey(
        Actividad, on_delete=models.CASCADE, null=True, blank=True, db_column='actividad_id', related_name='folios_emitidos'
    )
    macro_evento = models.ForeignKey(
        MacroEvento, on_delete=models.CASCADE, null=True, blank=True, db_column='macro_evento_id', related_name='folios_emitidos'
    )
    tipo_logro = models.CharField(max_length=100)
    emitido_at = models.DateTimeField(auto_now_add=True)
    emitido_por = models.ForeignKey(
        Usuario, on_delete=models.SET_NULL, null=True, blank=True, db_column='emitido_por'
    )
    revocado_at = models.DateTimeField(null=True, blank=True)
    motivo_revocacion = models.CharField(max_length=255, null=True, blank=True)

    class Meta:
        managed = False
        db_table = 'folios'