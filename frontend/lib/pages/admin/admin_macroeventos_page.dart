import '../../theme/unix_theme.dart';
import 'package:flutter/material.dart';
import 'admin_store.dart';
import 'admin_style.dart';
import 'admin_actividad_page.dart';

class AdminMacroeventosPage extends StatefulWidget {
  const AdminMacroeventosPage({
    super.key,
    required this.store,
    this.compact = false,
  });
  final AdminStore store;
  final bool compact;
  @override
  State<AdminMacroeventosPage> createState() => _AdminMacroeventosPageState();
}

class _AdminMacroeventosPageState extends State<AdminMacroeventosPage> {
  String query = '';
  ActivityStatus? filter;
  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: createMacro,
            icon: Icon(Icons.add),
            label: Text('Crear macro evento'),
          ),
        ),
        SizedBox(height: 16),
        AdminPanel(
          title: 'Macro eventos',
          child: Column(
            children: [
              TextField(
                onChanged: (v) =>
                    setState(() => query = v.toLowerCase().trim()),
                decoration: InputDecoration(
                  hintText: 'Buscar macro eventos o actividades…',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('Todos'),
                      selected: filter == null,
                      onSelected: (_) => setState(() => filter = null),
                    ),
                    for (final status in ActivityStatus.values)
                      ChoiceChip(
                        label: Text(status.label),
                        selected: filter == status,
                        onSelected: (_) => setState(() => filter = status),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              ...buildMacros(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> buildMacros() {
    final cards = <Widget>[];
    for (final macro in widget.store.macros) {
      final macroMatches = macro.title.toLowerCase().contains(query);
      final activities = macro.activities
          .where(
            (a) =>
                (macroMatches || a.title.toLowerCase().contains(query)) &&
                (filter == null || a.status == filter),
          )
          .toList();
      if (activities.isEmpty && !(macroMatches && filter == null)) continue;
      cards.add(
        Container(
          margin: EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AdminStyle.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            key: PageStorageKey('${widget.compact}-${macro.id}'),
            initiallyExpanded: true,
            shape: Border(),
            title: Text(
              macro.title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${macro.date} · ${macro.activities.length} subeventos · '
              '${macro.isUnlimited ? 'Cupo ilimitado' : 'Cupo: ${macro.capacity} personas'}',
              style: TextStyle(color: AdminStyle.muted),
            ),
            childrenPadding: EdgeInsets.all(12),
            children: [
              if (activities.isEmpty)
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Este macro evento todavía no tiene actividades.',
                  ),
                ),
              for (final a in activities)
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: AdminStyle.background,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => openActivity(a),
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(
                              a.type == 'Curso'
                                  ? Icons.school_outlined
                                  : Icons.terminal,
                              color: AdminStyle.orange,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      Text(
                                        a.type,
                                        style: TextStyle(
                                          color: AdminStyle.muted,
                                        ),
                                      ),
                                      AdminBadge(
                                        a.status.label,
                                        color: statusColor(a.status),
                                      ),
                                    ],
                                  ),
                                  if (a.status == ActivityStatus.recruiting)
                                    Padding(
                                      padding: EdgeInsets.only(top: 6),
                                      child: Text(
                                        '${a.candidates.length} postulantes a expositor',
                                        style: TextStyle(
                                          color: AdminStyle.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AdminStyle.muted),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => createActivity(macro),
                  icon: Icon(Icons.add),
                  label: Text('Añadir subevento'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return cards.isEmpty
        ? [
            Padding(
              padding: EdgeInsets.all(20),
              child: Text('No hay resultados para estos filtros.'),
            ),
          ]
        : cards;
  }

  void openActivity(EventActivity a) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminActividadPage(store: widget.store, activity: a),
      ),
    );
  }

  Future<void> createMacro() async {
  final value = await showDialog<List<String>>(
    context: context,
    builder: (_) => const _CreateForm(macro: true),
  );

  if (value == null || !mounted) return;

  widget.store.addMacro(
    value[0],
    value[1],
    capacity: value[2].isEmpty ? null : int.parse(value[2]),
  );

  setState(() {
    query = '';
    filter = null;
  });

  adminMessage(context, 'Evento principal creado en esta demostración.');
}

  Future<void> createActivity(MacroEvent macro) async {
    final value = await showDialog<List<String>>(
      context: context,
      builder: (_) => const _CreateForm(macro: false),
    );

    if (value == null || !mounted) return;

    widget.store.addActivity(
      macro,
      value[0],
      value[1],
      capacity: int.parse(value[2]),
    );

    setState(() => filter = null);

    adminMessage(context, 'Subevento creado en esta demostración.');
  }
}

Color statusColor(ActivityStatus s) => switch (s) {
  ActivityStatus.recruiting => AdminStyle.orange,
  ActivityStatus.draft => UnixColors.adapt(Color(0xFFB6A6FA)),
  ActivityStatus.published => AdminStyle.green,
};

class _CreateForm extends StatefulWidget {
  const _CreateForm({required this.macro});

  final bool macro;

  @override
  State<_CreateForm> createState() => _CreateFormState();
}

class _CreateFormState extends State<_CreateForm> {
  final form = GlobalKey<FormState>();

  final title = TextEditingController();
  final dates = TextEditingController();
  final capacity = TextEditingController(text: '30');

  String type = 'Exposición';
  bool unlimited = true;

  @override
  void dispose() {
    title.dispose();
    dates.dispose();
    capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);

    // Solo el evento principal puede tener cupo ilimitado.
    final isUnlimited = widget.macro && unlimited;

    return AlertDialog(
      title: Text(
        widget.macro
            ? 'Crear evento principal'
            : 'Agregar subevento',
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: title,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    hintText: widget.macro
                        ? 'Semana de Ingeniería'
                        : 'Fibra óptica',
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Escribe un nombre.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // El principal solicita fechas.
                // El subevento solicita el tipo de actividad.
                if (widget.macro)
                  TextFormField(
                    controller: dates,
                    decoration: const InputDecoration(
                      labelText: 'Fechas',
                      hintText: 'Ej. 9–13 NOV 2026',
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Indica las fechas.';
                      }
                      return null;
                    },
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de subevento',
                    ),
                    items: ['Curso', 'Exposición', 'Taller']
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => type = value);
                    },
                  ),

                const SizedBox(height: 20),
                const Text(
                  'Límite de asistentes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Este interruptor aparece solo en el principal.
                if (widget.macro)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cupo ilimitado'),
                    subtitle: const Text(
                      'Desactívalo para indicar un máximo.',
                    ),
                    value: unlimited,
                    onChanged: (value) {
                      setState(() => unlimited = value);
                    },
                  ),

                // El campo aparece si hay un límite.
                if (!isUnlimited)
                  TextFormField(
                    controller: capacity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cupo máximo',
                      hintText: 'Ej. 30',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    validator: (value) {
                      final number = int.tryParse(
                        (value ?? '').trim(),
                      );

                      if (number == null || number < 1) {
                        return 'Ingresa un número entero mayor a cero.';
                      }

                      return null;
                    },
                  ),

                const SizedBox(height: 14),
                Text(
                  widget.macro
                      ? 'Después podrás añadir varios subeventos, '
                          'cada uno con su propio cupo.'
                      : 'Este subevento se creará en estado Reclutando. '
                          'Podrás editar su fecha, horario y lugar '
                          'desde su detalle.',
                  style: TextStyle(color: AdminStyle.muted),
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
            if (!form.currentState!.validate()) return;

            Navigator.pop<List<String>>(context, [
              title.text.trim(),
              widget.macro ? dates.text.trim() : type,
              isUnlimited ? '' : capacity.text.trim(),
            ]);
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}