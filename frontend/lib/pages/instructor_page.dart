import '../backend_config.dart';
import '../theme/unix_role_brand.dart';
import '../theme/unix_theme.dart';
import '../portal/dashboard.dart';
import '../portal/courses.dart';
import '../portal/events.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/unix_account_bar.dart';

import 'instructor/instructor_perfil_page.dart';
import 'instructor/instructor_horarios_page.dart';
import 'alumno/alumno_comunidad_page.dart';

import '../main.dart';

class InstructorPage extends StatefulWidget {
  const InstructorPage({super.key});

  @override
  State<InstructorPage> createState() => _InstructorPageState();
}

class _InstructorPageState extends State<InstructorPage> {
  static const String _perfilUrl =
      '$backendUrl/api/auth/perfil/me/';

  static Color get bg =>
      UnixColors.adapt(const Color(0xFF031426));

  static Color get sidebar =>
      UnixColors.adapt(const Color(0xFF061C31));

  static Color get card =>
      UnixColors.adapt(const Color(0xFF0A2947));

  static Color get border => UnixColors.border;

  static const orange = Color(0xFFFF8A24);

  static Color get blue =>
      UnixColors.adapt(const Color(0xFF2796FF));

  static Color get muted =>
      UnixColors.adapt(const Color(0xFF91A9BE));

  int _selected = 0;
  int _profileVersion = 0;

  String _primerNombre = 'profesor';
  String _nombreCompleto = '';
  String _numeroControl = '';

  bool _loggingOut = false;
  bool _loadingName = false;

  // Permiso recibido directamente del backend.
  bool _esSuperAdmin = false;

  // ============================================================
  // SECCIONES DEL MENÚ
  // ============================================================

  static const _labels = [
    'Inicio',
    'Cursos',
    'Talleres',
    'Eventos',
    'Foros',
    'Mis clases',
    'Comunidad',
    'Mi perfil',
  ];

  static const _icons = [
    Icons.home_rounded,
    Icons.menu_book_rounded,
    Icons.construction_rounded,
    Icons.event_rounded,
    Icons.co_present_outlined,
    Icons.school_rounded,
    Icons.groups_rounded,
    Icons.person_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _cargarNombre();
  }

  // ============================================================
  // PERFIL Y PERMISOS
  // ============================================================

  Future<void> _cargarNombre({
    bool mostrarError = false,
  }) async {
    if (_loadingName || _loggingOut) return;

    setState(() {
      _loadingName = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.trim().isEmpty) {
        throw Exception(
          'Inicia sesión para cargar tus datos.',
        );
      }

      final response = await http
          .get(
            Uri.parse(_perfilUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 20));

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

      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'Respuesta inesperada del servidor.',
        );
      }

      if (data['rol']?.toString().toLowerCase() !=
          'instructor') {
        throw Exception(
          'La sesión no corresponde a un instructor.',
        );
      }

      final nombreCompleto =
          data['nombre_completo']?.toString().trim() ?? '';

      if (!mounted) return;

