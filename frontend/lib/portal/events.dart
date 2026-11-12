import 'package:flutter/material.dart';
import '../theme/unix_theme.dart';
import 'api.dart';
import 'ui.dart';
import 'courses.dart' show requiredText;

String eventDate(dynamic value) {
  final d = DateTime.tryParse('$value')?.toLocal();
  return d == null
      ? ''
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class PortalEvents extends StatefulWidget {
  final bool adminMode;
  final VoidCallback? onCreate;
  final String? type;
  const PortalEvents({
    super.key,
    this.onCreate,
    this.adminMode = false,
    this.type,
  });
  @override
  State<PortalEvents> createState() => _PortalEventsState();
}

class _PortalEventsState extends State<PortalEvents> {
  List<Map<String, dynamic>> _events = [];
  String _query = '', _state = 'Todos';
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = records(await PortalApi.request('eventos/'));
      if (mounted) setState(() => _events = data);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editor([Map<String, dynamic>? event]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EventEditor(event: event, defaultType: widget.type ?? 'Evento'),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    final items = _events
        .where(
          (e) =>
              (widget.adminMode || e['estado'] != 'Borrador') &&
              (widget.type == null || e['tipo'] == widget.type) &&
              (_state == 'Todos' || e['estado'] == _state) &&
              '${e['titulo']}'.toLowerCase().contains(_query),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        portalDataNotice(),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 16,
          runSpacing: 12,
          children: [
            heading(
              widget.type == 'Exposición'
                  ? 'Exposiciones individuales'
                  : widget.type == 'Taller'
                  ? 'Talleres y solicitudes'
                  : 'Eventos',
            ),
            if (widget.adminMode)
              FilledButton.icon(
                onPressed: widget.onCreate ?? () => _editor(),
                icon: const Icon(Icons.add),
                label: Text('Crear ${(widget.type ?? 'Evento').toLowerCase()}'),
              ),
          ],
        ),
        TextField(
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          decoration: const InputDecoration(
            hintText: 'Buscar por nombre',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in [
              'Todos',
              if (widget.adminMode) 'Borrador',
              'Reclutando',
              'Publicado',
              'Finalizado',
            ])
              ChoiceChip(
                label: Text(s),
                selected: _state == s,
                onSelected: (_) => setState(() => _state = s),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) errorPanel(_error!, _load),
        if (!_loading && _error == null && items.isEmpty)
          emptyPanel('No hay actividades que coincidan con los filtros.'),
        for (final e in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        e['tipo'] == 'Exposición'
                            ? Icons.co_present_outlined
                            : Icons.event_outlined,
                        color: UnixColors.link,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${e['titulo']}',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      badge('${e['estado']}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  muted('${e['tipo']} · ${eventDate(e['fecha'])}'),
                  const SizedBox(height: 8),
                  Text(
                    '${e['descripcion']}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    e['cupo_ilimitado'] == true
                        ? '${e['inscritos']} inscritos · Cupo ilimitado'
                        : '${e['inscritos']} inscritos · ${e['disponibles']} lugares disponibles',
                  ),
                  const SizedBox(height: 8),
                  if (e['cupo_ilimitado'] != true)
                    LinearProgressIndicator(
                      value: ((e['inscritos'] as num) / (e['cupo'] as num))
                          .clamp(0, 1)
                          .toDouble(),
                      color: e['disponibles'] == 0
                          ? Colors.red
                          : UnixColors.link,
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetail(
                                id: e['id'],
                                adminMode: widget.adminMode,
                              ),
                            ),
                          );
                          if (mounted) _load();
                        },
                        child: const Text('Ver evento'),
                      ),
                      if (widget.adminMode) ...[
                        OutlinedButton.icon(
                          onPressed: () => _editor(e),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventApplications(event: e),
                            ),
                          ),
                          icon: const Icon(Icons.people_outline),
                          label: const Text('Solicitudes'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class EventDetail extends StatefulWidget {
  final int id;
  final bool adminMode;
  const EventDetail({super.key, required this.id, this.adminMode = false});
  @override
  State<EventDetail> createState() => _EventDetailState();
}

class _EventDetailState extends State<EventDetail> {
  Map<String, dynamic>? _event;
  String? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = Map<String, dynamic>.from(
        await PortalApi.request('eventos/${widget.id}/'),
      );
      if (mounted) {
        setState(() {
          _event = data;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    }
  }

  Future<void> _attend() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await PortalApi.request(
        'eventos/${widget.id}/asistencia/',
        method: _event!['inscrito'] == true ? 'DELETE' : 'POST',
      );
      await _load();
    } catch (e) {
      if (mounted) notice(context, errorText(e));
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const ApplicationDialog(),
    );
    if (data == null || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      await PortalApi.request(
        'eventos/${widget.id}/solicitudes/',
        method: 'POST',
        data: data,
      );
      await _load();
      if (mounted) notice(context, 'Tu solicitud está pendiente de revisión.');
    } catch (e) {
      if (mounted) notice(context, errorText(e));
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    final e = _event;
    if (e == null || _error != null) {
      return PortalScaffold(
        title: 'Evento',
        child: _error != null
            ? errorPanel(_error!, _load)
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final date = DateTime.parse(e['fecha']).toLocal();
    final open =
        ['Reclutando', 'Publicado'].contains(e['estado']) &&
        date.isAfter(DateTime.now());
    final full = e['cupo_ilimitado'] != true && e['disponibles'] == 0;
    final attended = e['inscrito'] == true;
    return PortalScaffold(
      title: '${e['tipo']}',
      child: panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: [heading('${e['titulo']}'), badge('${e['estado']}')],
            ),
            Text('${e['descripcion']}'),
            const SizedBox(height: 24),
            Wrap(
              spacing: 24,
              runSpacing: 14,
              children: [
                Text('📅 ${eventDate(e['fecha'])}'),
                Text('Lugar: ${e['lugar']}'),
                Text(
                  e['cupo_ilimitado'] == true
                      ? 'Cupo: ilimitado'
                      : 'Cupo: ${e['cupo']} personas',
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              e['cupo_ilimitado'] == true
                  ? '${e['inscritos']} inscritos · Cupo ilimitado'
                  : '${e['inscritos']} inscritos · ${e['disponibles']} lugares disponibles',
            ),
            const SizedBox(height: 10),
            if (e['cupo_ilimitado'] != true)
              LinearProgressIndicator(
                value: ((e['inscritos'] as num) / (e['cupo'] as num))
                    .clamp(0, 1)
                    .toDouble(),
                color: full ? Colors.red : UnixColors.link,
              ),
            const SizedBox(height: 20),
            if (records(e['encargados']).isNotEmpty) ...[
              const Text(
                'Encargados',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final i in records(e['encargados']))
                    Chip(
                      avatar: const Icon(Icons.person_outline, size: 18),
                      label: Text('${i['nombre']}'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (records(e['subeventos'] ?? []).isNotEmpty) ...[
              const Text(
                'Subeventos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              for (final sub in records(e['subeventos'] ?? []))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_note_outlined),
                  title: Text('${sub['titulo']}'),
                  subtitle: Text(
                    '${sub['descripcion']}\n'
                    '${sub['lugar']} · Cupo: ${sub['cupo']} personas',
                  ),
                  isThreeLine: true,
                ),
              const SizedBox(height: 20),
            ],
            if (_busy) const LinearProgressIndicator(),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _busy || (!attended && (!open || full))
                      ? null
                      : _attend,
                  icon: Icon(
                    attended
                        ? Icons.event_busy
                        : full
                        ? Icons.lock_outline
                        : Icons.event_available,
                  ),
                  label: Text(
                    attended
                        ? 'Cancelar asistencia'
                        : !open
                        ? 'Inscripciones cerradas'
                        : full
                        ? 'Agotado'
                        : 'Asistir',
                  ),
                ),
                if (e['estado'] == 'Reclutando' &&
                    date.isAfter(DateTime.now()) &&
                    e['solicitud'] == null)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _apply,
                    icon: const Icon(Icons.mic_none),
                    label: const Text('Quiero ser Expositor'),
                  ),
                if (widget.adminMode)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventApplications(event: e),
                      ),
                    ),
                    icon: const Icon(Icons.people_outline),
                    label: const Text('Revisar solicitudes'),
                  ),
              ],
            ),
            if (e['solicitud'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text('Solicitud de expositor: ${e['solicitud']}'),
              ),
            if (full)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: muted('El evento alcanzó su límite de asistentes.'),
              ),
          ],
        ),
      ),
    );
  }
}

