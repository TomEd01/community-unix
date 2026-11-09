from rest_framework import serializers

class SubeventoModalSerializer(serializers.Serializer):
    """Valida cada subevento añadido desde el modal 'Añadir subevento'."""
    titulo = serializers.CharField(max_length=160, required=True)
    descripcion = serializers.CharField(required=False, allow_blank=True, default='')
    lugar = serializers.CharField(max_length=200, required=False, allow_blank=True, allow_null=True)
    tipo = serializers.ChoiceField(
        choices=['curso', 'exposicion', 'taller'],
        default='exposicion'
    )
    cupo_ilimitado = serializers.BooleanField(required=False, default=False)
    cupo_maximo = serializers.IntegerField(required=False, allow_null=True, min_value=1, default=30)
    puntos_xp = serializers.IntegerField(required=False, min_value=1, default=10)

    def to_internal_value(self, data):
        mutable = data.copy() if hasattr(data, 'copy') else dict(data)
        if 'tipo' in mutable and isinstance(mutable['tipo'], str):
            # Normalizo tildes y mayúsculas ('Exposición' -> 'exposicion')
            limpio = mutable['tipo'].strip().lower().replace('ó', 'o')
            mutable['tipo'] = limpio
        return super().to_internal_value(mutable)

class SuperAdminMacroEventoSerializer(serializers.Serializer):
    """Valida la creación y edición de un Macro Evento (y sus subeventos opcionales)."""
    titulo = serializers.CharField(max_length=160, required=True)
    descripcion = serializers.CharField(required=False, allow_blank=True, default='')
    estado = serializers.ChoiceField(
        choices=['borrador', 'reclutando', 'publicado', 'finalizado'],
        default='borrador'
    )
    fecha_inicio = serializers.DateTimeField(required=False, allow_null=True)
    fecha_fin = serializers.DateTimeField(required=False, allow_null=True)
    # Lista opcional que envía el modal 'Añadir subevento'
    subeventos = SubeventoModalSerializer(many=True, required=False)

    def to_internal_value(self, data):
        mutable = data.copy() if hasattr(data, 'copy') else dict(data)
        if 'estado' in mutable and isinstance(mutable['estado'], str):
            mutable['estado'] = mutable['estado'].strip().lower()
        return super().to_internal_value(mutable)