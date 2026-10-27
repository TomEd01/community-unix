import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_store.dart';
import 'admin_style.dart';

class AdminUsuariosPage extends StatefulWidget {
  const AdminUsuariosPage({
    super.key,
    required this.store,
  });

  // Se conserva para que siga funcionando con tu AdminPage actual.
  final AdminStore store;

  @override
  State<AdminUsuariosPage> createState() => _AdminUsuariosPageState();
}

class _AdminUsuariosPageState extends State<AdminUsuariosPage> {
  static const String _usuariosUrl =
      'http://127.0.0.1:8000/api/auth/admin/usuarios/';

  final TextEditingController _busquedaController =
      TextEditingController();

  List<Map<String, dynamic>> _usuarios = [];

  String _busqueda = '';
  String _rolSeleccionado = 'Todos';

  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    if (_cargando && _usuarios.isNotEmpty) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.trim().isEmpty) {
        throw Exception(
          'No se encontró una sesión. Vuelve a iniciar sesión.',
        );
      }

      final response = await http.get(
        Uri.parse(_usuariosUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 401) {
        throw Exception(
          'La sesión venció o no es válida. Vuelve a iniciar sesión.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          'Esta cuenta no tiene permiso para consultar los usuarios.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'No se pudieron cargar los usuarios. '
          'Código: ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! List) {
        throw Exception('El servidor devolvió un formato inesperado.');
      }

      final usuarios = <Map<String, dynamic>>[];

      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          usuarios.add(item);
        } else {
          throw Exception(
            'Uno de los registros tiene un formato inesperado.',
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _usuarios = usuarios;
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _error = 'El servidor tardó demasiado en responder.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  String _texto(Map<String, dynamic> usuario, String campo) {
    return usuario[campo]?.toString().trim() ?? '';
  }

  String _rolVisible(Map<String, dynamic> usuario) {
    if (usuario['es_superadmin'] == true) {
      return 'Super Admin';
    }

    final rol = _texto(usuario, 'rol').toLowerCase();

    switch (rol) {
      case 'alumno':
        return 'Alumno';
      case 'instructor':
        return 'Instructor';
      case 'externo':
        return 'Externo';
      default:
        return rol.isEmpty ? 'Sin rol' : _texto(usuario, 'rol');
    }
  }

  List<Map<String, dynamic>> get _usuariosFiltrados {
    return _usuarios.where((usuario) {
      final rol = _rolVisible(usuario);

      final coincideRol =
          _rolSeleccionado == 'Todos' ||
          rol == _rolSeleccionado;

      final textoBusqueda = [
        _texto(usuario, 'nombre_completo'),
        _texto(usuario, 'email'),
        _texto(usuario, 'numero_control'),
        _texto(usuario, 'id'),
      ].join(' ').toLowerCase();

      final coincideBusqueda =
          textoBusqueda.contains(_busqueda.toLowerCase());

      return coincideRol && coincideBusqueda;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final usuarios = _usuariosFiltrados;

    return AdminPanel(
      title: 'Usuarios registrados',
      action: IconButton(
        tooltip: 'Actualizar lista',
        onPressed: _cargando ? null : _cargarUsuarios,
        icon: const Icon(Icons.refresh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _busquedaController,
            onChanged: (value) {
              setState(() {
                _busqueda = value.trim();
              });
            },
            decoration: const InputDecoration(
              hintText: 'Buscar nombre, ID o correo',
              prefixIcon: Icon(Icons.search),
            ),
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final rol in [
                'Todos',
                'Alumno',
                'Instructor',
                'Externo',
                'Super Admin',
              ])
                ChoiceChip(
                  label: Text(rol),
                  selected: _rolSeleccionado == rol,
                  onSelected: (_) {
                    setState(() {
                      _rolSeleccionado = rol;
                    });
                  },
                ),
            ],
          ),

          const SizedBox(height: 20),

          if (_cargando)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: AdminStyle.orange,
                ),
              ),
            )
          else if (_error != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AdminStyle.red,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _cargarUsuarios,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            )
          else if (usuarios.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No se encontraron usuarios.',
                style: TextStyle(color: AdminStyle.muted),
              ),
            )
          else ...[
            Text(
              '${usuarios.length} usuario(s)',
              style: const TextStyle(
                color: AdminStyle.muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            for (final usuario in usuarios)
              _tarjetaUsuario(usuario),
          ],
        ],
      ),
    );
  }

  Widget _tarjetaUsuario(Map<String, dynamic> usuario) {
    final nombre = _texto(usuario, 'nombre_completo');
    final correo = _texto(usuario, 'email');
    final numeroControl = _texto(usuario, 'numero_control');
    final idUsuario = _texto(usuario, 'id');
    final rol = _rolVisible(usuario);
    final activo = usuario['is_active'] == true;

    final identificador = numeroControl.isNotEmpty
        ? numeroControl
        : idUsuario;

    final inicial = nombre.isNotEmpty
        ? nombre.substring(0, 1).toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AdminStyle.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminStyle.border),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          leading: CircleAvatar(
            backgroundColor: AdminStyle.orange,
            child: Text(
              inicial,
              style: const TextStyle(
                color: AdminStyle.background,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            nombre.isEmpty ? 'Sin nombre' : nombre,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text(
                'ID: ${identificador.isEmpty ? 'No disponible' : identificador}',
                style: const TextStyle(
                  color: AdminStyle.muted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                correo.isEmpty ? 'Sin correo' : correo,
                style: const TextStyle(
                  color: AdminStyle.muted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  AdminBadge(rol),
                  AdminBadge(
                    activo ? 'Activo' : 'Inactivo',
                    color: activo
                        ? AdminStyle.green
                        : AdminStyle.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}