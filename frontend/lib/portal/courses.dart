import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../theme/unix_theme.dart';
import 'api.dart';
import 'ui.dart';
import 'video.dart';

class PortalCourses extends StatefulWidget {
  final bool adminMode;
  final VoidCallback? onCreate;
  const PortalCourses({super.key, this.onCreate, this.adminMode = false});
  @override
  State<PortalCourses> createState() => _PortalCoursesState();
}

class _PortalCoursesState extends State<PortalCourses> {
  List<Map<String, dynamic>> _courses = [];
  bool _loading = true;
  String? _error;
  String _query = '';
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
      final data = records(await PortalApi.request('cursos/'));
      if (mounted) setState(() => _courses = data);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([Map<String, dynamic>? course]) async {
    final data = await courseForm(context, course);
    if (data == null || !mounted) return;
    try {
      await PortalApi.request(
        course == null ? 'cursos/' : 'cursos/${course['id']}/',
        method: course == null ? 'POST' : 'PATCH',
        data: data,
      );
      if (mounted) await _load();
    } catch (e) {
      if (mounted) notice(context, errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    final courses = _courses
        .where(
          (c) =>
              (widget.adminMode || c['publicado'] == true) &&
              '${c['titulo']}'.toLowerCase().contains(_query),
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
              widget.adminMode ? 'Administrar cursos' : 'Cursos asíncronos',
            ),
            if (widget.adminMode)
              FilledButton.icon(
                onPressed: widget.onCreate ?? () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('Crear curso'),
              ),
          ],
        ),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar cursos',
          ),
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 18),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) errorPanel(_error!, _load),
        if (!_loading && _error == null && courses.isEmpty)
          emptyPanel('No hay cursos que mostrar.'),
        for (final c in courses)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book_outlined, color: UnixColors.link),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${c['titulo']}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.adminMode)
                        IconButton(
                          tooltip: 'Editar información',
                          onPressed: () => _edit(c),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  muted('${c['descripcion']}'),
                  const SizedBox(height: 12),
                  if (widget.adminMode)
                    badge(c['publicado'] == true ? 'Publicado' : 'Borrador')
                  else ...[
                    LinearProgressIndicator(
                      value: (c['progreso'] as num).toDouble() / 100,
                    ),
                    const SizedBox(height: 6),
                    muted('Progreso: ${c['progreso']}%'),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseDetail(
                              id: c['id'],
                              adminMode: widget.adminMode,
                            ),
                          ),
                        );
                        if (mounted) _load();
                      },
                      child: Text(
                        widget.adminMode
                            ? 'Administrar contenido'
                            : 'Continuar',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

Future<Map<String, dynamic>?> courseForm(
  BuildContext context,
  Map<String, dynamic>? course,
) => showDialog<Map<String, dynamic>>(
  context: context,
  builder: (_) => _CourseForm(course: course),
);

class _CourseForm extends StatefulWidget {
  final Map<String, dynamic>? course;
  const _CourseForm({this.course});
  @override
  State<_CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends State<_CourseForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _title, _description;
  late bool _published;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.course?['titulo'] ?? '');
    _description = TextEditingController(
      text: widget.course?['descripcion'] ?? '',
    );
    _published = widget.course?['publicado'] == true;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return AlertDialog(
      title: Text(
        widget.course == null ? 'Crear curso' : 'Información del curso',
      ),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Form(
            key: _key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _title,
                  maxLength: 160,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: requiredText,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Publicado'),
                  subtitle: const Text('Visible para los usuarios'),
                  value: _published,
                  onChanged: (v) => setState(() => _published = v),
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
                'titulo': _title.text.trim(),
                'descripcion': _description.text.trim(),
                'publicado': _published,
              });
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'Este campo es obligatorio.' : null;

class CourseDetail extends StatefulWidget {
  final int id;
  final bool adminMode;
  const CourseDetail({super.key, required this.id, this.adminMode = false});
  @override
  State<CourseDetail> createState() => _CourseDetailState();
}

class _CourseDetailState extends State<CourseDetail> {
  Map<String, dynamic>? _course;
  String? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = Map<String, dynamic>.from(
        await PortalApi.request('cursos/${widget.id}/'),
      );
      if (mounted) {
        setState(() {
          _course = c;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    }
  }

  Future<void> _action(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
      if (mounted) await _load();
    } catch (e) {
      if (mounted) notice(context, errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _module([Map<String, dynamic>? m]) async {
    final data = await moduleForm(
      context,
      m,
      records(_course!['modulos']).length + 1,
    );
    if (data == null || !mounted) return;
    await _action(() async {
      await PortalApi.request(
        m == null ? 'cursos/${widget.id}/modulos/' : 'modulos/${m['id']}/',
        method: m == null ? 'POST' : 'PATCH',
        data: data,
      );
    });
  }

  Future<void> _upload(int module) async {
    const group = XTypeGroup(
      label: 'Documentos',
      extensions: ['pdf', 'doc', 'docx', 'txt'],
      uniformTypeIdentifiers: [
        'com.adobe.pdf',
        'com.microsoft.word.doc',
        'org.openxmlformats.wordprocessingml.document',
        'public.plain-text',
      ],
    );
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null || !mounted) return;
    if (await file.length() > 20 * 1024 * 1024) {
      if (mounted) notice(context, 'Máximo 20 MB por documento.');
      return;
    }
    await _action(
      () async => PortalApi.upload(module, file.name, await file.readAsBytes()),
    );
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return PortalScaffold(
      title: '${_course?['titulo'] ?? 'Curso'}',
      child: _error != null
          ? errorPanel(_error!, _load)
          : _course == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading('${_course!['titulo']}'),
                muted('${_course!['descripcion']}'),
                for (final block in records(
                  _course!['contenido_bloques'] ?? [],
                ))
                  if (block['tipo'] == 'enlace')
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.link),
                        onPressed: () =>
                            openPortalLink(context, '${block['contenido']}'),
                        label: Text('${block['contenido']}'),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('${block['contenido']}'),
                    ),

                const SizedBox(height: 18),
                if (_busy) const LinearProgressIndicator(),
                if (widget.adminMode)
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _module(),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar módulo'),
                    ),
                  ),
                if (records(_course!['modulos']).isEmpty)
                  emptyPanel('Este curso todavía no tiene módulos.'),
                for (final m in records(_course!['modulos']))
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${m['orden']}. ${m['titulo']}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              badge('${m['xp']} XP'),
                              if (widget.adminMode)
                                IconButton(
                                  tooltip: 'Editar módulo',
                                  onPressed: _busy ? null : () => _module(m),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('${m['descripcion']}'),
                          const SizedBox(height: 16),
                          if ('${m['video_url']}'.isNotEmpty)
                            PortalVideo(
                              url: '${m['video_url']}',
                              embed: '${m['video_embed']}',
                            ),
                          for (final a in records(m['materiales']))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.description_outlined),
                              title: Text('${a['nombre']}'),
                              onTap: () {
                                if (a['ejemplo'] == true) {
                                  notice(
                                    context,
                                    'Documento de ejemplo. La carga y visualización reales quedan pendientes.',
                                  );
                                } else {
                                  openPortalLink(context, '${a['url']}');
                                }
                              },
                              trailing: widget.adminMode
                                  ? IconButton(
                                      tooltip: 'Eliminar documento',
                                      onPressed: _busy
                                          ? null
                                          : () => _action(() async {
                                              await PortalApi.request(
                                                'materiales/${a['id']}/',
                                                method: 'DELETE',
                                              );
                                            }),
                                      icon: const Icon(Icons.delete_outline),
                                    )
                                  : const Icon(Icons.open_in_new),
                            ),
                          if (widget.adminMode)
                            OutlinedButton.icon(
                              onPressed: _busy ? null : () => _upload(m['id']),
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Agregar PDF o documento'),
                            )
                          else
                            FilledButton.icon(
                              onPressed: _busy || m['completado'] == true
                                  ? null
                                  : () => _action(() async {
                                      final r = await PortalApi.request(
                                        'modulos/${m['id']}/completar/',
                                        method: 'POST',
                                      );
                                      if (context.mounted) {
                                        notice(
                                          context,
                                          'Módulo completado · +${r['xp_otorgado']} XP',
                                        );
                                      }
                                    }),
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(
                                m['completado'] == true
                                    ? 'Completado'
                                    : 'Marcar como completado',
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
}

Future<Map<String, dynamic>?> moduleForm(
  BuildContext context,
  Map<String, dynamic>? module,
  int order,
) => showDialog<Map<String, dynamic>>(
  context: context,
  builder: (_) => _ModuleForm(module: module, order: order),
);

class _ModuleForm extends StatefulWidget {
  final Map<String, dynamic>? module;
  final int order;
  const _ModuleForm({this.module, required this.order});
  @override
  State<_ModuleForm> createState() => _ModuleFormState();
}

class _ModuleFormState extends State<_ModuleForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _title, _description, _video, _order, _xp;
  @override
  void initState() {
    super.initState();
    final m = widget.module;
    _title = TextEditingController(text: m?['titulo'] ?? '');
    _description = TextEditingController(text: m?['descripcion'] ?? '');
    _video = TextEditingController(text: m?['video_url'] ?? '');
    _order = TextEditingController(text: '${m?['orden'] ?? widget.order}');
    _xp = TextEditingController(text: '${m?['xp'] ?? 50}');
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _video, _order, _xp]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return AlertDialog(
      title: Text(widget.module == null ? 'Agregar módulo' : 'Editar módulo'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _title,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Título del módulo',
                  ),
                  validator: requiredText,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Información del módulo',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _video,
                  decoration: const InputDecoration(
                    labelText: 'Enlace de video externo',
                    hintText: 'https://www.youtube.com/watch?v=…',
                    helperText:
                        'YouTube o Vimeo. El video permanece en su plataforma.',
                    helperMaxLines: 2,
                  ),
                  validator: (v) =>
                      v!.trim().isNotEmpty && !v.trim().startsWith('https://')
                      ? 'Usa un enlace HTTPS.'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _order,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Orden'),
                        validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1
                            ? 'Mínimo 1'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _xp,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Puntos XP',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          return n == null || n < 0 || n > 1000
                              ? 'De 0 a 1000'
                              : null;
                        },
                      ),
                    ),
                  ],
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
                'titulo': _title.text.trim(),
                'descripcion': _description.text.trim(),
                'video_url': _video.text.trim(),
                'orden': int.parse(_order.text),
                'xp': int.parse(_xp.text),
              });
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
