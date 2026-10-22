import 'package:flutter/material.dart';
import 'admin_store.dart';
import 'admin_style.dart';
import 'admin_actividad_page.dart';

class AdminMacroeventosPage extends StatefulWidget {
  const AdminMacroeventosPage({super.key, required this.store, this.compact = false});
  final AdminStore store;
  final bool compact;
  @override
  State<AdminMacroeventosPage> createState() => _AdminMacroeventosPageState();
}
class _AdminMacroeventosPageState extends State<AdminMacroeventosPage> {
  String query = '';
  ActivityStatus? filter;
  @override
  Widget build(BuildContext context) => Column(children: [
    Align(alignment: Alignment.centerRight, child: FilledButton.icon(
      onPressed: createMacro, icon: const Icon(Icons.add),
      label: const Text('Crear macro evento'))),
    const SizedBox(height: 16),
    AdminPanel(title: 'Macro eventos', child: Column(children: [
      TextField(onChanged: (v) => setState(() => query = v.toLowerCase().trim()),
        decoration: const InputDecoration(hintText: 'Buscar macro eventos o actividades…',
          prefixIcon: Icon(Icons.search))),
      const SizedBox(height: 12),
      Align(alignment: Alignment.centerLeft, child: Wrap(spacing: 8, runSpacing: 8,
        children: [ChoiceChip(label: const Text('Todos'), selected: filter == null,
          onSelected: (_) => setState(() => filter = null)),
          for (final status in ActivityStatus.values) ChoiceChip(label: Text(status.label),
            selected: filter == status, onSelected: (_) => setState(() => filter = status)),
        ])),
      const SizedBox(height: 16),
      ...buildMacros(),
    ])),
  ]);
  List<Widget> buildMacros() {
    final cards = <Widget>[];
    for (final macro in widget.store.macros) {
      final macroMatches = macro.title.toLowerCase().contains(query);
      final activities = macro.activities.where((a) =>
        (macroMatches || a.title.toLowerCase().contains(query)) &&
        (filter == null || a.status == filter)).toList();
      if (activities.isEmpty && !(macroMatches && filter == null)) continue;
      cards.add(Container(margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(border: Border.all(color: AdminStyle.border),
          borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(key: PageStorageKey('${widget.compact}-${macro.id}'),
          initiallyExpanded: true, shape: const Border(),
          title: Text(macro.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${macro.date} · ${macro.activities.length} actividades',
            style: const TextStyle(color: AdminStyle.muted)),
          childrenPadding: const EdgeInsets.all(12), children: [
            if (activities.isEmpty) const Padding(padding: EdgeInsets.all(12),
              child: Text('Este macro evento todavía no tiene actividades.')),
            for (final a in activities) Padding(padding: const EdgeInsets.only(bottom: 10),
              child: Material(color: AdminStyle.background,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(borderRadius: BorderRadius.circular(12),
                  onTap: () => openActivity(a),
                  child: Padding(padding: const EdgeInsets.all(14),
                    child: Row(children: [Icon(a.type == 'Curso'
                      ? Icons.school_outlined : Icons.terminal, color: AdminStyle.orange),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Wrap(spacing: 8, runSpacing: 6, children: [
                            Text(a.type, style: const TextStyle(color: AdminStyle.muted)),
                            AdminBadge(a.status.label, color: statusColor(a.status)),
                          ]),
                          if (a.status == ActivityStatus.recruiting) Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('${a.candidates.length} postulantes a expositor',
                              style: const TextStyle(color: AdminStyle.muted, fontSize: 12))),
                        ])),
                      const Icon(Icons.chevron_right, color: AdminStyle.muted),
                    ]))))),
            Align(alignment: Alignment.centerLeft, child: TextButton.icon(
              onPressed: () => createActivity(macro), icon: const Icon(Icons.add),
              label: const Text('Agregar actividad'))),
          ])));
    }
    return cards.isEmpty ? [const Padding(padding: EdgeInsets.all(20),
      child: Text('No hay resultados para estos filtros.'))] : cards;
  }
  void openActivity(EventActivity a) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
      AdminActividadPage(store: widget.store, activity: a)));
  }
  Future<void> createMacro() async {
    final value = await showDialog<List<String>>(context: context,
      builder: (_) => const _CreateForm(macro: true));
    if (value != null && mounted) {
      widget.store.addMacro(value[0], value[1]);
      setState(() { query = ''; filter = null; });
      adminMessage(context, 'Macro evento creado en esta demostración.');
    }
  }
  Future<void> createActivity(MacroEvent macro) async {
    final value = await showDialog<List<String>>(context: context,
      builder: (_) => const _CreateForm(macro: false));
    if (value != null && mounted) {
      widget.store.addActivity(macro, value[0], value[1]);
      setState(() => filter = null);
    }
  }
}
Color statusColor(ActivityStatus s) => switch (s) {
  ActivityStatus.recruiting => AdminStyle.orange,
  ActivityStatus.draft => const Color(0xFFB6A6FA),
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
  String type = 'Exposición';
  @override
  void dispose() { title.dispose(); dates.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.macro ? 'Crear macro evento' : 'Agregar actividad'),
    content: SizedBox(width: 440, child: SingleChildScrollView(child: Form(key: form,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: title, maxLength: 100,
          decoration: const InputDecoration(labelText: 'Nombre'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Escribe un nombre.' : null),
        const SizedBox(height: 12),
        if (widget.macro) TextFormField(controller: dates,
          decoration: const InputDecoration(labelText: 'Fechas (ej. 26–30 OCT 2026)'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Indica las fechas.' : null)
        else DropdownButtonFormField<String>(initialValue: type,
          decoration: const InputDecoration(labelText: 'Tipo'),
          items: ['Curso', 'Exposición', 'Taller'].map((t) =>
            DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => type = v ?? type)),
        const SizedBox(height: 14),
        Text(widget.macro ? 'Contendrá cursos, exposiciones y talleres.'
          : 'Se creará en estado Reclutando.', style: const TextStyle(color: AdminStyle.muted)),
      ])))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(onPressed: () {
        if (form.currentState!.validate()) Navigator.pop(context,
          [title.text.trim(), widget.macro ? dates.text.trim() : type]);
      }, child: const Text('Crear'))]);
}
