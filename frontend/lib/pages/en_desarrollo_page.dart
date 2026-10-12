import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF080F22);
  static const backgroundMiddle = Color(0xFF101535);
  static const backgroundEnd = Color(0xFF171B48);

  static const surface = Color(0xFF101A34);
  static const surfaceLight = Color(0xFF182545);
  static const active = Color(0xFF27345E);
  static const border = Color(0xFF293A63);

  static const text = Color(0xFFF4F5FF);
  static const textSoft = Color(0xFF9BA7C2);
  static const textMuted = Color(0xFF75819E);

  static const orange = Color(0xFFFF7417);
  static const purple = Color(0xFFA755E8);
}

class EnDesarrolloPage extends StatefulWidget {
  const EnDesarrolloPage({super.key});

  @override
  State<EnDesarrolloPage> createState() => _EnDesarrolloPageState();
}

class _EnDesarrolloPageState extends State<EnDesarrolloPage> {
  String seleccionada = 'Cursos';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final mobile = screenWidth < 600;
    final tablet = screenWidth >= 600 && screenWidth < 950;

    final horizontalPadding = mobile
        ? 12.0
        : tablet
        ? 20.0
        : 28.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.backgroundMiddle,
              AppColors.backgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      SizedBox(height: mobile ? 12 : 20),

                      _header(mobile: mobile, tablet: tablet),

                      _content(mobile: mobile, tablet: tablet),

                      _footer(mobile: mobile, tablet: tablet),

                      SizedBox(height: mobile ? 14 : 28),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header({required bool mobile, required bool tablet}) {
    if (mobile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: _panelDecoration(radius: 16),
        child: Column(
          children: [
            const Row(
              children: [
                _Logo(size: 42),
                SizedBox(width: 11),
                Expanded(child: _BrandTitle()),
              ],
            ),

            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              height: 1,
              color: AppColors.border,
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _mobileMenuItem('Cursos', Icons.menu_book_outlined),
                ),
                Expanded(
                  child: _mobileMenuItem(
                    'Calendario',
                    Icons.calendar_month_outlined,
                  ),
                ),
                Expanded(
                  child: _mobileMenuItem(
                    'Notificaciones',
                    Icons.notifications_none_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(minHeight: tablet ? 105 : 120),
      padding: EdgeInsets.symmetric(horizontal: tablet ? 22 : 28, vertical: 20),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [_Logo(), SizedBox(width: 12), _BrandTitle()],
          ),

          const Spacer(),

          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              _menuItem('Cursos', Icons.menu_book_outlined),
              _menuItem('Calendario', Icons.calendar_month_outlined),
              _menuItem('Notificaciones', Icons.notifications_none_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuItem(String name, IconData icon) {
    final selected = seleccionada == name;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          seleccionada = name;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.active : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0x66FF7417) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.orange : AppColors.textSoft,
            ),
            const SizedBox(width: 7),
            Text(
              name,
              style: TextStyle(
                color: selected ? AppColors.text : AppColors.textSoft,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileMenuItem(String name, IconData icon) {
    final selected = seleccionada == name;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          seleccionada = name;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.active : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0x66FF7417) : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.orange : AppColors.textSoft,
            ),
            const SizedBox(height: 5),
            Text(
              name == 'Notificaciones' ? 'Avisos' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: selected ? AppColors.text : AppColors.textSoft,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CONTENIDO CENTRAL
  // ============================================================

  Widget _content({required bool mobile, required bool tablet}) {
    final iconSize = mobile
        ? 70.0
        : tablet
        ? 80.0
        : 88.0;

    final titleSize = mobile
        ? 34.0
        : tablet
        ? 42.0
        : 48.0;

    final subtitleSize = mobile
        ? 16.0
        : tablet
        ? 18.0
        : 20.0;

    final descriptionSize = mobile
        ? 14.0
        : tablet
        ? 15.0
        : 16.0;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: mobile ? 390 : 430),
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 12 : 24,
        vertical: mobile ? 48 : 65,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x33FF7417), Color(0x33A755E8)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x55FF7417)),
              boxShadow: const [
                BoxShadow(color: Color(0x33FF7417), blurRadius: 30),
              ],
            ),
            child: Icon(
              Icons.construction_rounded,
              color: AppColors.orange,
              size: mobile ? 34 : 42,
            ),
          ),

          SizedBox(height: mobile ? 22 : 28),

          Text(
            'En desarrollo...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),

          SizedBox(height: mobile ? 12 : 14),

          Text(
            'La sección $seleccionada todavía está en construcción.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSoft,
              fontSize: subtitleSize,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 8),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Text(
              'Estamos trabajando para ofrecerte una mejor experiencia de aprendizaje.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: descriptionSize,
                height: 1.5,
              ),
            ),
          ),

