import 'package:flutter/material.dart';

class AlumnoComunidadPage extends StatelessWidget {
  const AlumnoComunidadPage({super.key});

  static const Color _bg = Color(0xFF031426);
  static const Color _card = Color(0xFF0A2947);
  static const Color _border = Color(0xFF174064);
  static const Color _orange = Color(0xFFFF8A24);
  static const Color _blue = Color(0xFF2796FF);
  static const Color _green = Color(0xFF35D59A);
  static const Color _muted = Color(0xFF91A9BE);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
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
                constraints: const BoxConstraints(maxWidth: 1250),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(mobile),
                    const SizedBox(height: 28),
                    _buildFeatured(mobile),
                    const SizedBox(height: 34),
                    _buildSectionTitle(
                      'Explora la comunidad',
                      'Participa, aprende y comparte con otros miembros.',
                    ),
                    const SizedBox(height: 18),
                    _buildCommunityOptions(mobile),
                    const SizedBox(height: 34),
                    _buildSectionTitle(
                      'Próximas actividades',
                      'No te pierdas lo que está por venir.',
                    ),
                    const SizedBox(height: 18),
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
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'COMUNIDAD ACTIVA',
            style: TextStyle(
              color: _orange,
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          mobile
              ? 'Aprendemos mejor\nen comunidad'
              : 'Aprendemos mejor en comunidad',
          style: TextStyle(
            color: Colors.white,
            fontSize: mobile ? 29 : 36,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
  constraints: const BoxConstraints(
    maxWidth: 760,
  ),
  child: const Text(
    'Conecta con estudiantes e instructores, participa en actividades '
    'y descubre nuevos recursos para seguir aprendiendo.',
    style: TextStyle(
      color: _muted,
      fontSize: 14,
      height: 1.55,
    ),
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
        const Text(
          'EVENTO DESTACADO',
          style: TextStyle(
            color: _green,
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Linux Install Fest',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Aprende a instalar Linux junto con otros miembros de la comunidad. '
          'Habrá apoyo para principiantes y espacio para compartir experiencias.',
          style: TextStyle(
            color: _muted,
            fontSize: 13,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 20),
        const Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [
            _InfoChip(
              icon: Icons.calendar_today_outlined,
              text: 'Viernes',
            ),
            _InfoChip(
              icon: Icons.schedule_rounded,
              text: '4:00 PM',
            ),
            _InfoChip(
              icon: Icons.location_on_outlined,
              text: 'Lab. Sistemas',
            ),
          ],
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          icon: const Icon(
            Icons.event_available_rounded,
            size: 19,
          ),
          label: const Text(
            'Ver evento',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    final Widget illustration = Container(
      width: mobile ? double.infinity : 240,
      height: mobile ? 150 : 210,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _border,
        ),
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.groups_rounded,
            size: 88,
            color: _orange,
          ),
          Positioned(
            top: 27,
            right: 32,
            child: Icon(
              Icons.terminal_rounded,
              color: _blue,
              size: 28,
            ),
          ),
          Positioned(
            left: 32,
            bottom: 28,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: _green,
              size: 25,
            ),
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        mobile ? 22 : 30,
      ),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _border,
        ),
      ),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 25),
                illustration,
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: info,
                ),
                const SizedBox(width: 35),
                illustration,
              ],
            ),
    );
  }

  // ============================================================
  // TÍTULOS DE SECCIÓN
  // ============================================================

  Widget _buildSectionTitle(
    String title,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(
            color: _muted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // OPCIONES DE COMUNIDAD
  // ============================================================

  Widget _buildCommunityOptions(bool mobile) {
    const List<Widget> cards = [
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
          const SizedBox(height: 15),
          cards[1],
          const SizedBox(height: 15),
          cards[2],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: cards[0],
        ),
        const SizedBox(width: 18),
        Expanded(
          child: cards[1],
        ),
        const SizedBox(width: 18),
        Expanded(
          child: cards[2],
        ),
      ],
    );
  }

  // ============================================================
  // ACTIVIDADES
  // ============================================================

  Widget _buildActivities(bool mobile) {
    const Widget first = _ActivityCard(
      day: '18',
      month: 'OCT',
      title: 'Taller de Bash',
      description: 'Automatización y scripting desde cero.',
      time: '5:00 PM',
      icon: Icons.code_rounded,
    );

    const Widget second = _ActivityCard(
      day: '24',
      month: 'OCT',
      title: 'Introducción a Docker',
      description: 'Contenedores y conceptos fundamentales.',
      time: '4:30 PM',
      icon: Icons.inventory_2_rounded,
    );

    if (mobile) {
      return Column(
        children: [
          first,
          const SizedBox(height: 14),
          second,
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: first,
        ),
        const SizedBox(width: 18),
        Expanded(
          child: second,
        ),
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

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AlumnoComunidadPage._muted,
          size: 15,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: AlumnoComunidadPage._muted,
            fontSize: 12,
          ),
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
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: AlumnoComunidadPage._card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AlumnoComunidadPage._border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: accent.withValues(
                alpha: 0.13,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: accent,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            description,
            style: const TextStyle(
              color: AlumnoComunidadPage._muted,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 17),
          TextButton.icon(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: accent,
              padding: EdgeInsets.zero,
            ),
            iconAlignment: IconAlignment.end,
            icon: const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
            ),
            label: Text(
              action,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AlumnoComunidadPage._card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AlumnoComunidadPage._border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 57,
            height: 62,
            decoration: BoxDecoration(
              color: AlumnoComunidadPage._orange.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  month,
                  style: const TextStyle(
                    color: AlumnoComunidadPage._orange,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: AlumnoComunidadPage._blue,
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: AlumnoComunidadPage._muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  time,
                  style: const TextStyle(
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