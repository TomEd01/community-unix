import '../../theme/unix_theme.dart';
import 'package:flutter/material.dart';
import 'admin_store.dart';
import 'admin_style.dart';
import 'admin_macroeventos_page.dart';

class AdminActividadPage extends StatelessWidget {
  const AdminActividadPage({
    super.key,
    required this.store,
    required this.activity,
  });
  final AdminStore store;
  final EventActivity activity;
  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Theme(
      data: AdminStyle.theme,
      child: _ActivityScreen(store: store, activity: activity),
    );
  }
}

class _ActivityScreen extends StatefulWidget {
  const _ActivityScreen({required this.store, required this.activity});
  final AdminStore store;
  final EventActivity activity;
  @override
  State<_ActivityScreen> createState() => _AdminActividadPageState();
}

class _AdminActividadPageState extends State<_ActivityScreen> {
  String? selected;
  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Theme(
      data: AdminStyle.theme,
      child: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          UnixTheme.watch(context);
          final a = widget.activity;
          return Scaffold(
            appBar: AppBar(
              title: Text('Detalle de actividad'),
              actions: const [
                UnixThemeToggle(compact: true),
                SizedBox(width: 12),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 1100),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        UnixTheme.watch(context);
                        final information = AdminPanel(
                          title: a.title,
                          child: informationPanel(a),
                        );
                        final candidates = AdminPanel(
                          title: 'Postulantes a expositor',
                          child: candidatesPanel(a),
                        );
                        if (c.maxWidth < 850)
                          return Column(
                            children: [
                              information,
                              SizedBox(height: 18),
                              candidates,
                            ],
                          );
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: information),
                            SizedBox(width: 20),
                            Expanded(child: candidates),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget informationPanel(EventActivity a) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 10,
        children: [
          AdminBadge(a.type),
          AdminBadge(a.status.label, color: statusColor(a.status)),
        ],
      ),
      SizedBox(height: 22),
      if (a.type == 'Curso')
        Text(
          'Curso asíncrono · Sin horario',
          style: TextStyle(color: AdminStyle.muted),
        )
      else ...[
        detail(Icons.calendar_today_outlined, 'Fecha', a.date),
        detail(Icons.schedule, 'Horario', a.time),
        detail(Icons.place_outlined, 'Aula', a.room),
      ],
      detail(
        Icons.groups_outlined,
        'Cupo',
        '${a.enrolled} / ${a.capacity} inscritos',
      ),
      detail(
        Icons.person_outline,
        'Expositor',
        a.speakerId == null
            ? 'Sin asignar'
            : widget.store.user(a.speakerId!).name,
      ),
      SizedBox(height: 16),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: () => editActivity(a),
            icon: Icon(Icons.edit_outlined),
            label: Text('Editar información'),
          ),
          if (a.status == ActivityStatus.draft)
            FilledButton.icon(
              onPressed: () => publish(a),
              icon: Icon(Icons.publish_outlined),
              label: Text('Publicar actividad'),
            ),
        ],
      ),
      SizedBox(height: 16),
      Text(switch (a.status) {
        ActivityStatus.recruiting =>
          'Vacante visible para recibir postulantes.',
        ActivityStatus.draft =>
          'Oculta al público mientras el equipo prepara el contenido.',
        ActivityStatus.published =>
          'Visible para la comunidad. Inscripciones abiertas.',
      }, style: TextStyle(color: AdminStyle.muted)),
      SizedBox(height: 12),
      Text(
        'Vista de demostración. La asistencia, el contenido y las inscripciones '
        'requieren conexión con el backend.',
        style: TextStyle(color: AdminStyle.muted, fontSize: 12),
      ),
    ],
  );
  Widget detail(IconData icon, String label, String value) => Padding(
    padding: EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AdminStyle.muted),
        SizedBox(width: 10),
        Expanded(child: Text('$label: $value')),
      ],
    ),
  );
  Widget candidatesPanel(EventActivity a) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${a.candidates.length} postulantes · Revisión manual',
        style: TextStyle(color: AdminStyle.muted),
      ),
      SizedBox(height: 12),
      if (a.candidates.isEmpty)
        Padding(
          padding: EdgeInsets.all(12),
          child: Text('Todavía no hay postulantes para esta actividad.'),
        ),
      for (final candidate in a.candidates)
        Builder(
          builder: (context) {
            UnixTheme.watch(context);
            final user = widget.store.user(candidate.userId);
            final enabled =
                a.status == ActivityStatus.recruiting && user.active;
            return Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AdminStyle.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected == user.id
                        ? AdminStyle.orange
                        : AdminStyle.border,
                  ),
                ),
                child: ListTile(
                  onTap: enabled
                      ? () => setState(() => selected = user.id)
                      : null,
                  leading: Icon(
                    selected == user.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: enabled ? AdminStyle.orange : AdminStyle.muted,
                  ),
                  title: Text(user.name),
                  subtitle: Text(
                    'ID: ${user.id}'
                    '${user.active ? '' : ' · Inactivo'}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Ver perfil',
                    icon: Icon(Icons.person_search),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (dialog) {
                        UnixTheme.watch(dialog);
                        return AlertDialog(
                          title: Text(user.name),
                          content: Text(
                            'ID: ${user.id}\nCorreo: ${user.email}\nRol: ${user.role}\n\n'
                            'Motivación: ${candidate.reason}',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialog),
                              child: Text('Cerrar'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      SizedBox(height: 12),
      if (a.status == ActivityStatus.recruiting) ...[
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: selected == null ? null : () => assign(a),
            child: Text('Asignar expositor'),
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Al asignar, la actividad pasa a Borrador. La etiqueta de expositor '
          'aplica únicamente a esta actividad.',
          style: TextStyle(color: AdminStyle.muted),
        ),
      ] else
        Text(
          'La selección de expositor ya está cerrada.',
          style: TextStyle(color: AdminStyle.muted),
        ),
    ],
  );
  Future<void> assign(EventActivity a) async {
    final id = selected;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) {
        UnixTheme.watch(dialog);
        return AlertDialog(
          title: Text('Asignar expositor'),
          content: Text(
            '¿Asignar a ${widget.store.user(id).name}? '
            'La actividad se ocultará al público y pasará a Borrador.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: Text('Asignar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    try {
      widget.store.assignSpeaker(a, id);
      adminMessage(context, 'Expositor asignado en la demostración.');
    } on StateError catch (e) {
      adminMessage(context, '${e.message}');
    }
  }

  Future<void> publish(EventActivity a) async {
    final error = widget.store.publicationError(a);
    if (error != null) {
      adminMessage(context, error);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) {
        UnixTheme.watch(dialog);
        return AlertDialog(
          title: Text('Publicar actividad'),
          content: Text(
            'Confirma que el equipo terminó de preparar el contenido. '
            'Se abrirán las inscripciones en esta demostración.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: Text('Publicar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    try {
      widget.store.publish(a);
      adminMessage(context, 'Actividad publicada en la demostración.');
    } on StateError catch (e) {
      adminMessage(context, '${e.message}');
    }
  }

  Future<void> editActivity(EventActivity a) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _EditActivity(store: widget.store, activity: a),
    );
  }
}

class _EditActivity extends StatefulWidget {
  const _EditActivity({required this.store, required this.activity});
  final AdminStore store;
  final EventActivity activity;
  @override
  State<_EditActivity> createState() => _EditActivityState();
}

class _EditActivityState extends State<_EditActivity> {
  final form = GlobalKey<FormState>();
  late final List<TextEditingController> fields;
  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    fields = [
      a.title,
      a.date,
      a.time,
      a.room,
      '${a.capacity}',
    ].map((s) => TextEditingController(text: s)).toList();
  }

  @override
  void dispose() {
    for (final field in fields) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return AlertDialog(
      title: Text('Editar actividad'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final index in [
                  0,
                  if (widget.activity.type != 'Curso') ...[1, 2, 3],
                  4,
                ])
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: fields[index],
                      keyboardType: index == 4
                          ? TextInputType.number
                          : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: [
                          'Título',
                          'Fecha',
                          'Horario',
                          'Aula',
                          'Cupo',
                        ][index],
                      ),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty)
                          return 'Campo obligatorio.';
                        if (index == 4) {
                          final n = int.tryParse(v!);
                          if (n == null ||
                              n < 1 ||
                              n < widget.activity.enrolled) {
                            return 'Ingresa un cupo válido, mayor o igual a los inscritos.';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!form.currentState!.validate()) return;
            widget.store.editActivity(
              widget.activity,
              title: fields[0].text.trim(),
              date: fields[1].text.trim(),
              time: fields[2].text.trim(),
              room: fields[3].text.trim(),
              capacity: int.parse(fields[4].text),
            );
            Navigator.pop(context);
          },
          child: Text('Guardar cambios'),
        ),
      ],
    );
  }
}
