import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:blobatar/flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'alumno/alumno_comunidad_page.dart';
import 'alumno/alumno_cursos_page.dart';
import 'alumno/alumno_eventos_page.dart';
import 'alumno/alumno_inicio_page.dart';
import 'alumno/alumno_perfil_page.dart';

import '../main.dart';

class AlumnoPage extends StatefulWidget {
  const AlumnoPage({super.key});

  @override
  State<AlumnoPage> createState() => _AlumnoPageState();
}

class _AlumnoPageState extends State<AlumnoPage> {
  static const String _perfilUrl =
      'http://127.0.0.1:8000/api/auth/perfil/me/';

  static const Color _background = Color(0xFF031426);
  static const Color _sidebar = Color(0xFF061C31);
  static const Color _border = Color(0xFF174064);
  static const Color _orange = Color(0xFFFF8A24);
  static const Color _muted = Color(0xFF91A9BE);

  int _selectedIndex = 0;

  String _nombre = 'Alumno';
  String _numeroControl = '';
  String? _profileError;

  bool _loadingProfile = false;
  bool _loggingOut = false;

  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.home_rounded, label: 'Inicio'),
    _NavItem(icon: Icons.menu_book_rounded, label: 'Cursos'),
    _NavItem(icon: Icons.event_rounded, label: 'Eventos'),
    _NavItem(icon: Icons.groups_rounded, label: 'Comunidad'),
    _NavItem(icon: Icons.person_rounded, label: 'Mi perfil'),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_loadingProfile || _loggingOut) return;

    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.trim().isEmpty) {
        throw Exception('Inicia sesión para cargar tus datos.');
      }

      final response = await http.get(
        Uri.parse(_perfilUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 401) {
        throw Exception(
          'Tu sesión venció. Cierra sesión y vuelve a ingresar.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'No se pudo cargar el perfil (${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map<String, dynamic>) {
        throw Exception('El servidor devolvió una respuesta inesperada.');
      }

      if (decoded['rol']?.toString().toLowerCase() != 'alumno') {
        throw Exception('Esta sesión no corresponde a un alumno.');
      }

      final nombre = decoded['nombre_completo']?.toString().trim() ?? '';
      final id = decoded['numero_control']?.toString().trim() ?? '';

      if (!mounted) return;

      setState(() {
        _nombre = nombre.isEmpty ? 'Alumno' : nombre;
        _numeroControl = id;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _profileError =
            error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  void _selectPage(int index) {
    final previousIndex = _selectedIndex;

    setState(() => _selectedIndex = index);

    // Actualiza el nombre del menú al salir del perfil.
    if (previousIndex == 4 || index == 4) {
      _loadProfile();
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('jwt_token');
      await prefs.remove('user_rol');

      if (prefs.getString('jwt_token') != null ||
          prefs.getString('user_rol') != null) {
        throw Exception('No se pudo limpiar la sesión guardada.');
      }

      try {
        await GoogleSignIn.instance.signOut();
      } catch (error) {
        debugPrint('Error al cerrar sesión de Google: $error');
      }

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AccessScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Widget _avatar(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: _numeroControl.isEmpty
          ? CircleAvatar(
              backgroundColor: const Color(0xFF123451),
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: size * 0.6,
              ),
            )
          : AnimatedBlobatar(
              key: ValueKey('avatar-$_numeroControl-$size'),
              name: _numeroControl,
              size: size,
              animation: BlobatarAnimation.always,
            ),
    );
  }

  Widget _userInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Alumno',
          style: TextStyle(color: _muted, fontSize: 10),
        ),
        if (_numeroControl.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            'ID: $_numeroControl',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6ED9AB),
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 760) {
            return Column(
              children: [
                _buildMobileHeader(),
                Expanded(child: _buildContent()),
                _buildBottomNavigation(),
              ],
            );
          }

          return Row(
            children: [
              _buildSidebar(),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        if (_loadingProfile)
          const LinearProgressIndicator(
            minHeight: 2,
            color: _orange,
            backgroundColor: _sidebar,
          ),
        if (_profileError != null)
          Container(
            width: double.infinity,
            color: _sidebar,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: _orange,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _profileError!,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loadingProfile ? null : _loadProfile,
                  child: const Text(
                    'Reintentar',
                    style: TextStyle(color: _orange),
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: _buildCurrentPage()),
      ],
    );
  }

  // ============================================================
  // MENÚ LATERAL
  // ============================================================

  Widget _buildSidebar() {
    return Container(
      width: 245,
      decoration: const BoxDecoration(
        color: _sidebar,
        border: Border(right: BorderSide(color: _border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 25, 22, 30),
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
                padding: const EdgeInsets.symmetric(horizontal: 13),
                itemCount: _items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 5),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final selected = _selectedIndex == index;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectPage(index),
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
                                color: selected
                                    ? Colors.white
                                    : _muted,
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Material(
                color: _background,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => _selectPage(4),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        _avatar(42),
                        const SizedBox(width: 10),
                        Expanded(child: _userInfo()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BARRA SUPERIOR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: _sidebar,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar cursos, eventos o comunidad...',
                  hintStyle: TextStyle(color: _muted, fontSize: 12),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _muted,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: _muted,
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 28, color: _border),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => _selectPage(4),
            borderRadius: BorderRadius.circular(22),
            child: _avatar(40),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 130, child: _userInfo()),
          _buildAccountMenu(),
        ],
      ),
    );
  }

  Widget _buildAccountMenu() {
    return PopupMenuButton<String>(
      enabled: !_loggingOut,
      tooltip: 'Opciones de cuenta',
      color: _sidebar,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: _muted,
      ),
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            _selectPage(4);
            break;
          case 'refresh':
            await _loadProfile();
            break;
          case 'logout':
            await _logout();
            break;
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem<String>(
          value: 'profile',
          child: Text(
            'Mi perfil',
            style: TextStyle(color: Colors.white),
          ),
        ),
        PopupMenuItem<String>(
          value: 'refresh',
          child: Text(
            'Actualizar datos',
            style: TextStyle(color: Colors.white),
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.white, size: 19),
              SizedBox(width: 10),
              Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TELÉFONO
  // ============================================================

  Widget _buildMobileHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: _sidebar,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.terminal_rounded,
                color: _orange,
                size: 27,
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
                tooltip: 'Notificaciones',
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: _muted,
                ),
              ),
              Tooltip(
                message: _nombre,
                child: InkWell(
                  onTap: () => _selectPage(4),
                  borderRadius: BorderRadius.circular(20),
                  child: _avatar(36),
                ),
              ),
              _buildAccountMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
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
        onTap: _selectPage,
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

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return AlumnoInicioPage(nombre: _nombre);
      case 1:
        return const AlumnoCursosPage();
      case 2:
        return const AlumnoEventosPage();
      case 3:
        return const AlumnoComunidadPage();
      case 4:
        return const AlumnoPerfilPage();
      default:
        return AlumnoInicioPage(nombre: _nombre);
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.label,
  });
}