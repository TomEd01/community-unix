import 'package:flutter/material.dart';

class AlumnoCursosPage extends StatelessWidget {
  const AlumnoCursosPage({super.key});

  static const Color _bg = Color(0xFF031426);
  static const Color _card = Color(0xFF0A2947);
  static const Color _cardSoft = Color(0xFF0D3153);
  static const Color _border = Color(0xFF174064);
  static const Color _orange = Color(0xFFFF8A24);
  static const Color _blue = Color(0xFF2796FF);
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
              mobile ? 18 : 28,
              mobile ? 16 : 28,
              50,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1250),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(mobile),
                    const SizedBox(height: 34),

                    const Text(
                      'Rutas por nivel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Elige una ruta y avanza a tu propio ritmo.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildLevelSection(mobile),

                    const SizedBox(height: 40),

                    const Text(
                      'Continúa aprendiendo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Cursos recomendados para ti',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildCoursesSection(mobile),
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
  // HERO
  // ============================================================

  Widget _buildHero(bool mobile) {
    final Widget text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'TU RUTA DE APRENDIZAJE',
            style: TextStyle(
              color: _orange,
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(height: 18),

        Text(
          mobile
              ? 'Tu siguiente paso\nempieza aquí'
              : 'Tu siguiente paso empieza aquí',
          style: TextStyle(
            color: Colors.white,
            fontSize: mobile ? 31 : 38,
            height: 1.08,
            fontWeight: FontWeight.w900,
          ),
        ),

        ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 650),
  child: const Text(
    'Aprende Linux paso a paso. Elige el nivel que mejor '
    'se adapte a ti y continúa desarrollando tus habilidades.',
    style: TextStyle(
      color: _muted,
      fontSize: 14,
      height: 1.6,
    ),
  ),
),

        const SizedBox(height: 24),

        FilledButton.icon(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 17,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(
            Icons.play_arrow_rounded,
            size: 21,
          ),
          label: const Text(
            'Continuar aprendiendo',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    final Widget illustration = Container(
      width: mobile ? double.infinity : 210,
      height: mobile ? 150 : 190,
      decoration: BoxDecoration(
        color: _cardSoft,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: _border,
        ),
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.school_rounded,
            color: _orange,
            size: 82,
          ),
          Positioned(
            top: 27,
            right: 30,
            child: Icon(
              Icons.auto_awesome,
              color: Color(0xFFFFB067),
              size: 25,
            ),
          ),
          Positioned(
            bottom: 25,
            left: 30,
            child: Icon(
              Icons.code_rounded,
              color: _blue,
              size: 28,
            ),
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        mobile ? 23 : 36,
      ),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _border,
        ),
      ),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                const SizedBox(height: 27),
                illustration,
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: text,
                ),
                const SizedBox(width: 35),
                illustration,
              ],
            ),
    );
  }

  // ============================================================
  // RUTAS POR NIVEL
  // ============================================================

  Widget _buildLevelSection(bool mobile) {
    const List<Widget> cards = [
      _LevelCard(
        icon: Icons.rocket_launch_rounded,
        level: 'Principiante',
        title: 'Comienza desde cero',
        description:
            'Aprende los fundamentos de Linux, la terminal y los comandos esenciales.',
        progress: 0.65,
        courses: '8 cursos',
        accent: Color(0xFF35D59A),
      ),
      _LevelCard(
        icon: Icons.terminal_rounded,
        level: 'Intermedio',
        title: 'Lleva Linux más lejos',
        description:
            'Profundiza en administración, redes, scripting y herramientas del sistema.',
        progress: 0.30,
        courses: '10 cursos',
        accent: Color(0xFF2796FF),
      ),
      _LevelCard(
        icon: Icons.security_rounded,
        level: 'Avanzado',
        title: 'Domina el ecosistema',
        description:
            'Explora servidores, seguridad, automatización y conceptos avanzados.',
        progress: 0.10,
        courses: '12 cursos',
        accent: Color(0xFFA855F7),
      ),
    ];

    if (mobile) {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 16),
          cards[1],
          const SizedBox(height: 16),
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
  // CONTINUAR APRENDIENDO
  // ============================================================

  Widget _buildCoursesSection(bool mobile) {
    const List<Widget> cards = [
      _CourseCard(
        icon: Icons.terminal_rounded,
        title: 'Fundamentos de Linux',
        category: 'Principiante',
        description:
            'Conoce Linux, su estructura y los comandos que utilizarás todos los días.',
        progress: 0.72,
        modules: '9 de 12 módulos',
      ),
      _CourseCard(
        icon: Icons.code_rounded,
        title: 'Bash y Shell Scripting',
        category: 'Intermedio',
        description:
            'Automatiza tareas y crea scripts para trabajar de manera más eficiente.',
        progress: 0.38,
        modules: '4 de 11 módulos',
      ),
      _CourseCard(
        icon: Icons.lan_rounded,
        title: 'Redes en Linux',
        category: 'Intermedio',
        description:
            'Aprende configuración, diagnóstico y conceptos esenciales de redes.',
        progress: 0.15,
        modules: '2 de 10 módulos',
      ),
    ];

    if (mobile) {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 14),
          cards[1],
          const SizedBox(height: 14),
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
}

// ================================================================
// TARJETA DE NIVEL
// ================================================================

class _LevelCard extends StatelessWidget {
  final IconData icon;
  final String level;
  final String title;
  final String description;
  final double progress;
  final String courses;
  final Color accent;

  const _LevelCard({
    required this.icon,
    required this.level,
    required this.title,
    required this.description,
    required this.progress,
    required this.courses,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AlumnoCursosPage._card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AlumnoCursosPage._border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: accent,
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  level,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            description,
            style: const TextStyle(
              color: AlumnoCursosPage._muted,
              height: 1.5,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Text(
                courses,
                style: const TextStyle(
                  color: AlumnoCursosPage._muted,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress,
              backgroundColor: const Color(0xFF123451),
              valueColor: AlwaysStoppedAnimation<Color>(
                accent,
              ),
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(
                  color: AlumnoCursosPage._border,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'Ver ruta',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// TARJETA DE CURSO
// ================================================================

class _CourseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String category;
  final String description;
  final double progress;
  final String modules;

  const _CourseCard({
    required this.icon,
    required this.title,
    required this.category,
    required this.description,
    required this.progress,
    required this.modules,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AlumnoCursosPage._card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AlumnoCursosPage._border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AlumnoCursosPage._orange.withValues(
                alpha: 0.13,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AlumnoCursosPage._orange,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            category.toUpperCase(),
            style: const TextStyle(
              color: AlumnoCursosPage._orange,
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 7),

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
              color: AlumnoCursosPage._muted,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Text(
                modules,
                style: const TextStyle(
                  color: AlumnoCursosPage._muted,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: AlumnoCursosPage._orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFF123451),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AlumnoCursosPage._orange,
              ),
            ),
          ),

          const SizedBox(height: 18),

          TextButton.icon(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AlumnoCursosPage._orange,
              padding: EdgeInsets.zero,
            ),
            iconAlignment: IconAlignment.end,
            icon: const Icon(
              Icons.arrow_forward_rounded,
              size: 17,
            ),
            label: const Text(
              'Continuar curso',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}