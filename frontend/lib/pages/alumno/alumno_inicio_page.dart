import '../../theme/unix_theme.dart';
import 'package:flutter/material.dart';
import 'alumno_vinculo_profesor.dart';

class AlumnoInicioPage extends StatelessWidget {
  const AlumnoInicioPage({super.key, this.nombre = '', this.search});

  final String nombre;
  final Widget? search;

  String get primerNombre {
    final texto = nombre.trim();

    if (texto.isEmpty || texto == 'Alumno') return '';

    return texto.split(RegExp(r'\s+')).first;
  }

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
                    _buildWelcome(mobile),
                    if (search != null) ...[
                      const SizedBox(height: 20),
                      search!,
                    ],
                    SizedBox(height: 24),
                    AlumnoVinculoProfesor(),
                    SizedBox(height: 28),
                    _buildMainSection(mobile),
                    SizedBox(height: 34),
                    _buildCoursesHeader(),
                    SizedBox(height: 18),
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
          primerNombre.isEmpty ? '¡Hola!' : '¡Hola, $primerNombre!',
          style: TextStyle(
            color: UnixColors.text,
            fontSize: mobile ? 28 : 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Continúa aprendiendo y descubre todo lo que la comunidad tiene para ti.',
          style: TextStyle(color: _muted, fontSize: 14, height: 1.5),
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
      children: [_buildProgressCard(), SizedBox(height: 18), _buildEventCard()],
    );

    if (mobile) {
      return Column(children: [currentCourse, SizedBox(height: 18), side]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: currentCourse),
        SizedBox(width: 20),
        Expanded(child: side),
      ],
    );
  }

  // ============================================================
  // CURSO ACTUAL
  // ============================================================

  Widget _buildCurrentCourse() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'CURSO ACTUAL',
                  style: TextStyle(
                    color: _orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Spacer(),
              Icon(Icons.terminal_rounded, color: _orange, size: 30),
            ],
          ),

          SizedBox(height: 28),

          Text(
            'Fundamentos de Linux',
            style: TextStyle(
              color: UnixColors.text,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),

          SizedBox(height: 10),

          Text(
            'Domina los conceptos esenciales de Linux y aprende a utilizar '
            'la terminal con confianza.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.55),
          ),

          SizedBox(height: 30),

          Row(
            children: [
              Text('Progreso', style: TextStyle(color: _muted, fontSize: 12)),
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

          SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.72,
              minHeight: 7,
              backgroundColor: UnixColors.adapt(Color(0xFF123451)),
              valueColor: AlwaysStoppedAnimation<Color>(_orange),
            ),
          ),

          SizedBox(height: 12),

          Text(
            '9 de 12 módulos completados',
            style: TextStyle(color: _muted, fontSize: 11),
          ),

          SizedBox(height: 25),

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
            icon: Icon(Icons.play_arrow_rounded, size: 20),
            label: Text(
              'Continuar curso',
              style: TextStyle(fontWeight: FontWeight.w700),
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
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: _blue, size: 23),
              SizedBox(width: 10),
              Text(
                'Tu progreso',
                style: TextStyle(
                  color: UnixColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          SizedBox(height: 22),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(value: '3', label: 'Cursos'),
              _StatItem(value: '18', label: 'Módulos'),
              _StatItem(value: '12h', label: 'Aprendizaje'),
            ],
          ),

          SizedBox(height: 23),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.58,
              minHeight: 6,
              backgroundColor: UnixColors.adapt(Color(0xFF123451)),
              valueColor: AlwaysStoppedAnimation<Color>(_blue),
            ),
          ),

          SizedBox(height: 10),

          Text(
            '58% de tu ruta completada',
            style: TextStyle(color: _muted, fontSize: 11),
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
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_rounded, color: _green, size: 23),
              SizedBox(width: 10),
              Text(
                'Próximo evento',
                style: TextStyle(
                  color: UnixColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          Text(
            'Linux Install Fest',
            style: TextStyle(
              color: UnixColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          SizedBox(height: 8),

          Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: _muted, size: 14),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Viernes · 4:00 PM',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ),
            ],
          ),

          SizedBox(height: 7),

          Row(
            children: [
              Icon(Icons.location_on_outlined, color: _muted, size: 15),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Laboratorio de Sistemas',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ),
            ],
          ),

          SizedBox(height: 18),

          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: _green,
              padding: EdgeInsets.zero,
            ),
            child: Text(
              'Ver evento →',
              style: TextStyle(fontWeight: FontWeight.w700),
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
    return Row(
      children: [
        Expanded(
          child: Text(
            'Continúa aprendiendo',
            style: TextStyle(
              color: UnixColors.text,
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
    final cards = [
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
          SizedBox(height: 14),
          cards[1],
          SizedBox(height: 14),
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
}

// ================================================================
// ESTADÍSTICA
// ================================================================

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: UnixColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: AlumnoInicioPage._muted, fontSize: 10),
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
    UnixTheme.watch(context);
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AlumnoInicioPage._card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AlumnoInicioPage._border),
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
            child: Icon(icon, color: accent),
          ),

          SizedBox(height: 18),

          Text(
            level.toUpperCase(),
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),

          SizedBox(height: 7),

          Text(
            title,
            style: TextStyle(
              color: UnixColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          SizedBox(height: 20),

          Row(
            children: [
              Text(
                modules,
                style: TextStyle(color: AlumnoInicioPage._muted, fontSize: 11),
              ),
              Spacer(),
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

          SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: UnixColors.adapt(Color(0xFF123451)),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
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
            icon: Icon(Icons.arrow_forward_rounded, size: 17),
            label: Text(
              'Continuar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
