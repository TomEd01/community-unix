import 'dart:convert';

/// TODOS los ejemplos de las pantallas nuevas están aquí.
/// Solo memoria: no se escriben en BD, SharedPreferences ni en el backend.
/// Se reinician con Hot Restart o al recargar/cerrar la app.
class PortalExamples {
  static int _nextId = 1000;
  static final List<Map<String, dynamic>> courses = [
    {
      'id': 1,
      'titulo': 'Linux básico',
      'descripcion': 'Ejemplo: aprende los comandos esenciales de la terminal.',
      'publicado': true,
      'progreso': 50,
      'modulos': <Map<String, dynamic>>[
        {
          'id': 11,
          'titulo': 'Primeros pasos en Linux',
          'descripcion':
              'Ejemplo de información del módulo: navegación y estructura de archivos.',
          'orden': 1,
          'xp': 50,
          'completado': true,
          'video_url': '',
          'video_embed': '',
          'materiales': [],
        },
        {
          'id': 12,
          'titulo': 'Comandos de la terminal',
          'descripcion':
              'Ejemplo: practica pwd, ls y cd. Agrega un enlace de video desde Super Admin.',
          'orden': 2,
          'xp': 50,
          'completado': false,
          'video_url': '',
          'video_embed': '',
          'materiales': [],
        },
      ],
    },
    {
      'id': 2,
      'titulo': 'Python desde cero',
      'descripcion': 'Ejemplo de curso asíncrono con variables y funciones.',
      'publicado': true,
      'progreso': 0,
      'modulos': <Map<String, dynamic>>[
        {
          'id': 21,
          'titulo': 'Variables y tipos de datos',
          'descripcion': 'Ejemplo de contenido para visualizar el diseño.',
          'orden': 1,
          'xp': 50,
          'completado': false,
          'video_url': '',
          'video_embed': '',
          'materiales': [],
        },
      ],
    },
  ];
  static final List<Map<String, dynamic>> instructors = [
    {'id': 1, 'nombre': 'Profesor de ejemplo A', 'numero_control': 'DEMO-001'},
    {'id': 2, 'nombre': 'Profesora de ejemplo B', 'numero_control': 'DEMO-002'},
    {'id': 3, 'nombre': 'Profesor de ejemplo C', 'numero_control': 'DEMO-003'},
  ];
  static final List<Map<String, dynamic>> events = [
    _event(1, 'Linux Install Fest', 'Evento', 'Reclutando', 30, 18, 5),
    _event(2, 'Taller de Python', 'Taller', 'Publicado', 20, 20, 7),
    _event(
      3,
      'Mi primera experiencia con Linux',
      'Exposición',
      'Publicado',
      40,
      8,
      10,
    ),
  ];
  static Map<String, dynamic> _event(
    int id,
    String title,
    String type,
    String state,
    int limit,
    int count,
    int days,
  ) => {
    'id': id,
    'titulo': title,
    'descripcion': 'Actividad de ejemplo para probar el diseño y sus botones.',
    'tipo': type,
    'estado': state,
    'fecha': DateTime.now().add(Duration(days: days)).toUtc().toIso8601String(),
    'lugar': 'Laboratorio de ejemplo',
    'cupo': limit,
    'inscritos': count,
    'disponibles': limit - count,
    'inscrito': false,
    'solicitud': null,
    'encargados_ids': [1],
    'encargados': [Map<String, dynamic>.from(instructors.first)],
  };
  static final Map<int, List<Map<String, dynamic>>> applications = {
    1: [
      {
        'id': 101,
        'nombre': 'Solicitante de ejemplo A',
        'experiencia':
            'Ejemplo: dos años practicando Linux y apoyando a estudiantes.',
        'propuesta': 'Ejemplo: introducción práctica a la terminal.',
        'estado': 'Pendiente',
      },
      {
        'id': 102,
        'nombre': 'Solicitante de ejemplo B',
        'experiencia': 'Ejemplo: conocimientos de redes y servidores.',
        'propuesta': 'Ejemplo: configuración de un servidor local.',
        'estado': 'Pendiente',
      },
    ],
  };
  static int _xp = 550;
  static dynamic _copy(dynamic value) => jsonDecode(jsonEncode(value));
  static Map<String, dynamic> _find(List<Map<String, dynamic>> list, int id) =>
      list.firstWhere(
        (e) => e['id'] == id,
        orElse: () => throw Exception('No se encontró el ejemplo solicitado.'),
      );
  static Map<String, dynamic> _courseForModule(int id) => courses.firstWhere(
    (c) => (c['modulos'] as List).any((m) => m['id'] == id),
  );
  static Map<String, dynamic> _module(int id) =>
      (_courseForModule(id)['modulos'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((m) => m['id'] == id);
  static void _progress(Map<String, dynamic> c) {
    final modules = c['modulos'] as List;
    modules.sort((a, b) => (a['orden'] as int).compareTo(b['orden'] as int));
    c['progreso'] = modules.isEmpty
        ? 0
        : (100 *
                  modules.where((m) => m['completado'] == true).length /
                  modules.length)
              .round();
  }

  static void _capacity(Map<String, dynamic> e) {
    e['disponibles'] = e['cupo_ilimitado'] == true
        ? null
        : (e['cupo'] as int) - (e['inscritos'] as int);
  }
  static String _embed(String url) {
    final u = Uri.tryParse(url);
    if (u == null || u.scheme != 'https') return '';
    String? id;
    if (['youtube.com', 'www.youtube.com', 'm.youtube.com'].contains(u.host)) {
      id = u.queryParameters['v'];
      if (u.pathSegments.length == 2 &&
          ['embed', 'shorts'].contains(u.pathSegments.first)) {
        id = u.pathSegments[1];
      }
    } else if (u.host == 'youtu.be' && u.pathSegments.isNotEmpty) {
      id = u.pathSegments.first;
    }
    if (id != null && RegExp(r'^[\w-]{11}$').hasMatch(id)) {
      return 'https://www.youtube-nocookie.com/embed/$id';
    }
    if (['vimeo.com', 'www.vimeo.com'].contains(u.host) &&
        u.pathSegments.length == 1 &&
        int.tryParse(u.pathSegments.first) != null) {
      return 'https://player.vimeo.com/video/${u.pathSegments.first}';
    }
    return '';
  }

  static void addDocument(int module, String name) {
    (_module(module)['materiales'] as List).add({
      'id': _nextId++,
      'nombre': name,
      'url': '',
      'ejemplo': true,
    });
  }

  static dynamic request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
  }) {
    final p = Uri.parse(
      path,
    ).path.split('/').where((s) => s.isNotEmpty).toList();
    final d = data ?? <String, dynamic>{};
    if (p.first == 'dashboard') {
      // El nombre se omite expresamente: Dashboard usa el perfil REAL del login.
      return _copy({
        'nivel': _xp ~/ 500 + 1,
        'xp': _xp,
        'xp_siguiente': 500 - _xp % 500,
        'progreso_nivel': (_xp % 500) / 500,
        'cursos': courses.where((c) => c['publicado'] == true).toList(),
        'eventos': events
            .where(
              (e) => e['tipo'] != 'Exposición' && e['estado'] != 'Borrador',
            )
            .toList(),
        'exposiciones': events
            .where(
              (e) => e['tipo'] == 'Exposición' && e['estado'] != 'Borrador',
            )
            .toList(),
      });
    }
    if (p.first == 'encargados') return _copy(instructors);
    if (p.first == 'cursos') {
      if (p.length == 1) {
        if (method == 'POST') {
          courses.add({
            'id': _nextId++,
            ...d,
            'progreso': 0,
            'modulos': <Map<String, dynamic>>[],
          });
        }
        return _copy(courses);
      }
      final c = _find(courses, int.parse(p[1]));
      if (p.length == 3 && p[2] == 'modulos') {
        final video = '${d['video_url'] ?? ''}';
        if (video.isNotEmpty && _embed(video).isEmpty) {
          throw Exception('Usa un enlace HTTPS de YouTube o Vimeo válido.');
        }
        (c['modulos'] as List).add({
          'id': _nextId++,
          ...d,
          'video_embed': _embed(video),
          'completado': false,
          'materiales': [],
        });
      } else if (method == 'PATCH') {
        c.addAll(d);
      }
      _progress(c);
      return _copy(c);
    }
    if (p.first == 'modulos') {
      final id = int.parse(p[1]);
      final m = _module(id);
      if (p.length == 3 && p[2] == 'completar') {
        final points = m['completado'] == true ? 0 : m['xp'] as int;
        m['completado'] = true;
        _xp += points;
        _progress(_courseForModule(id));
        return {'completado': true, 'xp_otorgado': points};
      }
      final video = '${d['video_url'] ?? m['video_url']}';
      if (video.isNotEmpty && _embed(video).isEmpty) {
        throw Exception('Usa un enlace HTTPS de YouTube o Vimeo válido.');
      }
      m.addAll(d);
      m['video_embed'] = _embed(video);
      _progress(_courseForModule(id));
      return _copy(m);
    }
    if (p.first == 'materiales') {
      for (final c in courses) {
        for (final m in c['modulos'] as List) {
          (m['materiales'] as List).removeWhere((a) => '${a['id']}' == p[1]);
        }
      }
      return null;
    }
    if (p.first == 'eventos') {
      if (p.length == 1) {
        if (method == 'POST') {
          final e = _event(
            _nextId++,
            '${d['titulo']}',
            '${d['tipo']}',
            '${d['estado']}',
            d['cupo'],
            0,
            1,
          )..addAll(d);
          e['encargados'] = instructors
              .where((i) => (d['encargados_ids'] as List).contains(i['id']))
              .toList();
          _capacity(e);
          events.add(e);
        }
        return _copy(events);
      }
      final e = _find(events, int.parse(p[1]));
      if (p.length == 2) {
        if (method == 'PATCH') {
          final unlimited =
              (d['cupo_ilimitado'] ?? e['cupo_ilimitado']) == true;
          if (!unlimited &&
              (d['cupo'] as int? ?? e['cupo'] as int) <
                  (e['inscritos'] as int)) {
            throw Exception('El cupo no puede ser menor a los inscritos.');
          }
          e.addAll(d);
          if (d.containsKey('encargados_ids')) {
            e['encargados'] = instructors
                .where((i) => (d['encargados_ids'] as List).contains(i['id']))
                .toList();
          }
          _capacity(e);
        }
        return _copy(e);
      }
      if (p[2] == 'asistencia') {
        if (method == 'DELETE') {
          if (e['inscrito'] == true) {
            e['inscritos']--;
            e['inscrito'] = false;
          }
        } else if (e['inscrito'] != true) {
          if (!['Reclutando', 'Publicado'].contains(e['estado']) ||
              !DateTime.parse(e['fecha']).isAfter(DateTime.now())) {
            throw Exception('Inscripciones cerradas.');
          }
          if (e['cupo_ilimitado'] != true &&
              (e['disponibles'] as num) <= 0) {
            throw Exception('Agotado.');
          }
          e['inscritos']++;
          e['inscrito'] = true;
        }
        _capacity(e);
        return _copy(e);
      }
      if (p[2] == 'solicitudes') {
        final list = applications.putIfAbsent(e['id'], () => []);
        if (method == 'POST') {
          if (e['estado'] != 'Reclutando' || e['solicitud'] != null) {
            throw Exception(
              'La convocatoria está cerrada o ya enviaste una solicitud.',
            );
          }
          list.add({
            'id': _nextId++,
            'nombre': 'Mi solicitud de prueba',
            ...d,
            'estado': 'Pendiente',
            'propia': true,
          });
          e['solicitud'] = 'Pendiente';
        }
        return _copy(list);
      }
    }
    if (p.first == 'solicitudes') {
      for (final entry in applications.entries) {
        for (final s in entry.value) {
          if ('${s['id']}' == p[1]) {
            if (s['estado'] != 'Pendiente') {
              throw Exception('La solicitud ya fue revisada.');
            }
            s['estado'] = d['estado'];
            if (s['propia'] == true) {
              _find(events, entry.key)['solicitud'] = d['estado'];
            }
            return _copy(s);
          }
        }
      }
    }
    throw Exception('Esta acción queda pendiente de conexión con Backend/ABD.');
  }
}
