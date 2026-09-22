from rest_framework import serializers

class GoogleAuthSerializer(serializers.Serializer):
    # Flutter nos mandará un token cifrado kilométrico
    id_token = serializers.CharField(write_only=True)
    
    # El rol es opcional porque, si el usuario ya existe y solo está iniciando sesión,
    # no necesita mandarnos su rol otra vez. Solo lo manda en su primer registro.
    rol = serializers.CharField(max_length=50, required=False)