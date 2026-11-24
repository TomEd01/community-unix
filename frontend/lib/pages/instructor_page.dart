import '../theme/unix_role_brand.dart';
import '../theme/unix_theme.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/unix_account_bar.dart';
import 'instructor/instructor_perfil_page.dart';
import 'instructor/instructor_horarios_page.dart';
import '../main.dart';

class InstructorPage extends StatefulWidget {
  const InstructorPage({super.key});

  @override
  State<InstructorPage> createState() => _InstructorPageState();
}

class _InstructorPageState extends State<InstructorPage> {
  static const String _perfilUrl = 'http://127.0.0.1:8000/api/auth/perfil/me/';

  static Color get bg => UnixColors.adapt(Color(0xFF031426));
  static Color get sidebar => UnixColors.adapt(Color(0xFF061C31));
  static Color get card => UnixColors.adapt(Color(0xFF0A2947));
  static Color get border => UnixColors.border;
  static const orange = Color(0xFFFF8A24);
  static Color get blue => UnixColors.adapt(Color(0xFF2796FF));
  static Color get muted => UnixColors.adapt(Color(0xFF91A9BE));

  int _selected = 0;
  int _profileVersion = 0;

  String _primerNombre = 'profesor';
  String _nombreCompleto = '';
  String _numeroControl = '';

  bool _loggingOut = false;
  bool _loadingName = false;

  static const _labels = ['Mis clases', 'Mi perfil'];

  static const _icons = [Icons.menu_book_rounded, Icons.person_rounded];

