// Misma ruta que tus páginas de alumno. Cambia aquí la dirección si es necesario.
class ExternoConfig {
  static const perfilUrl = 'http://127.0.0.1:8000/api/auth/perfil/me/';
}

// No se reutiliza numero_control como identificador del externo.
String externoId(Map<String, dynamic> data) {
  return data['numero_control']?.toString().trim() ?? '';
}

String externoAvatarSeed(Map<String, dynamic> data) {
  final id = externoId(data);
  if (id.isNotEmpty) return id;
  return data['email']?.toString().trim().toLowerCase() ?? '';
}
