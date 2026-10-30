import '../../theme/unix_theme.dart';
import 'package:flutter/material.dart';

class AlumnoComunidadPage extends StatelessWidget {
  const AlumnoComunidadPage({super.key});

  static Color get _bg => UnixColors.adapt(Color(0xFF031426));
  static Color get _card => UnixColors.adapt(Color(0xFF0A2947));
  static Color get _border => UnixColors.border;
  static const Color _orange = Color(0xFFFF8A24);
  static Color get _blue => UnixColors.adapt(Color(0xFF2796FF));
  static Color get _green => UnixColors.adapt(Color(0xFF35D59A));
  static Color get _muted => UnixColors.adapt(Color(0xFF91A9BE));

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Container(
      color: _bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          UnixTheme.watch(context);
          final bool mobile = constraints.maxWidth < 760;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              mobile ? 16 : 28,
              mobile ? 20 : 30,
              mobile ? 16 : 28,
              50,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1250),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(mobile),
                    SizedBox(height: 28),
                    _buildFeatured(mobile),
                    SizedBox(height: 34),
                    _buildSectionTitle(
                      'Explora la comunidad',
                      'Participa, aprende y comparte con otros miembros.',
                    ),
                    SizedBox(height: 18),
                    _buildCommunityOptions(mobile),
                    SizedBox(height: 34),
                    _buildSectionTitle(
                      'Próximas actividades',
                      'No te pierdas lo que está por venir.',
                    ),
                    SizedBox(height: 18),
                    _buildActivities(mobile),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(bool mobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'COMUNIDAD ACTIVA',
            style: TextStyle(
              color: _orange,
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(height: 15),
        Text(
          mobile
              ? 'Aprendemos mejor\nen comunidad'
              : 'Aprendemos mejor en comunidad',
          style: TextStyle(
            color: UnixColors.text,
            fontSize: mobile ? 29 : 36,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 10),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 760),
          child: Text(
            'Conecta con estudiantes e instructores, participa en actividades '
            'y descubre nuevos recursos para seguir aprendiendo.',
            style: TextStyle(color: _muted, fontSize: 14, height: 1.55),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EVENTO DESTACADO
  // ============================================================

  Widget _buildFeatured(bool mobile) {
    final Widget info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EVENTO DESTACADO',
          style: TextStyle(
            color: _green,
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Linux Install Fest',
          style: TextStyle(
            color: UnixColors.text,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Aprende a instalar Linux junto con otros miembros de la comunidad. '
          'Habrá apoyo para principiantes y espacio para compartir experiencias.',
          style: TextStyle(color: _muted, fontSize: 13, height: 1.55),
        ),
        SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [
            _InfoChip(icon: Icons.calendar_today_outlined, text: 'Viernes'),
            _InfoChip(icon: Icons.schedule_rounded, text: '4:00 PM'),
            _InfoChip(icon: Icons.location_on_outlined, text: 'Lab. Sistemas'),
          ],
        ),
        SizedBox(height: 22),
        FilledButton.icon(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: UnixColors.text,
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          icon: Icon(Icons.event_available_rounded, size: 19),
          label: Text(
            'Ver evento',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );

    final Widget illustration = Container(
      width: mobile ? double.infinity : 240,
      height: mobile ? 150 : 210,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.groups_rounded, size: 88, color: _orange),
          Positioned(
            top: 27,
            right: 32,
            child: Icon(Icons.terminal_rounded, color: _blue, size: 28),
          ),
          Positioned(
            left: 32,
            bottom: 28,
            child: Icon(Icons.auto_awesome_rounded, color: _green, size: 25),
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 22 : 30),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [info, SizedBox(height: 25), illustration],
            )
          : Row(
              children: [
                Expanded(child: info),
                SizedBox(width: 35),
                illustration,
              ],
            ),
    );
  }

  // ============================================================
  // TÍTULOS DE SECCIÓN
  // ============================================================

  Widget _buildSectionTitle(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: UnixColors.text,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Text(description, style: TextStyle(color: _muted, fontSize: 13)),
      ],
    );
  }

