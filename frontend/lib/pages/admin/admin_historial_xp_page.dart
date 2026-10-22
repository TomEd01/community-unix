import 'package:flutter/material.dart';
import 'admin_store.dart';
import 'admin_style.dart';

class AdminHistorialXpPage extends StatefulWidget {
  const AdminHistorialXpPage({super.key, required this.store});
  final AdminStore store;
  @override
  State<AdminHistorialXpPage> createState() => _AdminHistorialXpPageState();
}
class _AdminHistorialXpPageState extends State<AdminHistorialXpPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final entries = widget.store.ledger.where((entry) {
      final user = widget.store.user(entry.userId);
      return '${user.name} ${user.id} ${entry.reason} ${entry.id}'
        .toLowerCase().contains(query);
    }).toList();
    return AdminPanel(title: 'Historial de movimientos XP', child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Consulta de solo lectura. Incluye recompensas y penalizaciones.',
          style: TextStyle(color: AdminStyle.muted)), const SizedBox(height: 16),
        TextField(onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
          decoration: const InputDecoration(hintText: 'Buscar alumno, ID o movimiento',
            prefixIcon: Icon(Icons.search))), const SizedBox(height: 16),
        if (entries.isEmpty) const Text('No hay movimientos con estos filtros.'),
        for (final entry in entries) Padding(padding: const EdgeInsets.only(bottom: 12),
          child: Container(decoration: BoxDecoration(color: AdminStyle.background,
            borderRadius: BorderRadius.circular(12)),
            child: ListTile(title: Text(widget.store.user(entry.userId).name),
              subtitle: Text('${entry.reason}\n${entry.date} · ${entry.id}'),
              isThreeLine: true,
              trailing: AdminBadge('${entry.points > 0 ? '+' : ''}${entry.points} XP',
                color: entry.points > 0 ? AdminStyle.green : AdminStyle.red)))),
        const Text('El ledger inmutable debe garantizarse en el servidor. '
          'Esta pantalla utiliza registros de ejemplo.',
          style: TextStyle(color: AdminStyle.muted, fontSize: 12)),
      ]));
  }
}
