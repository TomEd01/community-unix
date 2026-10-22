import 'package:flutter/material.dart';
import 'admin_store.dart';
import 'admin_style.dart';

class AdminFoliosPage extends StatefulWidget {
  const AdminFoliosPage({super.key, required this.store});
  final AdminStore store;
  @override
  State<AdminFoliosPage> createState() => _AdminFoliosPageState();
}
class _AdminFoliosPageState extends State<AdminFoliosPage> {
  final code = TextEditingController();
  @override
  void dispose() { code.dispose(); super.dispose(); }
  void verify() {
    if (code.text.trim().isEmpty) { adminMessage(context, 'Ingresa un folio.'); return; }
    final folio = widget.store.findFolio(code.text);
    final user = folio == null ? null : widget.store.user(folio.userId);
    showDialog<void>(context: context, builder: (dialog) => AlertDialog(
      title: Text(folio == null ? 'Folio no encontrado' : 'Registro de ejemplo encontrado'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (folio == null) const Text('Este código no existe en los datos de demostración.')
          else ...[const AdminBadge('DEMO · Sin validación oficial'),
            const SizedBox(height: 14), Text('Nombre: ${user!.name}'),
            Text('Número de control: ${user.id}'),
            Text('Folio: ${folio.code}'), const SizedBox(height: 10),
            Text('Tipo: ${folio.kind}'), Text('Actividad: ${folio.activity}'),
            if (folio.expositions > 0) Text('Exposiciones completadas: ${folio.expositions}'),
            const SizedBox(height: 14),
            const Text('El folio no otorga créditos automáticamente. '
              'La validación y firma física corresponden al personal autorizado.',
              style: TextStyle(color: AdminStyle.muted)),
          ]
        ])), actions: [TextButton(onPressed: () => Navigator.pop(dialog),
          child: const Text('Cerrar'))]));
  }
  @override
  Widget build(BuildContext context) => AdminPanel(title: 'Verificador de folios',
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Consulta el registro de una actividad o candidatura a liberación de crédito.',
        style: TextStyle(color: AdminStyle.muted)), const SizedBox(height: 18),
      TextField(controller: code, onSubmitted: (_) => verify(),
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(labelText: 'Folio', hintText: 'UNIX-21530369-X9Y2A',
          prefixIcon: Icon(Icons.verified_user_outlined))),
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: verify, icon: const Icon(Icons.search),
        label: const Text('Verificar')),
      const SizedBox(height: 22), const Text('Prueba estos códigos de ejemplo:',
        style: TextStyle(color: AdminStyle.muted)),
      TextButton(onPressed: () => code.text = 'UNIX-21530369-X9Y2A',
        child: const Text('UNIX-21530369-X9Y2A')),
      TextButton(onPressed: () => code.text = 'UNIX-21530369-C5EXP',
        child: const Text('UNIX-21530369-C5EXP')),
      const Text('La autenticidad real deberá comprobarse consultando el backend.',
        style: TextStyle(color: AdminStyle.muted, fontSize: 12)),
    ]));
}