          SizedBox(height: mobile ? 24 : 30),

          Container(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 15 : 18,
              vertical: mobile ? 9 : 11,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.orange,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Próximamente',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _footer({required bool mobile, required bool tablet}) {
    if (mobile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _panelDecoration(radius: 16),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FooterBrand(),

            SizedBox(height: 28),

            Divider(color: AppColors.border),

            SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FooterColumn(
                    title: 'Comunidad',
                    items: ['Cursos', 'Eventos', 'Constancias', 'Colaboración'],
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: _FooterColumn(
                    title: 'Explorar',
                    items: ['Linux', 'Programación', 'Redes', 'Ciberseguridad'],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            Divider(color: AppColors.border),

            SizedBox(height: 20),

            _FooterColumn(
              title: 'Recursos',
              items: ['Blog', 'Buenas prácticas', 'Soporte', 'Desarrolladores'],
            ),
          ],
        ),
      );
    }

    if (tablet) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: _panelDecoration(),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FooterBrand(),

            SizedBox(height: 30),

            Divider(color: AppColors.border),

            SizedBox(height: 26),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FooterColumn(
                    title: 'Comunidad',
                    items: ['Cursos', 'Eventos', 'Constancias', 'Colaboración'],
                  ),
                ),
                Expanded(
                  child: _FooterColumn(
                    title: 'Explorar',
                    items: ['Linux', 'Programación', 'Redes', 'Ciberseguridad'],
                  ),
                ),
                Expanded(
                  child: _FooterColumn(
                    title: 'Recursos',
                    items: [
                      'Blog',
                      'Buenas prácticas',
                      'Soporte',
                      'Desarrolladores',
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: _panelDecoration(),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _FooterBrand()),

          SizedBox(width: 35),

          Expanded(
            child: _FooterColumn(
              title: 'Comunidad',
              items: ['Cursos', 'Eventos', 'Constancias', 'Colaboración'],
            ),
          ),

          Expanded(
            child: _FooterColumn(
              title: 'Explorar',
              items: ['Linux', 'Programación', 'Redes', 'Ciberseguridad'],
            ),
          ),

          Expanded(
            child: _FooterColumn(
              title: 'Recursos',
              items: ['Blog', 'Buenas prácticas', 'Soporte', 'Desarrolladores'],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DECORACIÓN
  // ============================================================

  BoxDecoration _panelDecoration({double radius = 18}) {
    return BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    );
  }
}

// ============================================================
// LOGO
// ============================================================

class _Logo extends StatelessWidget {
  const _Logo({this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.orange, AppColors.purple],
        ),
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      child: Icon(
        Icons.terminal_rounded,
        color: Colors.white,
        size: size * 0.58,
      ),
    );
  }
}

// ============================================================
// NOMBRE DE LA COMUNIDAD
// ============================================================

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMUNIDAD',
          style: TextStyle(
            color: AppColors.orange,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Unix ITC',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FOOTER - MARCA
// ============================================================

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.terminal_rounded, color: AppColors.orange, size: 22),
            SizedBox(width: 8),
            Text(
              'Unix ITC',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          'Aprende, comparte y crece con nuestra comunidad.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FOOTER - COLUMNAS
// ============================================================

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 16),

        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Text(
              item,
              style: const TextStyle(
                color: AppColors.textSoft,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
