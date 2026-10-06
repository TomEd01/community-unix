import 'package:flutter/material.dart';

import 'alumno/alumno_comunidad_page.dart';
import 'alumno/alumno_cursos_page.dart';
import 'alumno/alumno_eventos_page.dart';
import 'alumno/alumno_inicio_page.dart';
import 'alumno/alumno_perfil_page.dart';

class AlumnoPage extends StatefulWidget {
  const AlumnoPage({super.key});

  @override
  State<AlumnoPage> createState() => _AlumnoPageState();
}

class _AlumnoPageState extends State<AlumnoPage> {
  static const Color _background = Color(0xFF031426);
  static const Color _sidebar = Color(0xFF061C31);
  static const Color _border = Color(0xFF174064);
  static const Color _orange = Color(0xFFFF8A24);
  static const Color _muted = Color(0xFF91A9BE);

  int _selectedIndex = 0;

  final List<_NavItem> _items = const [
    _NavItem(
      icon: Icons.home_rounded,
      label: 'Inicio',
    ),
    _NavItem(
      icon: Icons.menu_book_rounded,
      label: 'Cursos',
    ),
    _NavItem(
      icon: Icons.event_rounded,
      label: 'Eventos',
    ),
    _NavItem(
      icon: Icons.groups_rounded,
      label: 'Comunidad',
    ),
    _NavItem(
      icon: Icons.person_rounded,
      label: 'Mi perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool mobile = constraints.maxWidth < 760;

          if (mobile) {
            return _buildMobile();
          }

          return _buildDesktop();
        },
      ),
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktop() {
    return Row(
      children: [
        _buildSidebar(),
        Expanded(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: _buildCurrentPage(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobile() {
    return Column(
      children: [
        _buildMobileHeader(),
        Expanded(
          child: _buildCurrentPage(),
        ),
        _buildBottomNavigation(),
      ],
    );
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar() {
    return Container(
      width: 245,
      decoration: const BoxDecoration(
        color: _sidebar,
        border: Border(
          right: BorderSide(
            color: _border,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                22,
                25,
                22,
                30,
              ),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: _orange.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.terminal_rounded,
                      color: _orange,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comunidad',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'UNIX ITC',
                          style: TextStyle(
                            color: _orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                ),
                itemCount: _items.length,
                separatorBuilder: (_, _) {
                  return const SizedBox(height: 5);
                },
                itemBuilder: (context, index) {
                  return _buildSidebarItem(
                    index,
                    _items[index],
                  );
                },
              ),
            ),

            // Usuario
            Padding(
              padding: const EdgeInsets.all(15),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _border,
                  ),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFF123451),
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alumno',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Estudiante',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
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
  }

  Widget _buildSidebarItem(
    int index,
    _NavItem item,
  ) {
    final bool selected = _selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: selected
                ? _orange.withValues(alpha: 0.13)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: selected ? _orange : _muted,
              ),
              const SizedBox(width: 13),
              Text(
                item.label,
                style: TextStyle(
                  color: selected ? Colors.white : _muted,
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR DESKTOP
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
      ),
      decoration: const BoxDecoration(
        color: _sidebar,
        border: Border(
          bottom: BorderSide(
            color: _border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              height: 42,
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _border,
                ),
              ),
              child: const TextField(
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar cursos, eventos o comunidad...',
                  hintStyle: TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _muted,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: _muted,
            ),
          ),

          const SizedBox(width: 8),

          Container(
            width: 1,
            height: 28,
            color: _border,
          ),

          const SizedBox(width: 16),

          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF123451),
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 10),

          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alumno',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Comunidad UNIX',
                style: TextStyle(
                  color: _muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          const SizedBox(width: 5),

          PopupMenuButton<String>(
            tooltip: 'Opciones',
            color: _sidebar,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _muted,
            ),
            onSelected: (value) {
              if (value == 'logout') {
                Navigator.of(context).popUntil(
                  (route) => route.isFirst,
                );
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER MOBILE
  // ============================================================

  Widget _buildMobileHeader() {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: const BoxDecoration(
        color: _sidebar,
        border: Border(
          bottom: BorderSide(
            color: _border,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 37,
              height: 37,
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.terminal_rounded,
                color: _orange,
                size: 21,
              ),
            ),

            const SizedBox(width: 10),

            const Expanded(
              child: Text(
                'Comunidad UNIX',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            IconButton(
              tooltip: 'Buscar',
              onPressed: () {},
              icon: const Icon(
                Icons.search_rounded,
                color: _muted,
              ),
            ),

            IconButton(
              tooltip: 'Notificaciones',
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: _muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION MOBILE
  // ============================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: _border,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: _sidebar,
        selectedItemColor: _orange,
        unselectedItemColor: _muted,
        selectedFontSize: 10,
        unselectedFontSize: 9,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Cursos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_rounded),
            label: 'Eventos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_rounded),
            label: 'Comunidad',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CAMBIO DE PÁGINA
  // ============================================================

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const AlumnoInicioPage();

      case 1:
        return const AlumnoCursosPage();

      case 2:
        return const AlumnoEventosPage();

      case 3:
        return const AlumnoComunidadPage();

      case 4:
        return const AlumnoPerfilPage();

      default:
        return const AlumnoInicioPage();
    }
  }
}

// ================================================================
// MODELO DE NAVEGACIÓN
// ================================================================

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.label,
  });
}