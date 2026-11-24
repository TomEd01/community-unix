import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_data.dart';
import '../backend_config.dart';

/// Conecta el catálogo de eventos con Django y conserva las rutas de ejemplo.
/// Login, perfiles, usuarios y vínculo con profesor conservan sus servicios originales.
class PortalApi {
  static const useExamples = bool.fromEnvironment(
    'PORTAL_EJEMPLOS',
    defaultValue: true,
  );

  static const _backendUrl = String.fromEnvironment(
    'PORTAL_BACKEND_URL',
    defaultValue: backendUrl,
  );
  static const _catalogPath = '/superadmin/eventos/catalogos/';

  static Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
  }) async {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    if (method.toUpperCase() == 'GET' && normalizedPath == _catalogPath) {
      return _fetchEventCatalog();
    }
    if (useExamples) {
      return PortalExamples.request(path, method: method, data: data);
    }
    // Conectar aquí los servicios reales acordados con Backend/ABD.
    // No se inventan rutas ni se cambia a ejemplos cuando un servicio real falla.
    throw Exception('Conexión pendiente con Backend/ABD para esta sección.');
  }

  static Future<Map<String, dynamic>> _fetchEventCatalog() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token')?.trim();
    if (token == null || token.isEmpty) {
      throw Exception('Inicia sesión como Super Admin para cargar el catálogo.');
    }

    final url = Uri.base.resolve(_backendUrl).resolve(_catalogPath);
    final http.Response response;
    try {
      response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));
    } on http.ClientException {
      throw Exception('No se pudo conectar a Django en ${url.origin}.');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception(
        'Django rechazó el acceso al catálogo (${response.statusCode}). '
        'Vuelve a iniciar sesión como Super Admin.',
      );
    }
    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el catálogo (HTTP ${response.statusCode}).');
    }

    final Object? catalog;
    try {
      catalog = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw Exception('Django no devolvió un catálogo en formato JSON.');
    }
    if (catalog is! Map<String, dynamic> ||
        catalog['lugares_itc'] is! List ||
        catalog['instructores'] is! List ||
        catalog['alumnos_expositores'] is! List) {
      throw Exception('La respuesta del catálogo tiene un formato inesperado.');
    }
    return catalog;
  }

  // Adaptadores de creación. Los mapas de demostración son internos;
  // no representan el contrato JSON de los serializers de producción.
  static Future<Map<String, dynamic>> creationCatalog() async {
    return {
      'encargados': await request('encargados/'),
      'lugares': ['Laboratorio de Sistemas', 'Biblioteca', 'Cecilio Chi', 'Domo', 'Aula Magna', 'Esplanada de la Facultad', 'En linea'],
    };
  }

  static Future<void> createActivity(Map<String, dynamic> data) async {
    final course = data['tipo'] == 'Curso';
    await request(
      course ? 'cursos/' : 'eventos/',
      method: 'POST',
      data: {...data, if (course) 'publicado': data['estado'] == 'Publicado'},
    );
  }

  static Future<void> upload(int module, String name, Uint8List bytes) async {
    if (useExamples) {
      PortalExamples.addDocument(module, name);
      return;
    }
    // Conectar aquí la carga real de documentos.
    throw Exception('Carga de documentos pendiente con Backend/ABD.');
  }
}

List<Map<String, dynamic>> records(dynamic value) =>
    (value as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
String errorText(Object e) => e.toString().replaceFirst('Exception: ', '');