      setState(() {
        _nombreCompleto = nombreCompleto;

        _numeroControl =
            data['numero_control']?.toString().trim() ?? '';

        _primerNombre = nombreCompleto.isEmpty
            ? 'profesor'
            : nombreCompleto.split(RegExp(r'\s+')).first;

        _esSuperAdmin = data['es_superadmin'] == true;
      });
    } catch (error) {
      debugPrint('No se pudo cargar el perfil: $error');

      if (!mounted) return;

      setState(() {
        _esSuperAdmin = false;
      });

      if (mostrarError) {
        _message(
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingName = false;
        });
      }
    }
  }

  // ============================================================
  // NAVEGACIÓN
  // ============================================================

  void _navigate(int index) {
    final previous = _selected;

    setState(() {
      _selected = index;
    });

    if (index == 0 || index == 7 || previous == 7) {
      _cargarNombre();
    }
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text)),
      );
  }

  // ============================================================
  // CAMBIO DE VISTA A SUPER ADMIN
  // ============================================================

  Future<void> _cambiarRol() async {
    if (_loadingName || _loggingOut || !_esSuperAdmin) {
      return;
    }

    // Consultar nuevamente el permiso antes de abrir la vista.
    await _cargarNombre(mostrarError: true);

    if (!mounted ||
        !_esSuperAdmin ||
        _loadingName ||
        _loggingOut) {
      return;
    }

    final pantalla = pantallaParaRol('superadmin');

    if (pantalla == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(
          name: 'vista_superadmin_desde_rol',
        ),
        builder: (_) => pantalla,
      ),
    );

    if (mounted) {
      await _cargarNombre();
    }
  }

  // ============================================================
  // ESTRUCTURA PRINCIPAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 760;
        final compact = constraints.maxWidth < 1000;

        return Scaffold(
          backgroundColor: bg,

          body: SafeArea(
            child: Row(
              children: [
                if (!mobile)
                  _buildSidebar(compact),

                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(mobile),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(
                            mobile ? 16 : 24,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 1350,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  if (_selected == 5 ||
                                      _selected == 7) ...[
                                    _buildHeading(mobile),
                                    const SizedBox(height: 20),
                                  ],

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

          bottomNavigationBar:
              mobile ? _buildBottomBar() : null,
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
          : (MediaQuery.sizeOf(context).width < 1100
              ? 185
              : 220),

      decoration: BoxDecoration(
        color: sidebar,
        border: Border(
          right: BorderSide(color: border),
        ),
      ),

      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 26,
            ),
            child: UnixRoleBrand(
              compact: compact,
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              itemCount: _labels.length,

              itemBuilder: (context, index) {
                final active = _selected == index;

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8,
                  ),

                  child: Tooltip(
                    message: _labels[index],

                    child: Material(
                      color: active
                          ? UnixColors.selected
                          : sidebar,

                      borderRadius:
                          BorderRadius.circular(12),

                      child: InkWell(
                        onTap: () => _navigate(index),

                        borderRadius:
                            BorderRadius.circular(12),

                        child: Padding(
                          padding: const EdgeInsets.all(14),

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
                                const SizedBox(width: 12),

                                Expanded(
                                  child: Text(
                                    _labels[index],

                                    style: TextStyle(
                                      color: active
                                          ? UnixColors.text
                                          : muted,

                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w500,

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
  // BARRA SUPERIOR
  // ============================================================

  Widget _buildTopBar(bool mobile) {
    return UnixAccountBar(
      nombre: _nombreCompleto.isEmpty
          ? _primerNombre
          : _nombreCompleto,

      rol: 'Instructor',

      identificador: _numeroControl,

      onProfile: () => _navigate(7),

      onNotifications: () =>
          _message('No hay notificaciones disponibles.'),

      notificationsTooltip: 'Notificaciones',

      accountMenu: PopupMenuButton<String>(
        tooltip: 'Opciones de cuenta',

        enabled: !_loggingOut,

        color: sidebar,

        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: muted,
        ),

        onSelected: (value) async {
          switch (value) {
            case 'profile':
              _navigate(7);
              break;

            case 'refresh':
              setState(() {
                _profileVersion++;
              });

              await _cargarNombre(
                mostrarError: true,
              );
              break;

            case 'cambiar_rol':
              await _cambiarRol();
              break;

            case 'logout':
              await _logout();
              break;
          }
        },

        itemBuilder: (_) => [
          // Aparece únicamente cuando el servidor
          // confirma los permisos de Super Admin.
          if (_esSuperAdmin && !_loadingName)
            PopupMenuItem<String>(
              value: 'cambiar_rol',

              child: Row(
                children: [
                  const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: orange,
                    size: 22,
                  ),

                  const SizedBox(width: 10),

                  const Expanded(
                    child: Text('Super Admin'),
                  ),

                  IgnorePointer(
                    child: Switch(
                      value: false,
                      activeColor: orange,
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),

          PopupMenuItem<String>(
            value: 'profile',

            child: Text(
              'Mi perfil',
              style: TextStyle(
                color: UnixColors.text,
              ),
            ),
          ),

          PopupMenuItem<String>(
            value: 'refresh',

            child: Text(
              'Actualizar datos',
              style: TextStyle(
                color: UnixColors.text,
              ),
            ),
          ),

          PopupMenuItem<String>(
            value: 'logout',

            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: UnixColors.text,
                  size: 19,
                ),

                const SizedBox(width: 10),

                Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: UnixColors.text,
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
  // NAVEGACIÓN PARA CELULAR
  // ============================================================

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: sidebar,

        border: Border(
          top: BorderSide(color: border),
        ),
      ),

      child: SafeArea(
        top: false,

        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,

          padding: const EdgeInsets.symmetric(
            vertical: 6,
            horizontal: 8,
          ),

          child: Row(
            children: List.generate(
              _labels.length,

              (index) => SizedBox(
                width: 85,

                child: _bottomBarItem(
                  index: index,
                  icon: _icons[index],
                  label: _labels[index],
                ),
              ),
            ),
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

    final activeColor = UnixColors.dark
        ? orange
        : const Color(0xFFE87516);

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
            duration: const Duration(
              milliseconds: 200,
            ),

            padding: const EdgeInsets.symmetric(
              vertical: 5,
              horizontal: 8,
            ),

            decoration: BoxDecoration(
              color: active
                  ? activeColor.withValues(alpha: 0.15)
                  : Colors.transparent,

              borderRadius: BorderRadius.circular(16),
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                Container(
                  width: 42,
                  height: 29,

                  decoration: BoxDecoration(
                    color: active
                        ? activeColor
                        : Colors.transparent,

                    borderRadius:
                        BorderRadius.circular(12),
                  ),

                  child: Icon(
                    icon,
                    size: 21,
                    color: active
                        ? Colors.white
                        : muted,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  label,

                  maxLines: 1,

                  style: TextStyle(
                    color: active
                        ? activeColor
                        : muted,

                    fontSize: 11.5,

                    fontWeight: active
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TÍTULOS
  // ============================================================

  Widget _buildHeading(bool mobile) {
    return Text(
      _labels[_selected],

      style: TextStyle(
        color: UnixColors.text,
        fontSize: mobile ? 28 : 34,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  // ============================================================
  // VENTANAS DEL INSTRUCTOR
  // ============================================================

  Widget _buildCurrentPage() {
    switch (_selected) {
      case 0:
        return PortalDashboard(
          nombre: _nombreCompleto,
          alumno: true,
        );

      case 1:
        return const PortalCourses(
          adminMode: false,
        );

      case 2:
        return const PortalEvents(
          adminMode: false,
          type: 'Taller',
        );

      case 3:
        return const PortalEvents(
          adminMode: false,
          type: 'Evento',
        );

      case 4:
        return const PortalEvents(
          adminMode: false,
          type: 'Exposición',
        );

      case 5:
        return const InstructorHorariosPage();

      case 6:
        return const AlumnoComunidadPage();

      case 7:
        return InstructorPerfilPage(
          key: ValueKey(_profileVersion),
        );

      default:
        return PortalDashboard(
          nombre: _nombreCompleto,
          alumno: true,
        );
    }
  }

  // ============================================================
  // CERRAR SESIÓN
  // ============================================================

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() {
      _loggingOut = true;
    });

    try {
      final confirmed = await showDialog<bool>(
        context: context,

        builder: (dialogContext) {
          UnixTheme.watch(dialogContext);

          return AlertDialog(
            backgroundColor: card,

            title: Text(
              '¿Cerrar sesión?',
              style: TextStyle(
                color: UnixColors.text,
              ),
            ),

            content: Text(
              'Se cerrará tu sesión en este dispositivo.',
              style: TextStyle(color: muted),
            ),

            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, false),

                child: const Text('Cancelar'),
              ),

              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: UnixColors.onOrange,
                ),

                onPressed: () =>
                    Navigator.pop(dialogContext, true),

                child: const Text('Cerrar sesión'),
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
        throw StateError(
          'No se pudo limpiar la sesión.',
        );
      }

      try {
        await GoogleSignIn.instance.signOut();
      } catch (error) {
        debugPrint(
          'Error al cerrar Google: $error',
        );
      }

      if (!mounted) return;

      Navigator.of(
        context,
        rootNavigator: true,
      ).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => AccessScreen(),
        ),
        (route) => false,
      );
    } catch (error) {
      debugPrint('Error al cerrar sesión: $error');

      _message(
        'No se pudo cerrar la sesión. Inténtalo nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loggingOut = false;
        });
      }
    }
  }
}