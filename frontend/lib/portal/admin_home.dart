import 'package:flutter/material.dart';
import '../theme/unix_theme.dart';
import 'api.dart';
import 'events.dart';
import 'ui.dart';

class AdminPortalHome extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const AdminPortalHome({super.key, required this.onNavigate});
  @override
  State<AdminPortalHome> createState() => _AdminPortalHomeState();
}

class _AdminPortalHomeState extends State<AdminPortalHome> {
  List<Map<String, dynamic>>? _events, _courses;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Future.wait([
        PortalApi.request('eventos/'),
        PortalApi.request('cursos/'),
      ]);
      if (mounted) {
        setState(() {
          _events = records(data[0]);
          _courses = records(data[1]);
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    if (_error != null) return errorPanel(_error!, _load);
    if (_events == null) return const LinearProgressIndicator();
    final metrics = [
      ('Cursos', _courses!.length, 5, Icons.menu_book_outlined),
      (
        'Reclutando',
        _events!.where((e) => e['estado'] == 'Reclutando').length,
        1,
        Icons.people_outline,
      ),
      (
        'Publicados',
        _events!.where((e) => e['estado'] == 'Publicado').length,
        1,
        Icons.event_available,
      ),
      (
        'Inscripciones',
        _events!.fold<int>(0, (s, e) => s + (e['inscritos'] as int)),
        1,
        Icons.groups_outlined,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        portalDataNotice(),
        Row(
          children: [
            Expanded(
              child: muted(
                'Gestiona cursos, talleres, exposiciones y eventos.',
              ),
            ),
            IconButton(
              tooltip: 'Actualizar métricas',
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (ctx, c) {
            final columns = c.maxWidth < 550
                ? 1
                : c.maxWidth < 1000
                ? 2
                : 4;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final m in metrics)
                  SizedBox(
                    width: (c.maxWidth - (columns - 1) * 12) / columns,
                    child: InkWell(
                      onTap: () => widget.onNavigate(m.$3),
                      child: panel(
                        child: Row(
                          children: [
                            Icon(m.$4, color: UnixColors.link, size: 32),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${m.$2}',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(m.$1),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => widget.onNavigate(5),
              icon: const Icon(Icons.menu_book),
              label: const Text('Administrar cursos'),
            ),
            OutlinedButton.icon(
              onPressed: () => widget.onNavigate(6),
              icon: const Icon(Icons.school),
              label: const Text('Talleres y solicitudes'),
            ),
            OutlinedButton.icon(
              onPressed: () => widget.onNavigate(1),
              icon: const Icon(Icons.event),
              label: const Text('Eventos y encargados'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_events!.isEmpty)
          emptyPanel('Aún no hay eventos. Crea el primero desde Eventos.')
        else
          panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading('Actividades recientes'),
                for (final e in _events!.take(5))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${e['titulo']}'),
                    subtitle: Text(
                      '${eventDate(e['fecha'])} · ${e['inscritos']}/${e['cupo']} inscritos',
                    ),
                    trailing: badge('${e['estado']}'),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EventDetail(id: e['id'], adminMode: true),
                        ),
                      );
                      if (mounted) _load();
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
