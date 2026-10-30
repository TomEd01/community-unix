import '../../theme/unix_theme.dart';
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
  void dispose() {
    code.dispose();
    super.dispose();
  }

  void verify() {
    if (code.text.trim().isEmpty) {
      adminMessage(context, 'Ingresa un folio.');
      return;
    }
    final folio = widget.store.findFolio(code.text);
    final user = folio == null ? null : widget.store.user(folio.userId);
    showDialog<void>(
      context: context,
      builder: (dialog) {
        UnixTheme.watch(dialog);
        return AlertDialog(
          title: Text(
            folio == null
                ? 'Folio no encontrado'
                : 'Registro de ejemplo encontrado',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (folio == null)
                  Text('Este código no existe en los datos de demostración.')
                else ...[
                  AdminBadge('DEMO · Sin validación oficial'),
                  SizedBox(height: 14),
                  Text('Nombre: ${user!.name}'),
                  Text('Número de control: ${user.id}'),
                  Text('Folio: ${folio.code}'),
                  SizedBox(height: 10),
                  Text('Tipo: ${folio.kind}'),
                  Text('Actividad: ${folio.activity}'),
                  if (folio.expositions > 0)
                    Text('Exposiciones completadas: ${folio.expositions}'),
                  SizedBox(height: 14),
                  Text(
                    'El folio no otorga créditos automáticamente. '
                    'La validación y firma física corresponden al personal autorizado.',
                    style: TextStyle(color: AdminStyle.muted),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return AdminPanel(
      title: 'Verificador de folios',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consulta el registro de una actividad o candidatura a liberación de crédito.',
            style: TextStyle(color: AdminStyle.muted),
          ),
          SizedBox(height: 18),
          TextField(
            controller: code,
            onSubmitted: (_) => verify(),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Folio',
              hintText: 'UNIX-21530369-X9Y2A',
              prefixIcon: Icon(Icons.verified_user_outlined),
            ),
          ),
          SizedBox(height: 14),
          FilledButton.icon(
            onPressed: verify,
            icon: Icon(Icons.search),
            label: Text('Verificar'),
          ),
          SizedBox(height: 22),
          Text(
            'Prueba estos códigos de ejemplo:',
            style: TextStyle(color: AdminStyle.muted),
          ),
          TextButton(
            onPressed: () => code.text = 'UNIX-21530369-X9Y2A',
            child: Text('UNIX-21530369-X9Y2A'),
          ),
          TextButton(
            onPressed: () => code.text = 'UNIX-21530369-C5EXP',
            child: Text('UNIX-21530369-C5EXP'),
          ),
          Text(
            'La autenticidad real deberá comprobarse consultando el backend.',
            style: TextStyle(color: AdminStyle.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
