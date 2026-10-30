import '../../theme/unix_role_brand.dart';
import '../../theme/unix_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/unix_account_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart' show AccessScreen;
import 'admin_store.dart';
import 'admin_style.dart';
import 'admin_inicio_page.dart';
import 'admin_macroeventos_page.dart';
import 'admin_usuarios_page.dart';
import 'admin_folios_page.dart';
import 'admin_perfil_page.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    this.nombre = 'Administrador',
    this.correo = '',
    this.id = 'ADMIN-DEMO',
    this.onLogout,
  });

  final String nombre;
  final String correo;
  final String id;
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Theme(
      data: AdminStyle.theme,
      child: _AdminShell(
        nombre: nombre,
        correo: correo,
        id: id,
        onLogout: onLogout,
      ),
    );
  }
}

class _AdminShell extends StatefulWidget {
  const _AdminShell({
    required this.nombre,
    required this.correo,
    required this.id,
    this.onLogout,
  });

  final String nombre;
  final String correo;
  final String id;
  final Future<void> Function()? onLogout;

  @override
  State<_AdminShell> createState() => _AdminPageState();
}

class _AdminPageState extends State<_AdminShell> {
  late final AdminStore store;

  int selected = 0;
  bool loggingOut = false;
  bool _loadingProfile = false;
  String _nombreReal = '';
  String _idReal = '';
  String? _profileError;
  static const _perfilUrl = 'http://127.0.0.1:8000/api/auth/perfil/me/';

  static const labels = [
    'Inicio',
    'Macro eventos',
    'Usuarios',
    'Verificar folios',
    'Mi perfil',
  ];

  static const icons = [
    Icons.home_outlined,
    Icons.event_outlined,
    Icons.people_outline,
    Icons.verified_user_outlined,
    Icons.person_outline,
  ];

