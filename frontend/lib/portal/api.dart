import 'dart:typed_data';
import 'demo_data.dart';

/// Punto de integración pendiente para Backend/ABD.
/// Login, perfiles, usuarios y vínculo con profesor conservan sus servicios originales.
class PortalApi {
  static const useExamples = bool.fromEnvironment(
    'PORTAL_EJEMPLOS',
    defaultValue: true,
  );

  static Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
  }) async {
    if (useExamples) {
      return PortalExamples.request(path, method: method, data: data);
    }
    // Conectar aquí los servicios reales acordados con Backend/ABD.
    // No se inventan rutas ni se cambia a ejemplos cuando un servicio real falla.
    throw Exception('Conexión pendiente con Backend/ABD para esta sección.');
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
