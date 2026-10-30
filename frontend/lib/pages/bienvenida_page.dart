import '../theme/unix_theme.dart';
import 'package:flutter/material.dart';

class BienvenidaPage extends StatelessWidget {
  const BienvenidaPage({super.key, required this.onRegister});

  final VoidCallback onRegister;

  static Color get cream => UnixColors.background;
  static Color get paper => UnixColors.card;
  static Color get navy => UnixColors.text;
  static Color get muted => UnixColors.muted;
  static Color get line => UnixColors.border;

  static final Map<String, GlobalKey> _sectionKeys = {
    'inicio': GlobalKey(),
    'eventos': GlobalKey(),
    'comunidad': GlobalKey(),
    'acerca': GlobalKey(),
  };

  void _scrollToSection(String section) {
    final targetContext = _sectionKeys[section]?.currentContext;
    if (targetContext == null) return;

    Scrollable.ensureVisible(
      targetContext,
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              _hero(),
              _benefits(),
              _about(context),
              _audience(context),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return LayoutBuilder(
      builder: (context, constraints) {
        UnixTheme.watch(context);
        final mobile = constraints.maxWidth < 950;

        return Container(
          color: paper,
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 14 : 30,
            vertical: 10,
          ),
          child: Row(
            children: [
              Icon(Icons.groups_rounded, color: navy, size: 32),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Comunidad\nUNIX ITC',
                  style: TextStyle(
                    color: navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              if (!mobile) ...[
                _navItem('Inicio', 'inicio'),
                _navItem('Eventos', 'eventos'),
                _navItem('Comunidad', 'comunidad'),
                _navItem('Acerca de', 'acerca'),
                SizedBox(width: 8),
              ] else
                PopupMenuButton<String>(
                  tooltip: 'Abrir menú',
                  icon: Icon(Icons.menu_rounded, color: navy),
                  onSelected: _scrollToSection,
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'inicio', child: Text('Inicio')),
                    PopupMenuItem(value: 'eventos', child: Text('Eventos')),
                    PopupMenuItem(value: 'comunidad', child: Text('Comunidad')),
                    PopupMenuItem(value: 'acerca', child: Text('Acerca de')),
                  ],
                ),
              SizedBox(width: 6),
              UnixThemeToggle(compact: mobile),
              SizedBox(width: 8),
              FilledButton(
                onPressed: onRegister,
                style: FilledButton.styleFrom(
                  backgroundColor: UnixColors.orange,
                  foregroundColor: UnixColors.onOrange,
                  padding: EdgeInsets.symmetric(
                    horizontal: mobile ? 10 : 17,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: Text(
                  mobile ? 'Registrarse' : 'Registrarse a la comunidad',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _navItem(String label, String section) {
    return TextButton(
      onPressed: () => _scrollToSection(section),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: TextStyle(color: navy, fontSize: 12)),
    );
  }

  Widget _hero() {
    return Container(
      key: _sectionKeys['inicio'],
      color: paper,
      padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          UnixTheme.watch(context);
          final mobile = constraints.maxWidth < 800;
          final smallPhone = constraints.maxWidth < 380;

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'APRENDE  ·  PARTICIPA  ·  CONECTA',
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Bienvenido a\nComunidad UNIX ITC',
                style: TextStyle(
                  color: navy,
                  fontSize: smallPhone
                      ? 29
                      : mobile
                      ? 34
                      : 42,
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Un espacio para estudiantes, instructores y '
                'entusiastas de la tecnología. Participa en eventos, '
                'desarrolla tus habilidades y forma parte de una '
                'comunidad activa.',
                style: TextStyle(
                  color: UnixColors.muted,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              SizedBox(height: 20),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  FilledButton.icon(
                    onPressed: onRegister,
                    icon: Icon(Icons.arrow_forward_rounded, size: 17),
                    label: Text(
                      'Registrarse a la comunidad',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: UnixColors.orange,
                      foregroundColor: UnixColors.onOrange,
                      padding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _scrollToSection('acerca'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: navy,
                      side: BorderSide(color: UnixColors.border),
                      padding: EdgeInsets.symmetric(
                        horizontal: 17,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: Text('Conoce más', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          );

          final image = ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: double.infinity,
              height: mobile ? 225 : 340,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1562774053-701939374585'
                    '?auto=format&fit=crop&w=1200&q=85',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFCBD4D6),
                              Color(0xFF8F9DA0),
                              Color(0xFF435766),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.account_balance_rounded,
                            size: 80,
                            color: UnixColors.text.withValues(alpha: 0.7),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: paper.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Construyendo',
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Una comunidad de conocimiento',
                            style: TextStyle(
                              color: navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1250),
              child: mobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [copy, SizedBox(height: 22), image],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: EdgeInsets.only(right: 28),
                            child: copy,
                          ),
                        ),
                        Expanded(flex: 5, child: image),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _benefits() {
    final items = [
      _benefit(
        Icons.event_outlined,
        'Eventos',
        'Talleres, conferencias y más.',
      ),
      _benefit(
        Icons.groups_outlined,
        'Comunidad',
        'Conecta con otros miembros.',
      ),
      _benefit(
        Icons.trending_up_rounded,
        'Desarrollo',
        'Fortalece tus habilidades en tecnología.',
      ),
    ];

    return Container(
      color: paper,
      padding: EdgeInsets.fromLTRB(18, 0, 18, 22),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              UnixTheme.watch(context);
              if (constraints.maxWidth < 650) {
                return Column(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: item,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items
                    .map(
                      (item) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 7),
                          child: item,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _benefit(IconData icon, String title, String description) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: UnixColors.selected,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: navy, size: 22),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(color: muted, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _about(BuildContext context) {
    return Container(
      key: _sectionKeys['acerca'],
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(12, 14, 12, 8),
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 17 : 22),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          UnixTheme.watch(context);
          final mobile = constraints.maxWidth < 700;

          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Qué es Comunidad UNIX ITC?',
                style: TextStyle(
                  color: navy,
                  fontSize: constraints.maxWidth < 380 ? 21 : 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Una comunidad creada para impulsar el aprendizaje, '
                'la colaboración y la participación en actividades '
                'tecnológicas dentro del ITC.',
                style: TextStyle(
                  color: UnixColors.muted,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              SizedBox(height: 15),
              OutlinedButton(
                onPressed: onRegister,
                style: OutlinedButton.styleFrom(
                  foregroundColor: navy,
                  side: BorderSide(color: navy),
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                ),
                child: Text('Únete a la comunidad'),
              ),
            ],
          );

          final image = ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: mobile ? 190 : 220,
              width: double.infinity,
              child: Image.network(
                'https://images.unsplash.com/photo-1498050108023-c5249f4df085'
                '?auto=format&fit=crop&w=1000&q=85',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return ColoredBox(
                    color: Color(0xFFE5DED6),
                    child: Center(
                      child: Icon(
                        Icons.computer_rounded,
                        size: 70,
                        color: navy,
                      ),
                    ),
                  );
                },
              ),
            ),
          );

          return mobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [text, SizedBox(height: 18), image],
                )
              : Row(
                  children: [
                    Expanded(child: text),
                    SizedBox(width: 24),
                    Expanded(child: image),
                  ],
                );
        },
      ),
    );
  }

  Widget _audience(BuildContext context) {
    return Container(
      key: _sectionKeys['comunidad'],
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 17 : 22),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿A quién está dirigida?',
            style: TextStyle(
              color: navy,
              fontSize: MediaQuery.sizeOf(context).width < 380 ? 21 : 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              UnixTheme.watch(context);
              final items = [
                _audienceCard(
                  Icons.school_rounded,
                  'Estudiantes',
                  'Participa en eventos, aprende y desarrolla nuevas habilidades.',
                ),
                _audienceCard(
                  Icons.person_rounded,
                  'Instructores',
                  'Comparte conocimientos y crea actividades para la comunidad.',
                ),
                _audienceCard(
                  Icons.groups_rounded,
                  'Externos',
                  'Conecta con personas interesadas en la tecnología.',
                ),
              ];

              if (constraints.maxWidth < 650) {
                return Column(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: item,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items.map((item) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: item,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _audienceCard(IconData icon, String title, String description) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: navy, size: 34),
          SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      key: _sectionKeys['eventos'],
      width: double.infinity,
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 23),
      color: Color(0xFF061C31),
      child: Column(
        children: [
          Icon(Icons.groups_rounded, color: Colors.white, size: 32),
          SizedBox(height: 8),
          Text(
            'Comunidad UNIX ITC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Aprende · Participa · Conecta',
            style: TextStyle(color: Color(0xFFD8DDE1), fontSize: 12),
          ),
          SizedBox(height: 9),
          Text(
            'Una comunidad para aprender y crecer en tecnología.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFD8DDE1), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