class ApplicationDialog extends StatefulWidget {
  const ApplicationDialog({super.key});
  @override
  State<ApplicationDialog> createState() => _ApplicationDialogState();
}

class _ApplicationDialogState extends State<ApplicationDialog> {
  final _key = GlobalKey<FormState>();
  final _experience = TextEditingController(),
      _proposal = TextEditingController();
  @override
  void dispose() {
    _experience.dispose();
    _proposal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Quiero ser Expositor'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _experience,
                maxLines: 3,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Breve descripción de tu experiencia',
                ),
                validator: requiredText,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _proposal,
                maxLines: 4,
                maxLength: 3000,
                decoration: const InputDecoration(
                  labelText: '¿Qué te gustaría presentar?',
                ),
                validator: requiredText,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (_key.currentState!.validate()) {
            Navigator.pop(context, {
              'experiencia': _experience.text.trim(),
              'propuesta': _proposal.text.trim(),
            });
          }
        },
        child: const Text('Enviar solicitud'),
      ),
    ],
  );
}

class EventApplications extends StatefulWidget {
  final Map<String, dynamic> event;
  const EventApplications({super.key, required this.event});
  @override
  State<EventApplications> createState() => _EventApplicationsState();
}

class _EventApplicationsState extends State<EventApplications> {
  List<Map<String, dynamic>> _items = [];
  String _state = 'Pendiente', _query = '';
  bool _loading = true, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = records(
        await PortalApi.request('eventos/${widget.event['id']}/solicitudes/'),
      );
      if (mounted) setState(() => _items = data);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(int id, String state) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          state == 'Aprobada' ? 'Aprobar solicitud' : 'Rechazar solicitud',
        ),
        content: const Text('¿Confirmas esta decisión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await PortalApi.request(
        'solicitudes/$id/',
        method: 'PATCH',
        data: {'estado': state},
      );
      await _load();
    } catch (e) {
      if (mounted) notice(context, errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    final results = _items
        .where(
          (s) =>
              s['estado'] == _state &&
              '${s['nombre']}'.toLowerCase().contains(_query),
        )
        .toList();
    return PortalScaffold(
      title: 'Solicitudes · ${widget.event['titulo']}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading('Solicitudes de expositores'),
          TextField(
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'Buscar solicitante por nombre',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final s in ['Pendiente', 'Aprobada', 'Rechazada'])
                ChoiceChip(
                  label: Text(
                    '$s (${_items.where((a) => a['estado'] == s).length})',
                  ),
                  selected: _state == s,
                  onSelected: (_) => setState(() => _state = s),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading || _busy) const LinearProgressIndicator(),
          if (_error != null) errorPanel(_error!, _load),
          if (!_loading && _error == null && results.isEmpty)
            emptyPanel('No hay solicitudes con estos filtros.'),
          for (final s in results)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(child: Icon(Icons.person_outline)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${s['nombre']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        badge('${s['estado']}'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Experiencia: ${s['experiencia']}'),
                    const SizedBox(height: 12),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Ver propuesta'),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('${s['propuesta']}'),
                        ),
                      ],
                    ),
                    if (s['estado'] == 'Pendiente')
                      Wrap(
                        spacing: 12,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _review(s['id'], 'Aprobada'),
                            icon: const Icon(Icons.check, color: Colors.green),
                            label: const Text('Aprobar'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _review(s['id'], 'Rechazada'),
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Rechazar'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EventEditor extends StatefulWidget {
  final Map<String, dynamic>? event;
  final String defaultType;
  const EventEditor({super.key, this.event, this.defaultType = 'Evento'});
  @override
  State<EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<EventEditor> {
  static const _online = 'En línea';

  static String _normalizePlace(String value) {
    final place = value.trim();
    return place.toLowerCase().replaceAll('í', 'i') == 'en linea'
        ? _online
        : place;
  }
  final _key = GlobalKey<FormState>();
  late final TextEditingController _title, _description, _place, _capacity;
  final _search = TextEditingController();
  late DateTime _date;
  late String _state, _type;
  List<Map<String, dynamic>> _instructors = [], _selected = [];
  bool _loading = true, _saving = false;
  bool _unlimited = false;
  List<Map<String, dynamic>> _subevents = [];
  final _content = <Map<String, dynamic>>[];
  List<String> _places = [];
  String? _error;
  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _unlimited = e?['cupo_ilimitado'] == true;
    _subevents = records(e?['subeventos'] ?? []);
    _title = TextEditingController(text: e?['titulo'] ?? '');
    _description = TextEditingController(text: e?['descripcion'] ?? '');
    _place = TextEditingController(
      text: _normalizePlace(e?['lugar'] ?? ''),
    );
    _capacity = TextEditingController(text: '${e?['cupo'] ?? 30}');
    _date = e == null
        ? DateTime.now().add(const Duration(days: 1))
        : DateTime.parse(e['fecha']).toLocal();
    _state = e?['estado'] ?? 'Borrador';
    _type = e?['tipo'] ?? widget.defaultType;
    _selected = e == null ? [] : records(e['encargados']);
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _place.dispose();
    _capacity.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await PortalApi.creationCatalog();
      if (mounted) {
        setState(() {
          _instructors = records(catalog['encargados']);
          _places = (catalog['lugares'] as List).cast<String>();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chooseDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    setState(
      () => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute),
    );
  }

  Future<void> _chooseTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (t == null || !mounted) return;
    setState(
      () => _date = DateTime(
        _date.year,
        _date.month,
        _date.day,
        t.hour,
        t.minute,
      ),
    );
  }

  // Edita una copia: cancelar el diálogo no cambia los datos originales.
  Future<void> _editSubevent([int? index]) async {
    final previous = index == null ? null : _subevents[index];
    final draft = <String, dynamic>{
      ...?previous,
      'titulo': previous?['titulo'] ?? '',
      'descripcion': previous?['descripcion'] ?? '',
      'lugar': previous?['lugar'] ?? _place.text.trim(),
      'cupo': previous?['cupo'] ?? 30,
    };
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(index == null ? 'Añadir subevento' : 'Editar subevento'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: '${draft['titulo']}',
                    maxLength: 160,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del subevento',
                      hintText: 'Ej. Fibra óptica',
                    ),
                    validator: requiredText,
                    onChanged: (v) => draft['titulo'] = v.trim(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: '${draft['descripcion']}',
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    onChanged: (v) => draft['descripcion'] = v.trim(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: '${draft['lugar']}',
                    decoration: const InputDecoration(labelText: 'Lugar'),
                    validator: requiredText,
                    onChanged: (v) => draft['lugar'] = v.trim(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: '${draft['cupo']}',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cupo del subevento',
                    ),
                    onChanged: (v) => draft['cupo'] = int.tryParse(v.trim()),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      return n == null || n < 1 || n > 100000
                          ? 'Ingresa un cupo de 1 a 100000.'
                          : null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, draft);
            },
            child: const Text('Guardar subevento'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (index == null) {
        _subevents.add(result);
      } else {
        _subevents[index] = result;
      }
    });
  }

  Future<void> _save({bool draft = false}) async {
    if (_saving || !_key.currentState!.validate()) return;
    final state = draft ? 'Borrador' : _state;
    if (state != 'Borrador' &&
        state != 'Finalizado' &&
        !_date.isAfter(DateTime.now())) {
      notice(context, 'Selecciona una fecha futura.');
      return;
    }
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'titulo': _title.text.trim(),
        'descripcion': _description.text.trim(),
        'lugar': _type == 'Curso' ? _online : _normalizePlace(_place.text),
        'cupo': _unlimited ? 30 : int.parse(_capacity.text.trim()),
        'cupo_ilimitado': _unlimited,
        if (_type == 'Evento') 'subeventos': _subevents,
        if (_type == 'Curso') 'contenido_bloques': _content,
        'fecha': _date.toUtc().toIso8601String(),
        'tipo': _type,
        'estado': state,
        'encargados_ids': _selected.map((i) => i['id']).toList(),
      };
      final event = widget.event;
      if (event == null) {
        await PortalApi.createActivity(data);
      } else {
        await PortalApi.request(
          'eventos/${event['id']}/',
          method: 'PATCH',
          data: data,
        );
      }
      if (mounted) Navigator.pop(context, _type);
    } catch (e) {
      if (mounted) notice(context, errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    final q = _search.text.trim().toLowerCase();
    final matches = _instructors
        .where(
          (i) =>
              !_selected.any((s) => s['id'] == i['id']) &&
              '${i['nombre']} ${i['numero_control']}'.toLowerCase().contains(q),
        )
        .toList();
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _title,
          maxLength: 160,
          decoration: const InputDecoration(labelText: 'Nombre'),
          validator: requiredText,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _description,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Descripción'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.calendar_today),
                label: Text('${_date.day}/${_date.month}/${_date.year}'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _chooseTime,
                icon: const Icon(Icons.schedule),
                label: Text(
                  '${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Tipo de actividad'),
          items: [
            'Evento',
            'Taller',
            'Exposición',
            if (widget.event == null) 'Curso',
          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: widget.event != null
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() => _type = value);
                },
        ),
        const SizedBox(height: 16),
        if (_type == 'Curso')
          const InputDecorator(
            decoration: InputDecoration(labelText: 'Lugar o modalidad'),
            child: Text(_online),
          )
        else
          DropdownButtonFormField<String>(
            key: ValueKey((_places.length, _type)),
            initialValue: _place.text.isEmpty ? null : _place.text,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Lugar o modalidad'),
            items: <String>{
              ..._places.map(_normalizePlace).where((place) => place.isNotEmpty),
              if (_place.text.isNotEmpty) _place.text,
            }.map((place) => DropdownMenuItem(
              value: place,
              child: Text(place),
            )).toList(),
            onChanged: _loading ? null : (value) => _place.text = value ?? '',
            validator: requiredText,
          ),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _state,
          decoration: const InputDecoration(labelText: 'Estado'),
          items: [
            'Borrador',
            'Reclutando',
            'Publicado',
            'Finalizado',
          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _state = v!),
        ),
      ],
    );
    final people = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Encargados',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Buscar por nombre o ID',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final i in _selected)
              InputChip(
                label: Text('${i['nombre']}'),
                onDeleted: () => setState(
                  () => _selected.removeWhere((s) => s['id'] == i['id']),
                ),
              ),
          ],
        ),
        muted('${_selected.length} encargados seleccionados'),
        const SizedBox(height: 8),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) errorPanel(_error!, _load),
        if (!_loading && _error == null)
          Container(
            constraints: const BoxConstraints(maxHeight: 210),
            child: matches.isEmpty
                ? muted('No hay profesores que coincidan.')
                : ListView.builder(
                    shrinkWrap: true,
                    primary: false,
                    itemCount: matches.length,
                    itemBuilder: (_, index) {
                      final i = matches[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_add_alt_1),
                        title: Text('${i['nombre']}'),
                        subtitle: Text('ID: ${i['numero_control']}'),
                        trailing: const Icon(Icons.add),
                        onTap: () => setState(() {
                          _selected.add(i);
                          _search.clear();
                        }),
                      );
                    },
                  ),
          ),
        const SizedBox(height: 18),
        panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Límite de asistentes',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cupo ilimitado'),
                subtitle: const Text(
                  'Desactívalo para indicar el máximo de asistentes.',
                ),
                value: _unlimited,
                onChanged: (value) {
                  setState(() => _unlimited = value);
                },
              ),
              const SizedBox(height: 10),
              if (!_unlimited)
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Reducir cupo',
                      onPressed: () {
                        final n = int.tryParse(_capacity.text) ?? 1;
                        if (n > 1) setState(() => _capacity.text = '${n - 1}');
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _capacity,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(labelText: 'Cupo'),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          final count =
                              (widget.event?['inscritos'] as int?) ?? 0;
                          return n == null || n < 1 || n > 100000
                              ? 'De 1 a 100000'
                              : n < count
                              ? 'Ya hay $count inscritos'
                              : null;
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'Aumentar cupo',
                      onPressed: () {
                        final n = int.tryParse(_capacity.text) ?? 0;
                        if (n < 100000) {
                          setState(() => _capacity.text = '${n + 1}');
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              muted(
                _unlimited
                    ? 'Este evento no tendrá límite de asistentes.'
                    : '${widget.event?['inscritos'] ?? 0} inscritos. '
                          'El cupo no puede ser menor a los inscritos actuales.',
              ),
            ],
          ),
        ),
      ],
    );
    return PortalScaffold(
      title: widget.event == null
          ? 'Crear ${_type.toLowerCase()}'
          : 'Editar ${_type.toLowerCase()}',
      child: Form(
        key: _key,
        child: AbsorbPointer(
          absorbing: _saving,
          child: Column(
            children: [
              if (_saving) const LinearProgressIndicator(),
              panel(
                child: LayoutBuilder(
                  builder: (ctx, c) => c.maxWidth < 750
                      ? Column(
                          children: [info, const SizedBox(height: 28), people],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: info),
                            const SizedBox(width: 28),
                            Expanded(child: people),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              if (_type == 'Evento')
                panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Subeventos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      muted(
                        'Añade las actividades del evento principal. '
                        'Cada una tiene su propio cupo.',
                      ),
                      const SizedBox(height: 12),
                      if (_subevents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Todavía no has añadido subeventos.'),
                        ),
                      for (var i = 0; i < _subevents.length; i++)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.event_note_outlined),
                          title: Text('${_subevents[i]['titulo']}'),
                          subtitle: Text(
                            '${_subevents[i]['lugar']} · '
                            'Cupo: ${_subevents[i]['cupo']} personas',
                          ),
                          onTap: () => _editSubevent(i),
                          trailing: IconButton(
                            tooltip: 'Eliminar subevento',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                setState(() => _subevents.removeAt(i)),
                          ),
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _editSubevent(),
                        icon: const Icon(Icons.add),
                        label: const Text('Añadir subevento'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              if (_type == 'Curso')
                panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Contenido del curso'),
                      for (final block in _content)
                        Padding(
                          key: ObjectKey(block),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: TextFormField(
                            initialValue: block['contenido'] as String,
                            maxLines: block['tipo'] == 'enlace' ? 1 : 3,
                            decoration: InputDecoration(
                              labelText: block['tipo'] == 'enlace'
                                  ? 'Enlace'
                                  : 'Párrafo',
                              suffixIcon: IconButton(
                                tooltip: 'Quitar bloque',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () =>
                                    setState(() => _content.remove(block)),
                              ),
                            ),
                            onChanged: (value) =>
                                block['contenido'] = value.trim(),
                            validator: (value) {
                              final missing = requiredText(value);
                              if (missing != null) return missing;
                              if (block['tipo'] == 'enlace') {
                                final uri = Uri.tryParse(value!.trim());
                                if (uri == null ||
                                    uri.host.isEmpty ||
                                    !['https', 'http'].contains(uri.scheme)) {
                                  return 'Ingresa un enlace HTTP o HTTPS válido.';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      Wrap(
                        spacing: 12,
                        children: [
                          for (final kind in ['parrafo', 'enlace'])
                            TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: Text(
                                kind == 'parrafo'
                                    ? 'Añadir párrafo'
                                    : 'Añadir enlace',
                              ),
                              onPressed: () => setState(
                                () => _content.add({
                                  'tipo': kind,
                                  'contenido': '',
                                }),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => _save(draft: true),
                    child: const Text('Guardar borrador'),
                  ),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(
                      _saving ? 'Guardando…' : 'Guardar ${_type.toLowerCase()}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
