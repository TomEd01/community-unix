import '../../theme/unix_theme.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_store.dart';
import 'admin_style.dart';

class AdminPerfilPage extends StatefulWidget {
  const AdminPerfilPage({
    super.key,
    required this.store,
    this.onLogout,
    this.loggingOut = false,
  });

  final AdminStore store;
  final Future<void> Function()? onLogout;
  final bool loggingOut;

  @override
  State<AdminPerfilPage> createState() => _AdminPerfilPageState();
}

class _AdminPerfilPageState extends State<AdminPerfilPage> {
  // Es la misma dirección que utilizas en las otras páginas.
  static const String perfilUrl = 'http://127.0.0.1:8000/api/auth/perfil/me/';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _correo = '';
  String _rol = '';
  String? _error;

  bool _cargando = true;
  bool _guardando = false;
  bool _perfilCargado = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.trim().isEmpty) {
      throw Exception('No hay una sesión guardada. Vuelve a iniciar sesión.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  String _mensajeError(Object error) {
    if (error is TimeoutException) {
      return 'El servidor tardó demasiado en responder.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargando = true;
      _error = null;
      _perfilCargado = false;
    });

    try {
      final headers = await _headers();

      final response = await http
          .get(Uri.parse(perfilUrl), headers: headers)
          .timeout(Duration(seconds: 20));

      if (response.statusCode == 401) {
        throw Exception(
          'La sesión no es válida o venció. Vuelve a iniciar sesión.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'No se pudo cargar el perfil. '
          'Código: ${response.statusCode}.',
        );
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data is! Map<String, dynamic>) {
        throw Exception('El servidor devolvió una respuesta inválida.');
      }

      if (data['es_superadmin'] != true) {
        throw Exception('Esta cuenta no tiene permisos de Super Admin.');
      }

      final nombre = data['nombre_completo']?.toString().trim() ?? '';
      final correo = data['email']?.toString().trim() ?? '';
      final rol = data['rol']?.toString().trim() ?? '';

      if (!mounted) return;

      setState(() {
        _nameController.text = nombre;
        _correo = correo;
        _rol = rol;
        _perfilCargado = true;
      });

      // También actualiza el nombre que aparece en la barra superior.
      widget.store.updateName(nombre.isEmpty ? 'Administrador' : nombre);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = _mensajeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  Future<void> _actualizarPerfil() async {
    if (!_perfilCargado || _cargando || _guardando) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _guardando = true;
    });

    try {
      final headers = await _headers();

      final response = await http
          .patch(
            Uri.parse(perfilUrl),
            headers: headers,
            body: jsonEncode({'nombre_completo': _nameController.text.trim()}),
          )
          .timeout(Duration(seconds: 20));

      if (response.statusCode == 401) {
        throw Exception(
          'La sesión no es válida o venció. Vuelve a iniciar sesión.',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'No se pudo actualizar el perfil. '
          'Código: ${response.statusCode}.',
        );
      }

      if (!mounted) return;

      // El backend devuelve una respuesta parcial tras el PATCH.
      // Volvemos a consultar el perfil para mostrar el dato guardado.
      await _cargarPerfil();

      if (!mounted) return;

      if (_perfilCargado) {
        adminMessage(context, 'Perfil actualizado correctamente.');
      } else {
        adminMessage(
          context,
          'Se guardó el cambio, pero no se pudo recargar el perfil.',
        );
      }
    } catch (error) {
      if (!mounted) return;

      adminMessage(context, _mensajeError(error));
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    final puedeEditar = _perfilCargado && !_cargando && !_guardando;

    return AdminPanel(
      title: 'Mi perfil',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AdminStyle.border,
                  child: Icon(
                    Icons.admin_panel_settings_outlined,
                    color: AdminStyle.orange,
                    size: 32,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _perfilCargado
                            ? widget.store.adminName
                            : 'Administrador',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      AdminBadge('Super Admin', color: AdminStyle.green),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            if (_cargando) ...[
              Center(
                child: CircularProgressIndicator(color: AdminStyle.orange),
              ),
              SizedBox(height: 18),
            ],

            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: AdminStyle.red)),
              SizedBox(height: 8),
              TextButton.icon(
                onPressed: _cargarPerfil,
                icon: Icon(Icons.refresh),
                label: Text('Reintentar'),
              ),
              SizedBox(height: 18),
            ],

            TextFormField(
              controller: _nameController,
              enabled: puedeEditar,
              maxLength: 255,
              decoration: InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Escribe tu nombre completo.';
                }
                return null;
              },
            ),

            SizedBox(height: 14),

            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email_outlined),
                suffixIcon: Icon(Icons.lock_outline),
              ),
              child: Text(_correo.isEmpty ? 'Sin datos' : _correo),
            ),

            SizedBox(height: 14),

            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Rol registrado',
                prefixIcon: Icon(Icons.badge_outlined),
                suffixIcon: Icon(Icons.lock_outline),
              ),
              child: Text(_rol.isEmpty ? 'Sin datos' : _rol),
            ),

            SizedBox(height: 20),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: puedeEditar ? _actualizarPerfil : null,
                  icon: Icon(Icons.save_outlined),
                  label: Text(
                    _guardando ? 'Guardando...' : 'Actualizar perfil',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: widget.onLogout == null || widget.loggingOut
                      ? null
                      : () {
                          widget.onLogout!();
                        },
                  icon: Icon(Icons.logout),
                  label: Text(
                    widget.loggingOut ? 'Cerrando sesión...' : 'Cerrar sesión',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
