import 'package:flutter/material.dart';
import 'admin_store.dart';
import 'admin_style.dart';

class AdminPerfilPage extends StatefulWidget {
  const AdminPerfilPage({super.key, required this.store,
    this.onLogout, this.loggingOut = false});
  final AdminStore store;
  final Future<void> Function()? onLogout;
  final bool loggingOut;
  @override
  State<AdminPerfilPage> createState() => _AdminPerfilPageState();
}
class _AdminPerfilPageState extends State<AdminPerfilPage> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name;
  @override
  void initState() { super.initState(); name = TextEditingController(text: widget.store.adminName); }
  @override
  void dispose() { name.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AdminPanel(title: 'Mi perfil',
    child: Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [const CircleAvatar(radius: 30,
          backgroundColor: AdminStyle.border, child: Icon(Icons.admin_panel_settings_outlined,
            color: AdminStyle.orange, size: 32)), const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.store.adminName, style: const TextStyle(fontSize: 20,
              fontWeight: FontWeight.bold)),
            const SizedBox(height: 6), const AdminBadge('Super Admin', color: AdminStyle.green),
            const SizedBox(height: 6), Text('ID: ${widget.store.adminId}',
              style: const TextStyle(color: AdminStyle.muted)),
          ]))]),
        const SizedBox(height: 24),
        TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nombre completo'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Escribe tu nombre.' : null),
        const SizedBox(height: 14),
        TextFormField(initialValue: widget.store.adminEmail.isEmpty
          ? 'Sin correo proporcionado' : widget.store.adminEmail,
          readOnly: true, decoration: const InputDecoration(labelText: 'Correo electrónico',
            suffixIcon: Icon(Icons.lock_outline))),
        const SizedBox(height: 14),
        TextFormField(initialValue: 'Super Admin', readOnly: true,
          decoration: const InputDecoration(labelText: 'Rol', suffixIcon: Icon(Icons.lock_outline))),
        const SizedBox(height: 20),
        Wrap(spacing: 12, runSpacing: 12, children: [
          FilledButton.icon(onPressed: () {
            if (form.currentState!.validate()) {
              widget.store.updateName(name.text.trim());
              adminMessage(context, 'Perfil actualizado solo en esta demostración.');
            }
          }, icon: const Icon(Icons.save_outlined), label: const Text('Actualizar perfil')),
          OutlinedButton.icon(onPressed: widget.onLogout == null || widget.loggingOut
            ? null : () { widget.onLogout!(); }, icon: const Icon(Icons.logout),
            label: Text(widget.loggingOut ? 'Cerrando sesión…' : 'Cerrar sesión')),
        ]),
        const SizedBox(height: 18),
        const Text('El cierre de sesión se habilita al conectar onLogout con la '
          'autenticación del proyecto.', style: TextStyle(color: AdminStyle.muted, fontSize: 12)),
      ])));
}
