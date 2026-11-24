import '../../backend_config.dart';

// Misma ruta que tus páginas de alumno.
class ExternoConfig {
  static const perfilUrl = '$backendUrl/api/auth/perfil/me/';
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
