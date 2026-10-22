import 'package:flutter/material.dart';
import 'admin_store.dart';
import 'admin_style.dart';
import 'admin_macroeventos_page.dart';

class AdminInicioPage extends StatelessWidget {
  const AdminInicioPage({super.key, required this.store, required this.onNavigate});
  final AdminStore store;
  final ValueChanged<int> onNavigate;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Gestiona eventos, expositores y participación.',
        style: TextStyle(color: AdminStyle.muted)),
      const SizedBox(height: 18),
      LayoutBuilder(builder: (context, c) {
        final columns = c.maxWidth >= 850 ? 4 : c.maxWidth >= 340 ? 2 : 1;
        final metrics = [
          ('Reclutando', store.count(ActivityStatus.recruiting), Icons.people_alt_outlined,
            AdminStyle.orange),
          ('Borrador', store.count(ActivityStatus.draft), Icons.description_outlined,
            const Color(0xFFB6A6FA)),
          ('Publicados', store.count(ActivityStatus.published), Icons.play_arrow_rounded,
            AdminStyle.green),
          ('Inscritos', store.enrolled, Icons.groups_outlined, const Color(0xFF2796FF)),
        ];
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (final item in metrics) SizedBox(
            width: (c.maxWidth - 12 * (columns - 1)) / columns,
            child: InkWell(onTap: () => onNavigate(1),
              borderRadius: BorderRadius.circular(16),
              child: AdminPanel(title: '${item.$2}', child: Row(children: [
                Icon(item.$3, color: item.$4), const SizedBox(width: 8),
                Flexible(child: Text(item.$1, style: TextStyle(color: item.$4))),
              ])))),
        ]);
      }),
      const SizedBox(height: 22),
      AdminMacroeventosPage(store: store, compact: true),
      const SizedBox(height: 20),
      AdminPanel(title: 'Verificar folio', child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 12,
        children: [const Text('Consulta autenticidad y actividades acreditadas.'),
          OutlinedButton.icon(onPressed: () => onNavigate(3),
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Abrir verificador'))])),
    ]);
}
