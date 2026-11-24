import 'package:flutter/material.dart';
import '../theme/unix_theme.dart';
//import '../pages/alumno/alumno_vinculo_profesor.dart';
import 'api.dart';
import 'ui.dart';
import 'courses.dart';
import 'events.dart';

class PortalDashboard extends StatefulWidget {
  final String nombre;
  final bool alumno;
  const PortalDashboard({super.key, this.nombre = '', this.alumno = false});
  @override
  State<PortalDashboard> createState() => _PortalDashboardState();
}

class _PortalDashboardState extends State<PortalDashboard> {
  static const bool _modoMantenimiento = true;

  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();

    if (!widget.alumno || !_modoMantenimiento) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final data = Map<String, dynamic>.from(
        await PortalApi.request('dashboard/'),
      );
      if (mounted) {
        setState(() {
          _data = data;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    }
  }

  Future<void> _navigate(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    if (widget.alumno && _modoMantenimiento) {
    final nombre = widget.nombre.trim();

    final primero = nombre.isEmpty
        ? ''
        : nombre.split(RegExp(r'\s+')).first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            primero.isEmpty ? '¡Hola!' : '¡Hola, $primero!',
            style: TextStyle(
              color: UnixColors.text,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 80),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Column(
                children: [
                  const Icon(
                    Icons.construction_rounded,
                    size: 100,
                    color: Color(0xFFFF8A24),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    '¡Estamos preparando algo increíble para ti!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: UnixColors.text,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Estamos trabajando en nuevas actividades '
                    'y experiencias para que sigas aprendiendo y '
                    'creciendo tus conocimientos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: UnixColors.text,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    '¡Muy pronto tendremos novedades!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFF8A24),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
    final raw = '${_data?['nombre'] ?? widget.nombre}'.trim();
    final first = raw.isEmpty ? '' : raw.split(RegExp(r'\s+')).first;
    final d = _data;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              portalDataNotice(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      first.isEmpty ? '¡Hola!' : '¡Hola, $first!',
                      style: TextStyle(
                        color: UnixColors.text,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualizar dashboard',
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              muted('Continúa aprendiendo y comparte lo que sabes.'),
              const SizedBox(height: 24),
              if (_error != null) errorPanel(_error!, _load),
              if (d == null && _error == null) const LinearProgressIndicator(),
              if (d != null) ...[
                LayoutBuilder(
                  builder: (ctx, c) {
                    final stats = [
                      _stat(
                        Icons.workspace_premium,
                        'Nivel ${d['nivel']} · Explorador',
                        'Sigue participando en cursos y actividades.',
                      ),
                      _stat(
                        Icons.layers_outlined,
                        '${d['xp']} XP totales',
                        'Experiencia acumulada en la comunidad.',
                      ),
                      panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${d['xp_siguiente']} XP para el siguiente nivel',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: (d['progreso_nivel'] as num).toDouble(),
                            ),
                            const SizedBox(height: 8),
                            muted('Cada nivel requiere 500 XP.'),
                          ],
                        ),
                      ),
                    ];
                    return c.maxWidth < 850
                        ? Column(
                            children: [
                              for (final s in stats)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: s,
                                ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < stats.length; i++) ...[
                                if (i > 0) const SizedBox(width: 16),
                                Expanded(child: stats[i]),
                              ],
                            ],
                          );
                  },
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (ctx, c) {
                    final sections = [
                      _courseSection(records(d['cursos'])),
                      _eventSection(
                        'Exposiciones individuales',
                        records(d['exposiciones']),
                        exposure: true,
                      ),
                      _eventSection('Próximos eventos', records(d['eventos'])),
                    ];
                    return c.maxWidth < 1080
                        ? Column(
                            children: [
                              for (final s in sections)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: s,
                                ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < sections.length; i++) ...[
                                if (i > 0) const SizedBox(width: 16),
                                Expanded(child: sections[i]),
                              ],
                            ],
                          );
                  },
                ),
              ],
             /* if (widget.alumno) ...[
                const SizedBox(height: 24),
                const AlumnoVinculoProfesor(),
              ],*/
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String title, String description) => panel(
    child: Row(
      children: [
        Icon(icon, color: UnixColors.link, size: 38),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              muted(description),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _courseSection(List<Map<String, dynamic>> courses) => panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Cursos asíncronos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _navigate(
              const PortalScaffold(title: 'Cursos', child: PortalCourses()),
            ),
            child: const Text('Ver todos →'),
          ),
        ),
        if (courses.isEmpty) muted('Aún no hay cursos publicados.'),
        for (final c in courses)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${c['titulo']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (c['progreso'] as num).toDouble() / 100,
                ),
                const SizedBox(height: 6),
                muted('Progreso: ${c['progreso']}%'),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => _navigate(CourseDetail(id: c['id'])),
                    child: const Text('Continuar'),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
  Widget _eventSection(
    String title,
    List<Map<String, dynamic>> events, {
    bool exposure = false,
  }) => panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _navigate(
              PortalScaffold(
                title: title,
                child: PortalEvents(type: exposure ? 'Exposición' : null),
              ),
            ),
            child: const Text('Ver todos →'),
          ),
        ),
        if (events.isEmpty) muted('No hay actividades próximas publicadas.'),
        for (final e in events)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${e['titulo']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                badge('${e['estado']}'),
                muted(eventDate(e['fecha'])),
                const SizedBox(height: 6),
                muted('${e['inscritos']} de ${e['cupo']} lugares'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _navigate(EventDetail(id: e['id'])),
                  child: Text(exposure ? 'Ver exposición' : 'Ver evento'),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