  // ============================================================
  // OPCIONES DE COMUNIDAD
  // ============================================================

  Widget _buildCommunityOptions(bool mobile) {
    List<Widget> cards = [
      _CommunityCard(
        icon: Icons.forum_rounded,
        title: 'Noticias',
        description:
            'Descubre novedades, anuncios y actualizaciones de la comunidad.',
        action: 'Explorar noticias',
        accent: _orange,
      ),
      _CommunityCard(
        icon: Icons.groups_2_rounded,
        title: 'Grupos de estudio',
        description:
            'Encuentra personas que estén aprendiendo los mismos temas que tú.',
        action: 'Ver grupos',
        accent: _blue,
      ),
      _CommunityCard(
        icon: Icons.folder_copy_rounded,
        title: 'Recursos compartidos',
        description:
            'Consulta guías, apuntes y material recomendado por la comunidad.',
        action: 'Ver recursos',
        accent: _green,
      ),
    ];

    if (mobile) {
      return Column(
        children: [
          cards[0],
          SizedBox(height: 15),
          cards[1],
          SizedBox(height: 15),
          cards[2],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: cards[0]),
        SizedBox(width: 18),
        Expanded(child: cards[1]),
        SizedBox(width: 18),
        Expanded(child: cards[2]),
      ],
    );
  }

  // ============================================================
  // ACTIVIDADES
  // ============================================================

  Widget _buildActivities(bool mobile) {
    final Widget first = _ActivityCard(
      day: '18',
      month: 'OCT',
      title: 'Taller de Bash',
      description: 'Automatización y scripting desde cero.',
      time: '5:00 PM',
      icon: Icons.code_rounded,
    );

    final Widget second = _ActivityCard(
      day: '24',
      month: 'OCT',
      title: 'Introducción a Docker',
      description: 'Contenedores y conceptos fundamentales.',
      time: '4:30 PM',
      icon: Icons.inventory_2_rounded,
    );

    if (mobile) {
      return Column(children: [first, SizedBox(height: 14), second]);
    }

    return Row(
      children: [
        Expanded(child: first),
        SizedBox(width: 18),
        Expanded(child: second),
      ],
    );
  }
}

// ================================================================
// CHIP DE INFORMACIÓN
// ================================================================

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AlumnoComunidadPage._muted, size: 15),
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(color: AlumnoComunidadPage._muted, fontSize: 12),
        ),
      ],
    );
  }
}

// ================================================================
// TARJETA DE COMUNIDAD
// ================================================================

class _CommunityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String action;
  final Color accent;

  const _CommunityCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Container(
      padding: EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: AlumnoComunidadPage._card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AlumnoComunidadPage._border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: accent),
          ),
          SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              color: UnixColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 9),
          Text(
            description,
            style: TextStyle(
              color: AlumnoComunidadPage._muted,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          SizedBox(height: 17),
          TextButton.icon(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: accent,
              padding: EdgeInsets.zero,
            ),
            iconAlignment: IconAlignment.end,
            icon: Icon(Icons.arrow_forward_rounded, size: 16),
            label: Text(action, style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// TARJETA DE ACTIVIDAD
// ================================================================

class _ActivityCard extends StatelessWidget {
  final String day;
  final String month;
  final String title;
  final String description;
  final String time;
  final IconData icon;

  const _ActivityCard({
    required this.day,
    required this.month,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AlumnoComunidadPage._card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AlumnoComunidadPage._border),
      ),
      child: Row(
        children: [
          Container(
            width: 57,
            height: 62,
            decoration: BoxDecoration(
              color: AlumnoComunidadPage._orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: TextStyle(
                    color: UnixColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  month,
                  style: TextStyle(
                    color: AlumnoComunidadPage._orange,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AlumnoComunidadPage._blue, size: 16),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: UnixColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: AlumnoComunidadPage._muted,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  time,
                  style: TextStyle(
                    color: AlumnoComunidadPage._orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
