from rest_framework import serializers

class GoogleAuthSerializer(serializers.Serializer):
    # Flutter nos mandará un token cifrado kilométrico
    id_token = serializers.CharField(write_only=True)
    
    # El rol es opcional porque, si el usuario ya existe y solo está iniciando sesión,
    # no necesita mandarnos su rol otra vez. Solo lo manda en su primer registro.
    rol = serializers.CharField(max_length=50, required=False)
class CompletarPerfilSerializer(serializers.Serializer):
    # Se arreglan las mayúsculas automáticamente
    def to_internal_value(self, data):
        # Hacemos una copia para no modificar el inmutable original
        mutable_data = data.copy()
        
        # Si viene un rol en minúscula, lo capitalizamos ('alumno' -> 'Alumno')
        if 'rol' in mutable_data and isinstance(mutable_data['rol'], str):
            mutable_data['rol'] = mutable_data['rol'].capitalize()
            
        # Le pasamos los datos arreglados al validador normal
        return super().to_internal_value(mutable_data)
    """
    Bloqueará automáticamente cualquier campo extraño,
    inyección de código o tipos de datos incorrectos (ej. arrays en lugar de texto).
    """
    email = serializers.EmailField(required=False)
    # Validamos que no intenten inyectar un rol de administrador
    rol = serializers.ChoiceField(choices=['Alumno', 'Instructor', 'Externo'])
    nombre_completo = serializers.CharField(max_length=255, required=False, allow_blank=True)
    
    # Campos de Alumno e Instructor
    numero_control = serializers.CharField(max_length=50, required=False, allow_blank=True)
    procedencia = serializers.CharField(max_length=100, required=False, allow_blank=True)
    nombre_institucion = serializers.CharField(max_length=100, required=False, allow_blank=True)
    
    # Campos exclusivos de Instructor
    departamento = serializers.CharField(max_length=100, required=False, allow_blank=True)
    especialidad = serializers.CharField(max_length=100, required=False, allow_blank=True)
    grado_academico = serializers.CharField(max_length=50, required=False, allow_blank=True)
    especifica_grado = serializers.CharField(max_length=50, required=False, allow_blank=True)
    
    # Campos exclusivos de Externo
    tipo_experiencia = serializers.CharField(max_length=50, required=False, allow_blank=True)
    organizacion = serializers.CharField(max_length=100, required=False, allow_blank=True)

class PerfilUpdateSerializer(serializers.Serializer):
    # Expongo únicamente los campos permitidos para edición (bloqueo email y numero_control)
    nombre_completo = serializers.CharField(max_length=255, required=False, allow_blank=True)
    
    # Campos editables para Alumno e Instructor
    procedencia = serializers.CharField(max_length=100, required=False, allow_blank=True)
    nombre_institucion = serializers.CharField(max_length=100, required=False, allow_blank=True)
    
    # Campos editables exclusivos de Instructor
    departamento = serializers.CharField(max_length=100, required=False, allow_blank=True)
    especialidad = serializers.CharField(max_length=100, required=False, allow_blank=True)
    grado_academico = serializers.CharField(max_length=50, required=False, allow_blank=True)
    especifica_grado = serializers.CharField(max_length=50, required=False, allow_blank=True)
    
    # Campos editables exclusivos de Externo
    tipo_experiencia = serializers.CharField(max_length=50, required=False, allow_blank=True)
    organizacion = serializers.CharField(max_length=100, required=False, allow_blank=True)

class HorarioClaseSerializer(serializers.Serializer):
    # Valido estrictamente que el Instructor envíe materia y horario sin dejar campos en blanco
    materia = serializers.CharField(max_length=120, required=True, allow_blank=False)
    horario = serializers.CharField(max_length=80, required=True, allow_blank=False)

    def validate_materia(self, value):
        limpio = value.strip()
        if not limpio:
            raise serializers.ValidationError("El nombre de la materia no puede estar vacío.")
        return limpio

    def validate_horario(self, value):
        limpio = value.strip()
        if not limpio:
            raise serializers.ValidationError("El horario no puede estar vacío.")
        return limpio


class VincularHorarioSerializer(serializers.Serializer):
    # Recibo únicamente el ID numérico del bloque de horario que el alumno seleccionó
    horario_id = serializers.IntegerField(required=True)