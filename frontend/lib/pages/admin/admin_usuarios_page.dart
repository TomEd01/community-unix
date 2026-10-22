import 'package:flutter/material.dart';
import 'admin_store.dart';
import 'admin_style.dart';

class AdminUsuariosPage extends StatefulWidget {
  const AdminUsuariosPage({super.key, required this.store});
  final AdminStore store;
  @override
  State<AdminUsuariosPage> createState() => _AdminUsuariosPageState();
}
class _AdminUsuariosPageState extends State<AdminUsuariosPage> {
  String query = '';
  String role = 'Todos';
  @override
  Widget build(BuildContext context) {
    final users = widget.store.users.where((u) => (role == 'Todos' || u.role == role)
      && '${u.name} ${u.id} ${u.email}'.toLowerCase().contains(query)).toList();
    return AdminPanel(title: 'Usuarios registrados', child: Column(children: [
      TextField(onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
        decoration: const InputDecoration(hintText: 'Buscar nombre, ID o correo',
          prefixIcon: Icon(Icons.search))),
      const SizedBox(height: 12),
      Align(alignment: Alignment.centerLeft, child: Wrap(spacing: 8, runSpacing: 8,
        children: [for (final r in ['Todos', 'Alumno', 'Maestro', 'Externo'])
          ChoiceChip(label: Text(r), selected: role == r,
            onSelected: (_) => setState(() => role = r))])),
      const SizedBox(height: 14),
      if (users.isEmpty) const Text('No hay usuarios con estos filtros.'),
      for (final u in users) Padding(padding: const EdgeInsets.only(bottom: 10),
        child: Container(decoration: BoxDecoration(color: AdminStyle.background,
          borderRadius: BorderRadius.circular(12)),
          child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: CircleAvatar(child: Text(u.name.substring(0, 1))),
            title: Text(u.name),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${u.id} · ${u.email}'), const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [AdminBadge(u.role),
                AdminBadge(u.active ? 'Activo' : 'Inactivo',
                  color: u.active ? AdminStyle.green : AdminStyle.red)])]),
            trailing: PopupMenuButton<String>(tooltip: 'Opciones de usuario',
              onSelected: (_) => confirmToggle(u),
              itemBuilder: (_) => [PopupMenuItem(value: 'toggle',
                child: Text(u.active ? 'Desactivar' : 'Activar'))]),
          ))),
      const Text('Los cambios de acceso son locales. El backend deberá validar '
        'permisos y registrar las acciones administrativas.',
        style: TextStyle(color: AdminStyle.muted, fontSize: 12)),
    ]));
  }
  Future<void> confirmToggle(AdminUser u) async {
    final result = await showDialog<bool>(context: context, builder: (dialog) =>
      AlertDialog(title: Text(u.active ? 'Desactivar usuario' : 'Activar usuario'),
        content: Text('¿Confirmas el cambio para ${u.name}? Solo afectará esta demostración.'),
        actions: [TextButton(onPressed: () => Navigator.pop(dialog, false),
          child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Confirmar'))]));
    if (result == true && mounted) widget.store.toggleUser(u);
  }
}
