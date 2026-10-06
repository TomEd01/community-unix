import 'package:flutter/material.dart';

class AlumnoInicioPage extends StatelessWidget {
  const AlumnoInicioPage({super.key});

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
                    _buildWelcome(mobile),
                    const SizedBox(height: 28),
                    _buildMainSection(mobile),
                    const SizedBox(height: 34),
                    _buildCoursesHeader(),
                    const SizedBox(height: 18),
                    _buildCourses(mobile),
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
  // BIENVENIDA
  // ============================================================

  Widget _buildWelcome(bool mobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¡Hola, Alumno! 👋',
          style: TextStyle(
            color: Colors.white,
            fontSize: mobile ? 28 : 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Continúa aprendiendo y descubre todo lo que la comunidad tiene para ti.',
          style: TextStyle(
            color: _muted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECCIÓN PRINCIPAL
  // ============================================================

  Widget _buildMainSection(bool mobile) {
    final currentCourse = _buildCurrentCourse();
    final side = Column(
      children: [
        _buildProgressCard(),
        const SizedBox(height: 18),
        _buildEventCard(),
      ],
    );

    if (mobile) {
      return Column(
        children: [
          currentCourse,
          const SizedBox(height: 18),
          side,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: currentCourse,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: side,
        ),
      ],
    );
  }

  // ============================================================
  // CURSO ACTUAL
  // ============================================================

  Widget _buildCurrentCourse() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  'CURSO ACTUAL',
                  style: TextStyle(
                    color: _orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.terminal_rounded,
                color: _orange,
                size: 30,
              ),
            ],
          ),

          const SizedBox(height: 28),

          const Text(
            'Fundamentos de Linux',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Domina los conceptos esenciales de Linux y aprende a utilizar '
            'la terminal con confianza.',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 30),

          const Row(
            children: [
              Text(
                'Progreso',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                ),
              ),
              Spacer(),
              Text(
                '72%',
                style: TextStyle(
                  color: _orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.72,
              minHeight: 7,
              backgroundColor: Color(0xFF123451),
              valueColor: AlwaysStoppedAnimation<Color>(_orange),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            '9 de 12 módulos completados',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 25),

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
              Icons.play_arrow_rounded,
              size: 20,
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

  // ============================================================
  // PROGRESO GENERAL
  // ============================================================

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: _blue,
                size: 23,
              ),
              SizedBox(width: 10),
              Text(
                'Tu progreso',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                value: '3',
                label: 'Cursos',
              ),
              _StatItem(
                value: '18',
                label: 'Módulos',
              ),
              _StatItem(
                value: '12h',
                label: 'Aprendizaje',
              ),
            ],
          ),

          const SizedBox(height: 23),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.58,
              minHeight: 6,
              backgroundColor: Color(0xFF123451),
              valueColor: AlwaysStoppedAnimation<Color>(_blue),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            '58% de tu ruta completada',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRÓXIMO EVENTO
  // ============================================================

  Widget _buildEventCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.event_available_rounded,
                color: _green,
                size: 23,
              ),
              SizedBox(width: 10),
              Text(
                'Próximo evento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            'Linux Install Fest',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          const Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: _muted,
                size: 14,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Viernes · 4:00 PM',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          const Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: _muted,
                size: 15,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Laboratorio de Sistemas',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: _green,
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'Ver evento →',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CURSOS RECOMENDADOS
  // ============================================================

  Widget _buildCoursesHeader() {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'Continúa aprendiendo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          'Ver todos',
          style: TextStyle(
            color: _orange,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCourses(bool mobile) {
    const cards = [
      _HomeCourseCard(
        icon: Icons.code_rounded,
        title: 'Bash y Shell Scripting',
        level: 'Intermedio',
        progress: 0.38,
        modules: '4 de 11 módulos',
        accent: _blue,
      ),
      _HomeCourseCard(
        icon: Icons.lan_rounded,
        title: 'Redes en Linux',
        level: 'Intermedio',
        progress: 0.15,
        modules: '2 de 10 módulos',
        accent: _green,
      ),
      _HomeCourseCard(
        icon: Icons.security_rounded,
        title: 'Seguridad en Linux',
        level: 'Avanzado',
        progress: 0.10,
        modules: '1 de 10 módulos',
        accent: Color(0xFFA855F7),
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
        Expanded(child: cards[0]),
        const SizedBox(width: 18),
        Expanded(child: cards[1]),
        const SizedBox(width: 18),
        Expanded(child: cards[2]),
      ],
    );
  }
}

// ================================================================
// ESTADÍSTICA
// ================================================================

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AlumnoInicioPage._muted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// TARJETA CURSO
// ================================================================

class _HomeCourseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String level;
  final double progress;
  final String modules;
  final Color accent;

  const _HomeCourseCard({
    required this.icon,
    required this.title,
    required this.level,
    required this.progress,
    required this.modules,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AlumnoInicioPage._card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AlumnoInicioPage._border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: accent,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            level.toUpperCase(),
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Text(
                modules,
                style: const TextStyle(
                  color: AlumnoInicioPage._muted,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: accent,
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
              valueColor: AlwaysStoppedAnimation<Color>(
                accent,
              ),
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
              size: 17,
            ),
            label: const Text(
              'Continuar',
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