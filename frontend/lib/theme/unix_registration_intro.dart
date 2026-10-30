import 'unix_lexus_portrait.dart';
import 'package:flutter/material.dart';
import 'unix_theme.dart';

class UnixRegistrationIntro extends StatelessWidget {
  const UnixRegistrationIntro({super.key, this.compact = false});
  final bool compact;

  Widget _benefit(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: UnixColors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: UnixColors.dark
                ? UnixColors.orange
                : const Color(0xFFA94700),
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: UnixColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: UnixColors.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final short =
            !compact &&
            constraints.hasBoundedHeight &&
            constraints.maxHeight < 640;
        final panelPadding = compact ? 20.0 : 26.0;
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Tu comunidad empieza aquí',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: UnixColors.text,
                fontSize: compact || short ? 24 : 28,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Forma parte de un espacio donde la tecnología, el aprendizaje y las personas se encuentran.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: UnixColors.muted,
                fontSize: short ? 12 : 14,
                height: 1.5,
              ),
            ),
            if (!compact) ...[
              SizedBox(height: short ? 12 : 20),
              UnixLexusPortrait(width: short ? 132 : 166),
              SizedBox(height: short ? 14 : 22),
            ],
            if (compact || short)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    for (final label in ['Aprende', 'Participa', 'Conecta'])
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: UnixColors.muted,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            label,
                            style: TextStyle(
                              color: UnixColors.text,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              )
            else ...[
              _benefit(
                Icons.menu_book_outlined,
                'Aprende',
                'Descubre cursos, talleres y contenido especializado.',
              ),
              const SizedBox(height: 16),
              _benefit(
                Icons.groups_outlined,
                'Participa',
                'Únete a actividades y forma parte de la comunidad.',
              ),
              const SizedBox(height: 16),
              _benefit(
                Icons.hub_outlined,
                'Conecta',
                'Comparte tus intereses con otros miembros.',
              ),
            ],
          ],
        );
        return Container(
          padding: EdgeInsets.all(panelPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: UnixColors.dark
                  ? const [Color(0xFF0A2947), Color(0xFF123F62)]
                  : const [Color(0xFFEAF3FF), Color(0xFFD8EAFF)],
            ),
          ),
          child: compact
              ? content
              : Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: (constraints.maxWidth - panelPadding * 2).clamp(
                        1.0,
                        400.0,
                      ),
                      child: content,
                    ),
                  ),
                ),
        );
      },
    );
  }
}
