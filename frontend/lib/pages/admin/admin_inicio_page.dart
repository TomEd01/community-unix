import '../../theme/unix_theme.dart';
import 'package:flutter/material.dart';
import 'admin_store.dart';
import 'admin_style.dart';
import 'admin_macroeventos_page.dart';

class AdminInicioPage extends StatelessWidget {
  const AdminInicioPage({
    super.key,
    required this.store,
    required this.onNavigate,
    this.nombre = '',
  });
  final AdminStore store;
  final ValueChanged<int> onNavigate;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestiona eventos, expositores y participación.',
          style: TextStyle(color: UnixColors.muted),
        ),
        const SizedBox(height: 20),
        _metrics(),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1050) {
              return Column(
                children: [
                  _quickActions(),
                  const SizedBox(height: 20),
                  AdminMacroeventosPage(store: store, compact: true),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: AdminMacroeventosPage(store: store, compact: true),
                ),
                const SizedBox(width: 18),
                Expanded(child: _quickActions()),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _metrics() => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 850
          ? 4
          : constraints.maxWidth >= 340
          ? 2
          : 1;
      final metrics = [
        (
          'Reclutando',
          store.count(ActivityStatus.recruiting),
          Icons.people_alt_outlined,
          AdminStyle.orange,
        ),
        (
          'Borrador',
          store.count(ActivityStatus.draft),
          Icons.description_outlined,
          UnixColors.adapt(const Color(0xFFB6A6FA)),
        ),
        (
          'Publicados',
          store.count(ActivityStatus.published),
          Icons.play_arrow_rounded,
          AdminStyle.green,
        ),
        (
          'Inscritos',
          store.enrolled,
          Icons.groups_outlined,
          UnixColors.adapt(const Color(0xFF2796FF)),
        ),
      ];
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final item in metrics)
            SizedBox(
              width: (constraints.maxWidth - 12 * (columns - 1)) / columns,
              child: InkWell(
                onTap: () => onNavigate(1),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: UnixColors.card,
                    border: Border.all(color: UnixColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: item.$4.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.$3, color: item.$4),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.$2}',
                              style: TextStyle(
                                color: UnixColors.text,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              item.$1,
                              style: TextStyle(
                                color: UnixColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _quickActions() => AdminPanel(
    title: 'Accesos rápidos',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Las herramientas de tu comunidad, a un clic.',
          style: TextStyle(color: UnixColors.muted, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 16),
        _action(
          'Macro eventos',
          'Crea y organiza actividades.',
          Icons.event_outlined,
          1,
          primary: true,
        ),
        const SizedBox(height: 12),
        _action(
          'Ver usuarios',
          'Consulta y administra perfiles.',
          Icons.groups_outlined,
          2,
        ),
        const SizedBox(height: 12),
        _action(
          'Verificar folios',
          'Consulta actividades acreditadas.',
          Icons.verified_user_outlined,
          3,
        ),
      ],
    ),
  );

  Widget _action(
    String title,
    String description,
    IconData icon,
    int index, {
    bool primary = false,
  }) {
    final foreground = primary ? UnixColors.onOrange : UnixColors.text;
    return Material(
      color: primary ? UnixColors.orange : UnixColors.field,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: primary
              ? UnixColors.orange
              : UnixColors.border.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        onTap: () => onNavigate(index),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: primary ? foreground : UnixColors.muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: foreground, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
