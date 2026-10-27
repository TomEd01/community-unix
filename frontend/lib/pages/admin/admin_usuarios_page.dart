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

  // Se conserva porque tu AdminPage ya envía este dato.
  final AdminStore store;

  @override
  State<AdminUsuariosPage> createState() => _AdminUsuariosPageState();
}

class _AdminUsuariosPageState extends State<AdminUsuariosPage> {
  // Dirección del backend.
  static const String _baseUrl =
      'http://127.0.0.1:8000/api/auth/superadmin';

  final TextEditingController _busquedaController =
      TextEditingController();

  Timer? _temporizadorBusqueda;

  List<Map<String, dynamic>> _usuarios = [];

  String _rolSeleccionado = 'Todos';
  String? _error;

  bool _cargando = true;
  bool _eliminando = false;

  // Evita que una respuesta vieja de búsqueda reemplace una más reciente.
  int _numeroPeticion = 0;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  @override
  void dispose() {
    _temporizadorBusqueda?.cancel();
    _busquedaController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _obtenerHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'No se encontró una sesión. Vuelve a iniciar sesión.',
      );
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  String _mensajeError(Object error) {
    if (error is TimeoutException) {
      return 'El servidor tardó demasiado en responder.';
    }

    if (error is http.ClientException) {
      return 'No se pudo conectar con el backend. '
          'Comprueba que Django esté encendido.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
  }

  Future<void> _cargarUsuarios() async {
    final peticionActual = ++_numeroPeticion;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final headers = await _obtenerHeaders();

      final parametros = <String, String>{};

      final busqueda = _busquedaController.text.trim();

      if (busqueda.isNotEmpty) {
        parametros['q'] = busqueda;
      }

      if (_rolSeleccionado != 'Todos') {
        parametros['rol'] = _rolSeleccionado;
      }

      final uri = Uri.parse(
        '$_baseUrl/dashboard/',
      ).replace(
        queryParameters: parametros.isEmpty ? null : parametros,
      );

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 401) {
        throw Exception(
          'Tu sesión venció o no es válida. '
          'Vuelve a iniciar sesión.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          'Esta cuenta no tiene permiso para ver los usuarios.',
        );
      }

      if (response.statusCode == 404) {
        throw Exception(
          'No se encontró la ruta del dashboard. '
          'Comprueba que Django esté actualizado y reiniciado.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'No se pudieron cargar los usuarios. '
          'Código: ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'El dashboard devolvió una respuesta inesperada.',
        );
      }

      final lista = decoded['usuarios'];

      if (lista is! List) {
        throw Exception(
          'La respuesta no contiene una lista válida en "usuarios".',
        );
      }

      final usuariosRecibidos = <Map<String, dynamic>>[];

      for (final item in lista) {
        if (item is! Map<String, dynamic>) {
          throw Exception(
            'Uno de los usuarios tiene un formato inesperado.',
          );
        }

        usuariosRecibidos.add(item);
      }

      if (!mounted || peticionActual != _numeroPeticion) return;

      setState(() {
        _usuarios = usuariosRecibidos;
      });
    } catch (error) {
      if (!mounted || peticionActual != _numeroPeticion) return;

      setState(() {
        _error = _mensajeError(error);
      });
    } finally {
      if (mounted && peticionActual == _numeroPeticion) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  void _alBuscar(String value) {
    _temporizadorBusqueda?.cancel();

    // Marca como antiguas las respuestas que ya estén en camino.
    _numeroPeticion++;

    _temporizadorBusqueda = Timer(
      const Duration(milliseconds: 400),
      _cargarUsuarios,
    );
  }

  void _seleccionarRol(String rol) {
    if (_rolSeleccionado == rol) return;

    _temporizadorBusqueda?.cancel();

    setState(() {
      _rolSeleccionado = rol;
    });

    _cargarUsuarios();
  }

  String _texto(dynamic valor) {
    if (valor == null) return '';

    return valor.toString().trim();
  }

  String _primerValor(
    Map<String, dynamic> datos,
    List<String> claves,
  ) {
    for (final clave in claves) {
      final valor = _texto(datos[clave]);

      if (valor.isNotEmpty) {
        return valor;
      }
    }

    return '';
  }

  String _nombreUsuario(Map<String, dynamic> usuario) {
    return _primerValor(
      usuario,
      ['nombre_completo', 'nombre', 'name'],
    );
  }

  String _idUsuario(Map<String, dynamic> usuario) {
    return _primerValor(
      usuario,
      ['id', 'usuario_id'],
    );
  }

  String _identificadorVisible(Map<String, dynamic> usuario) {
    final detalles = _comoMapa(usuario['detalles_perfil']);

    final numero = _primerValor(
      usuario,
      ['numero_control', 'matricula'],
    );

    if (numero.isNotEmpty) return numero;

    final numeroDetalle = _primerValor(
      detalles,
      ['numero_control', 'matricula'],
    );

    if (numeroDetalle.isNotEmpty) return numeroDetalle;

    return _idUsuario(usuario);
  }

  String _rolVisible(Map<String, dynamic> usuario) {
    if (usuario['es_superadmin'] == true) {
      return 'Super Admin';
    }

    final rol = _primerValor(usuario, ['rol', 'role']);

    if (rol.isEmpty) return 'Sin rol';

    return rol;
  }

  Map<String, dynamic> _comoMapa(dynamic valor) {
    if (valor is Map) {
      return valor.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return {};
  }

  Future<void> _abrirOpciones(
    Map<String, dynamic> usuario,
    String opcion,
  ) async {
    if (opcion == 'detalles') {
      await _mostrarDetalles(usuario);
    } else if (opcion == 'eliminar') {
      await _confirmarEliminar(usuario);
    }
  }

  Future<void> _mostrarDetalles(
    Map<String, dynamic> usuario,
  ) async {
    final nombre = _nombreUsuario(usuario);
    final correo = _primerValor(usuario, ['email', 'correo']);
    final identificador = _identificadorVisible(usuario);
    final rol = _rolVisible(usuario);

    final detalles = _comoMapa(usuario['detalles_perfil']);
    final resumen = _comoMapa(usuario['resumen_actividades']);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AdminStyle.card,
          title: Text(
            nombre.isEmpty ? 'Detalle de usuario' : nombre,
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _filaDetalle(
                    'Correo',
                    correo.isEmpty ? 'No disponible' : correo,
                  ),
                  _filaDetalle(
                    'ID / matrícula',
                    identificador.isEmpty
                        ? 'No disponible'
                        : identificador,
                  ),
                  _filaDetalle('Rol', rol),

                  const SizedBox(height: 16),

                  const Text(
                    'Información del perfil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (detalles.isEmpty)
                    const Text(
                      'No hay detalles de perfil disponibles.',
                      style: TextStyle(color: AdminStyle.muted),
                    )
                  else
                    for (final entry in detalles.entries)
                      _filaDetalle(
                        _tituloCampo(entry.key),
                        _valorVisible(entry.value),
                      ),

                  const SizedBox(height: 18),

                  const Text(
                    'Resumen de actividades',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (resumen.isEmpty)
                    const Text(
                      'No hay actividades disponibles.',
                      style: TextStyle(color: AdminStyle.muted),
                    )
                  else
                    for (final entry in resumen.entries)
                      _filaDetalle(
                        _tituloCampo(entry.key),
                        _valorVisible(entry.value),
                      ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _filaDetalle(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$titulo: ',
              style: const TextStyle(
                color: AdminStyle.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: valor.isEmpty ? 'No disponible' : valor,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  String _tituloCampo(String clave) {
    const nombres = {
      'numero_control': 'Número de control',
      'procedencia': 'Procedencia',
      'tipo_experiencia': 'Tipo de experiencia',
      'organizacion': 'Organización',
      'departamento': 'Departamento',
      'especialidad': 'Especialidad',
      'grado_academico': 'Grado académico',
      'profesor_vinculado': 'Profesor vinculado',
      'xp_total': 'XP total',
      'total_macro_eventos': 'Macro eventos',
      'total_cursos': 'Cursos',
      'total_talleres': 'Talleres',
      'total_exposiciones': 'Exposiciones',
    };

    return nombres[clave] ?? clave.replaceAll('_', ' ');
  }

  String _valorVisible(dynamic valor) {
    if (valor == null) return 'No disponible';

    if (valor is bool) {
      return valor ? 'Sí' : 'No';
    }

    if (valor is Map || valor is List) {
      return jsonEncode(valor);
    }

    final texto = valor.toString().trim();

    return texto.isEmpty ? 'No disponible' : texto;
  }

  Future<void> _confirmarEliminar(
    Map<String, dynamic> usuario,
  ) async {
    if (_eliminando) return;

    final id = _idUsuario(usuario);

    if (id.isEmpty) {
      _mostrarMensaje(
        'El servidor no devolvió el ID del usuario. '
        'No se puede realizar la eliminación.',
      );
      return;
    }

    final nombre = _nombreUsuario(usuario);
    final nombreVisible = nombre.isEmpty ? 'este usuario' : nombre;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AdminStyle.card,
          title: const Text('Eliminar usuario'),
          content: Text(
            '¿Deseas eliminar a $nombreVisible?\n\n'
            'Esta acción eliminará la cuenta según las reglas '
            'del backend y puede ser permanente.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AdminStyle.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmado != true) return;

    await _eliminarUsuario(id);
  }

  Future<void> _eliminarUsuario(String id) async {
    setState(() {
      _eliminando = true;
    });

    try {
      final headers = await _obtenerHeaders();

      final uri = Uri.parse(
        '$_baseUrl/usuarios/${Uri.encodeComponent(id)}/',
      );

      final response = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 401) {
        throw Exception(
          'Tu sesión venció o no es válida. '
          'Vuelve a iniciar sesión.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          'No tienes permiso para eliminar este usuario.',
        );
      }

      if (response.statusCode == 404) {
        throw Exception(
          'No se encontró el usuario o la ruta de eliminación.',
        );
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String detalle = '';

        try {
          final body = jsonDecode(
            utf8.decode(response.bodyBytes),
          );

          if (body is Map) {
            detalle = _texto(body['error'] ?? body['detail']);
          }
        } catch (_) {
          // Algunas respuestas pueden no ser JSON.
        }

        throw Exception(
          detalle.isNotEmpty
              ? detalle
              : 'No se pudo eliminar el usuario. '
                  'Código: ${response.statusCode}.',
        );
      }

      if (!mounted) return;

      _mostrarMensaje('Usuario eliminado correctamente.');

      // Recarga la lista real desde Django.
      await _cargarUsuarios();
    } catch (error) {
      if (!mounted) return;

      _mostrarMensaje(_mensajeError(error));
    } finally {
      if (mounted) {
        setState(() {
          _eliminando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onChanged: _alBuscar,
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
                'Maestro',
                'Externo',
              ])
                ChoiceChip(
                  label: Text(rol),
                  selected: _rolSeleccionado == rol,
                  onSelected: (_) => _seleccionarRol(rol),
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
          else if (_usuarios.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No se encontraron usuarios.',
                style: TextStyle(color: AdminStyle.muted),
              ),
            )
          else ...[
            Text(
              '${_usuarios.length} usuario(s)',
              style: const TextStyle(
                color: AdminStyle.muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            for (final usuario in _usuarios)
              _tarjetaUsuario(usuario),
          ],
        ],
      ),
    );
  }

  Widget _tarjetaUsuario(Map<String, dynamic> usuario) {
    final nombre = _nombreUsuario(usuario);
    final correo = _primerValor(usuario, ['email', 'correo']);
    final identificador = _identificadorVisible(usuario);
    final rol = _rolVisible(usuario);

    final activo = usuario['activo'];

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
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),

              Text(
                'ID: ${identificador.isEmpty ? 'No disponible' : identificador}',
                style: const TextStyle(color: AdminStyle.muted),
              ),

              const SizedBox(height: 4),

              Text(
                correo.isEmpty ? 'Sin correo' : correo,
                style: const TextStyle(color: AdminStyle.muted),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  AdminBadge(rol),

                  if (activo is bool)
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
          trailing: PopupMenuButton<String>(
            tooltip: 'Opciones del usuario',
            enabled: !_eliminando,
            onSelected: (opcion) {
              _abrirOpciones(usuario, opcion);
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'detalles',
                child: Text('Ver detalles'),
              ),
              PopupMenuItem<String>(
                value: 'eliminar',
                child: Text(
                  'Eliminar usuario',
                  style: TextStyle(color: AdminStyle.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}