  @override
  void initState() {
    super.initState();

    store = AdminStore(
      adminName: widget.nombre,
      adminEmail: widget.correo,
      adminId: widget.id,
    );
    _nombreReal = widget.nombre;
    _loadHeaderProfile();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  void navigate(int index) {
    // Compatibilidad con accesos antiguos al perfil, antes en índice 5.
    final destination = index == 5 ? 4 : index;

    if (!mounted || destination < 0 || destination >= labels.length) {
      return;
    }

    final previous = selected;
    setState(() => selected = destination);
    if (previous == 4 || destination == 4) _loadHeaderProfile();
  }

  Future<void> logout() async {
    if (loggingOut) return;

    setState(() => loggingOut = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('jwt_token');
      await prefs.remove('user_rol');

      if (prefs.containsKey('jwt_token') || prefs.containsKey('user_rol')) {
        throw Exception('No se pudo eliminar la sesión guardada.');
      }

      try {
        await GoogleSignIn.instance.signOut().timeout(Duration(seconds: 10));
      } catch (error) {
        debugPrint('No se pudo cerrar la sesión de Google: $error');
      }

      // Conserva cualquier limpieza adicional configurada por el proyecto.
      final callback = widget.onLogout;

      if (callback != null) {
        try {
          await callback().timeout(Duration(seconds: 10));
        } catch (error) {
          debugPrint('Error en la limpieza adicional de sesión: $error');
        }
      }

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AccessScreen()),
        (route) => false,
      );
    } catch (error) {
      debugPrint('Error al cerrar sesión: $error');

      if (!mounted) return;

      adminMessage(
        context,
        'No se pudo cerrar la sesión. Inténtalo nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() => loggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Theme(
      data: AdminStyle.theme,
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          UnixTheme.watch(context);
          return LayoutBuilder(
            builder: (context, constraints) {
              UnixTheme.watch(context);
              final mobile = constraints.maxWidth < 700;
              final compact = constraints.maxWidth < 700;

              return Scaffold(
                appBar: mobile
                    ? PreferredSize(
                        preferredSize: Size.fromHeight(70),
                        child: SafeArea(
                          bottom: false,
                          child: _buildAccountBar(mobile: true),
                        ),
                      )
                    : null,
                drawer: mobile
                    ? Drawer(
                        backgroundColor: AdminStyle.surface,
                        child: sidebar(false, closeDrawer: true),
                      )
                    : null,
                body: SafeArea(
                  child: Row(
                    children: [
                      if (!mobile)
                        SizedBox(
                          width: compact
                              ? 82
                              : (constraints.maxWidth < 1100 ? 185 : 220),
                          child: sidebar(compact),
                        ),
                      Expanded(
                        child: Column(
                          children: [
                            if (!mobile) _buildAccountBar(mobile: false),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(mobile ? 16 : 26),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: 1400),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selected == 0
                                              ? 'Panel de administración'
                                              : labels[selected],
                                          style: TextStyle(
                                            fontSize: mobile ? 25 : 30,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Algunas secciones contienen '
                                          'datos de demostración.',
                                          style: TextStyle(
                                            color: AdminStyle.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 18),
                                        _buildSectionSearch(),
                                        SizedBox(height: 20),
                                        Column(
                                          children: [
                                            for (final entry in <Widget>[
                                              AdminInicioPage(
                                                nombre: _nombreReal,
                                                store: store,
                                                onNavigate: navigate,
                                              ),
                                              AdminMacroeventosPage(
                                                store: store,
                                              ),
                                              AdminUsuariosPage(store: store),
                                              AdminFoliosPage(store: store),
                                              AdminPerfilPage(
                                                store: store,
                                                onLogout: logout,
                                                loggingOut: loggingOut,
                                              ),
                                            ].asMap().entries)
                                              Visibility(
                                                visible: entry.key == selected,
                                                maintainState: true,
                                                child: entry.value,
                                              ),
                                          ],
                                        ),
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
                bottomNavigationBar: mobile
                    ? NavigationBar(
                        backgroundColor: AdminStyle.surface,
                        selectedIndex: selected <= 2 ? selected : 3,
                        onDestinationSelected: (index) {
                          if (index < 3) {
                            navigate(index);
                          } else {
                            showMore();
                          }
                        },
                        destinations: [
                          NavigationDestination(
                            icon: Icon(Icons.home_outlined),
                            label: 'Inicio',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.event_outlined),
                            label: 'Eventos',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.people_outline),
                            label: 'Usuarios',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.more_horiz),
                            label: 'Más',
                          ),
                        ],
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _loadHeaderProfile() async {
    if (_loadingProfile || loggingOut) return;
    _loadingProfile = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null || token.trim().isEmpty) {
        throw Exception('No hay una sesión guardada.');
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
      if (response.statusCode != 200) {
        throw Exception(
          'No se pudo cargar el perfil (${response.statusCode}).',
        );
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map) throw Exception('Respuesta de perfil inesperada.');
      if (!mounted || loggingOut) return;
      setState(() {
        final nombre = data['nombre_completo']?.toString().trim() ?? '';
        if (nombre.isNotEmpty) _nombreReal = nombre;
        // La matrícula/ID del perfil es distinta del ID numérico interno.
        _idReal = data['numero_control']?.toString().trim() ?? '';
        _profileError = null;
      });
    } catch (error) {
      if (mounted && !loggingOut) {
        setState(
          () =>
              _profileError = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _buscarSecciones(String query) async {
    final texto = query.trim().toLowerCase();
    if (texto.isEmpty) return;
    final resultados = labels
        .asMap()
        .entries
        .where((entry) => entry.value.toLowerCase().contains(texto))
        .toList();
    final destino = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        UnixTheme.watch(dialogContext);
        return AlertDialog(
          backgroundColor: AdminStyle.card,
          title: Text('Buscar sección'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: resultados.isEmpty
                  ? [Text('No se encontraron secciones con ese nombre.')]
                  : resultados
                        .map(
                          (entry) => ListTile(
                            leading: Icon(icons[entry.key]),
                            title: Text(entry.value),
                            onTap: () =>
                                Navigator.pop(dialogContext, entry.key),
                          ),
                        )
                        .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
    if (mounted && destino != null) navigate(destino);
  }

  Widget _buildAccountBar({required bool mobile}) => UnixAccountBar(
    nombre: _nombreReal,
    rol: 'Super Admin',
    identificador: _idReal,
    profileError: _profileError,
    leading: mobile
        ? Builder(
            builder: (scaffoldContext) {
              UnixTheme.watch(scaffoldContext);
              return IconButton(
                tooltip: 'Abrir menú',
                icon: Icon(Icons.menu, color: AdminStyle.muted),
                onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
              );
            },
          )
        : null,
    onProfile: () => navigate(4),
    onNotifications: () => adminMessage(
      context,
      'No hay un servicio de notificaciones conectado.',
    ),
    accountMenu: profileMenu(),
  );

  Widget _buildSectionSearch() => TextField(
    onSubmitted: _buscarSecciones,
    style: TextStyle(color: UnixColors.text, fontSize: 13),
    decoration: InputDecoration(
      hintText: 'Buscar secciones: usuarios, eventos o folios...',
      hintStyle: TextStyle(color: AdminStyle.muted, fontSize: 12),
      prefixIcon: Icon(Icons.search_rounded, color: AdminStyle.muted, size: 20),
      isDense: true,
      filled: true,
      fillColor: AdminStyle.background,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AdminStyle.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AdminStyle.border),
      ),
    ),
  );

  Widget profileMenu() {
    return PopupMenuButton<int>(
      enabled: !loggingOut,
      tooltip: 'Opciones de cuenta',
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: AdminStyle.muted),
      onSelected: (value) async {
        if (value == 0) {
          navigate(4);
        } else if (value == 2) {
          await _loadHeaderProfile();
        } else if (value == 1) {
          await logout();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<int>(
          value: 2,
          enabled: !_loadingProfile,
          child: Text('Actualizar datos'),
        ),
        PopupMenuItem<int>(value: 0, child: Text('Mi perfil')),
        PopupMenuItem<int>(
          value: 1,
          enabled: !loggingOut,
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 19),
              SizedBox(width: 10),
              Text(loggingOut ? 'Cerrando sesión…' : 'Cerrar sesión'),
            ],
          ),
        ),
      ],
    );
  }

  Widget sidebar(bool compact, {bool closeDrawer = false}) {
    return Container(
      color: AdminStyle.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 24),
              child: UnixRoleBrand(compact: compact),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: labels.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Tooltip(
                      message: labels[index],
                      child: ListTile(
                        dense: true,
                        selected: index == selected,
                        selectedColor: UnixColors.dark
                            ? AdminStyle.orange
                            : UnixColors.link,
                        selectedTileColor: UnixColors.selected,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        leading: Icon(
                          icons[index],
                          color: index == selected
                              ? AdminStyle.orange
                              : AdminStyle.muted,
                        ),
                        title: compact
                            ? null
                            : Text(
                                labels[index],
                                style: const TextStyle(fontSize: 13),
                              ),
                        onTap: () {
                          if (closeDrawer) {
                            Navigator.of(context).pop();
                          }
                          navigate(index);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showMore() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AdminStyle.surface,
      builder: (sheetContext) {
        UnixTheme.watch(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final index in [3, 4])
                ListTile(
                  leading: Icon(
                    icons[index],
                    color: index == selected
                        ? AdminStyle.orange
                        : AdminStyle.muted,
                  ),
                  title: Text(labels[index]),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    navigate(index);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
