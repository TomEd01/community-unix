from rest_framework import serializers
from django.contrib.auth import get_user_model

# get_user_model() manda llamar al AUTH_USER_MODEL del settings.py de forma segura
Usuario = get_user_model()

class RegistroUsuarioSerializer(serializers.ModelSerializer):
    # CWrite_only=True asegura que la contraseña no viaje al frontend
    password = serializers.CharField(
        max_length=128,
        write_only=True,
        style={'input_type': 'password'} # Oculta el texto en la interfaz navegable de DRF
    )

    class Meta:
        # Vincula el serializador con tu modelo exacto
        model = Usuario
        fields = ['email', 'nombre_completo', 'password', 'rol']

    def create(self, validated_data):
        # Usa el mánager para encriptar la contraseña correctamente
        # **validated_data desempaqueta el diccionario como argumentos clave-valor
        user = Usuario.objects.create_user(**validated_data)
        return user