  @override
  void initState() {
    super.initState();
    _cargarNombre();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ============================================================
  // NOMBRE REAL DESDE EL BACKEND
  // ============================================================

  Future<void> _cargarNombre({bool mostrarError = false}) async {
    if (_loadingName || _loggingOut) return;
    _loadingName = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.trim().isEmpty) {
        throw Exception('Inicia sesión para cargar tu nombre.');
      }

      final response = await http
          .get(
            Uri.parse(_perfilUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(Duration(seconds: 20));

      if (response.statusCode == 401) {
        throw Exception('Tu sesión venció. Cierra sesión y vuelve a ingresar.');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'No se pudo cargar el nombre (${response.statusCode}).',
        );
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data is! Map<String, dynamic>) {
        throw Exception('Respuesta inesperada del servidor.');
      }

      if (data['rol']?.toString().toLowerCase() != 'instructor') {
        throw Exception('La sesión no corresponde a un instructor.');
      }

      final nombreCompleto = data['nombre_completo']?.toString().trim() ?? '';

      if (!mounted || nombreCompleto.isEmpty) return;

      setState(() {
        _nombreCompleto = nombreCompleto;
        _numeroControl = data['numero_control']?.toString().trim() ?? '';
        _primerNombre = nombreCompleto.split(RegExp(r'\s+')).first;
      });
    } catch (error) {
      debugPrint('No se pudo cargar el nombre: $error');

      if (mostrarError) {
        _message(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      _loadingName = false;
    }
  }

  void _navigate(int index) {
    final previous = _selected;

    setState(() {
      _selected = index;
    });

    // Recarga el saludo al volver al inicio o salir del perfil.
    if (index == 0 || previous == 1) {
      _cargarNombre();
    }
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // ============================================================
  // ESTRUCTURA PRINCIPAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        UnixTheme.watch(context);
        final mobile = constraints.maxWidth < 760;
        final compact = constraints.maxWidth < 760;

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Row(
              children: [
                if (!mobile) _buildSidebar(compact),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(mobile),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(mobile ? 16 : 24),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 1350),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildHeading(mobile),
                                  SizedBox(height: 20),
                                  _buildCurrentPage(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: mobile ? _buildBottomBar() : null,
        );
      },
    );
  }

  // ============================================================
  // MENÚ LATERAL
  // ============================================================

  Widget _buildSidebar(bool compact) {
    return Container(
      width: compact
          ? 82
          : (MediaQuery.sizeOf(context).width < 1100 ? 185 : 220),
      decoration: BoxDecoration(
        color: sidebar,
        border: Border(right: BorderSide(color: border)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 26),
            child: UnixRoleBrand(compact: compact),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 10),
              itemCount: _labels.length,
              itemBuilder: (context, index) {
                final active = _selected == index;

                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Tooltip(
                    message: _labels[index],
                    child: Material(
                      color: active ? UnixColors.selected : sidebar,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _navigate(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: Row(
                            mainAxisAlignment: compact
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            children: [
                              Icon(
                                _icons[index],
                                color: active ? orange : muted,
                                size: 20,
                              ),
                              if (!compact) ...[
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _labels[index],
                                    style: TextStyle(
                                      color: active
                                          ? (UnixColors.dark
                                                ? UnixColors.text
                                                : blue)
                                          : muted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BARRA SUPERIOR Y OPCIONES
  // ============================================================

  Widget _buildTopBar(bool mobile) {
    return UnixAccountBar(
      nombre: _nombreCompleto.isEmpty ? _primerNombre : _nombreCompleto,
      rol: 'Instructor',
      identificador: _numeroControl,
      onProfile: () => _navigate(1),
      onNotifications: () => _message('No hay notificaciones disponibles.'),
      notificationsTooltip: 'Notificaciones',
      accountMenu: PopupMenuButton<String>(
        tooltip: 'Opciones de cuenta',
        enabled: !_loggingOut,
        color: sidebar,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: muted),
        onSelected: (value) {
          switch (value) {
            case 'profile':
              _navigate(1);
              break;

            case 'refresh':
              setState(() {
                _profileVersion++;
              });
              _cargarNombre(mostrarError: true);
              break;

            case 'logout':
              _logout();
              break;
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem<String>(
            value: 'profile',
            child: Text('Mi perfil', style: TextStyle(color: UnixColors.text)),
          ),
          PopupMenuItem<String>(
            value: 'refresh',
            child: Text(
              'Actualizar datos',
              style: TextStyle(color: UnixColors.text),
            ),
          ),
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout_rounded, color: UnixColors.text, size: 19),
                SizedBox(width: 10),
                Text('Cerrar sesión', style: TextStyle(color: UnixColors.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVEGACIÓN MÓVIL
  // ============================================================

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: UnixColors.surface,
        border: Border(top: BorderSide(color: border.withValues(alpha: 0.75))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: UnixColors.dark ? 0.16 : 0.035,
            ),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 5),
          child: Row(
            children: [
              Expanded(
                child: _bottomBarItem(
                  index: 0,
                  icon: Icons.auto_stories_rounded,
                  label: 'Mis clases',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _bottomBarItem(
                  index: 1,
                  icon: Icons.account_circle_rounded,
                  label: 'Mi perfil',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBarItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final active = _selected == index;
    final activeColor = UnixColors.dark ? orange : const Color(0xFFE87516);

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigate(index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            decoration: BoxDecoration(
              color: active
                  ? activeColor.withValues(alpha: UnixColors.dark ? 0.16 : 0.09)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 42,
                  height: 29,
                  decoration: BoxDecoration(
                    color: active ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 21,
                    color: active ? Colors.white : UnixColors.muted,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    color: active ? activeColor : UnixColors.muted,
                    fontSize: 11.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeading(bool mobile) {
    return Text(
      _selected == 0 ? 'Mis clases' : _labels[_selected],
      style: TextStyle(
        color: UnixColors.text,
        fontSize: mobile ? 28 : 34,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  // ============================================================
  // SECCIONES
  // ============================================================

  Widget _buildCurrentPage() {
    if (_selected == 1) {
      return InstructorPerfilPage(key: ValueKey(_profileVersion));
    }

    return const InstructorHorariosPage();
  }

  // ============================================================
  // CERRAR SESIÓN
  // ============================================================

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          UnixTheme.watch(dialogContext);
          return AlertDialog(
            backgroundColor: card,
            title: Text(
              '¿Cerrar sesión?',
              style: TextStyle(color: UnixColors.text),
            ),
            content: Text(
              'Se cerrará tu sesión en este dispositivo.',
              style: TextStyle(color: muted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: UnixColors.onOrange,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text('Cerrar sesión'),
              ),
            ],
          );
        },
      );

      if (!mounted || confirmed != true) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('user_rol');

      if (prefs.getString('jwt_token') != null ||
          prefs.getString('user_rol') != null) {
        throw StateError('No se pudo limpiar la sesión.');
      }

      try {
        await GoogleSignIn.instance.signOut();
      } catch (error) {
        debugPrint('Error al cerrar Google: $error');
      }

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AccessScreen()),
        (route) => false,
      );
    } catch (error) {
      debugPrint('Error al cerrar sesión: $error');
      _message('No se pudo cerrar la sesión. Inténtalo nuevamente.');
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  // ============================================================
  // COMPONENTES
  // ============================================================

}