import '../../theme/unix_theme.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_store.dart';
import 'admin_style.dart';

class AdminUsuariosPage extends StatefulWidget {
  const AdminUsuariosPage({super.key, required this.store});

  // Se conserva porque tu AdminPage ya envía este dato.
  final AdminStore store;

  @override
  State<AdminUsuariosPage> createState() => _AdminUsuariosPageState();
}

class _AdminUsuariosPageState extends State<AdminUsuariosPage> {
  // Dirección del backend.
  static const String _baseUrl = 'http://127.0.0.1:8000/api/auth/superadmin';

  final TextEditingController _busquedaController = TextEditingController();

  Timer? _temporizadorBusqueda;

  List<Map<String, dynamic>> _usuarios = [];

  String _rolSeleccionado = 'Todos';
  String? _error;

  bool _cargando = true;
  bool _eliminando = false;
  bool _otorgandoPermisos = false;

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
      throw Exception('No se encontró una sesión. Vuelve a iniciar sesión.');
    }

    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
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
      ..showSnackBar(SnackBar(content: Text(mensaje)));
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
      ).replace(queryParameters: parametros.isEmpty ? null : parametros);

      final response = await http
          .get(uri, headers: headers)
          .timeout(Duration(seconds: 20));

      if (response.statusCode == 401) {
        throw Exception(
          'Tu sesión venció o no es válida. '
          'Vuelve a iniciar sesión.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception('Esta cuenta no tiene permiso para ver los usuarios.');
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

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map<String, dynamic>) {
        throw Exception('El dashboard devolvió una respuesta inesperada.');
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
          throw Exception('Uno de los usuarios tiene un formato inesperado.');
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

    _temporizadorBusqueda = Timer(Duration(milliseconds: 400), _cargarUsuarios);
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

  String _primerValor(Map<String, dynamic> datos, List<String> claves) {
    for (final clave in claves) {
      final valor = _texto(datos[clave]);

      if (valor.isNotEmpty) {
        return valor;
      }
    }

    return '';
  }

  String _nombreUsuario(Map<String, dynamic> usuario) {
    return _primerValor(usuario, ['nombre_completo', 'nombre', 'name']);
  }

  String _idUsuario(Map<String, dynamic> usuario) {
    return _primerValor(usuario, ['id', 'usuario_id']);
  }

  String _identificadorVisible(Map<String, dynamic> usuario) {
    final detalles = _comoMapa(usuario['detalles_perfil']);

    final numero = _primerValor(usuario, ['numero_control', 'matricula']);

    if (numero.isNotEmpty) return numero;

    final numeroDetalle = _primerValor(detalles, [
      'numero_control',
      'matricula',
    ]);

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
      return valor.map((key, value) => MapEntry(key.toString(), value));
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

  Future<void> _mostrarDetalles(Map<String, dynamic> usuario) async {
    final nombre = _nombreUsuario(usuario);
    final correo = _primerValor(usuario, ['email', 'correo']);
    final identificador = _identificadorVisible(usuario);
    final rol = _rolVisible(usuario);

    final detalles = _comoMapa(usuario['detalles_perfil']);
    final resumen = _comoMapa(usuario['resumen_actividades'])
      ..removeWhere(
        (clave, valor) =>
            clave.toLowerCase() == 'nivel' ||
            clave.toLowerCase().contains('xp'),
      );

    // Espera la opción seleccionada en la ventana de detalles.
    final accion = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        UnixTheme.watch(dialogContext);
        return AlertDialog(
          backgroundColor: AdminStyle.card,
          title: Text(nombre.isEmpty ? 'Detalle de usuario' : nombre),
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
                    identificador.isEmpty ? 'No disponible' : identificador,
                  ),
                  _filaDetalle('Rol', rol),

                  SizedBox(height: 16),

                  Text(
                    'Información del perfil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: UnixColors.text,
                    ),
                  ),

                  SizedBox(height: 8),

                  if (detalles.isEmpty)
                    Text(
                      'No hay detalles de perfil disponibles.',
                      style: TextStyle(color: AdminStyle.muted),
                    )
                  else
                    for (final entry in detalles.entries)
                      _filaDetalle(
                        _tituloCampo(entry.key),
                        _valorVisible(entry.value),
                      ),

                  SizedBox(height: 18),

                  Text(
                    'Resumen de actividades',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: UnixColors.text,
                    ),
                  ),

                  SizedBox(height: 8),

                  if (resumen.isEmpty)
                    Text(
                      'No hay actividades disponibles.',
                      style: TextStyle(color: AdminStyle.muted),
                    )
                  else
                    for (final entry in resumen.entries)
                      if (entry.key.toLowerCase() != 'nivel')
                        _filaDetalle(
                          _tituloCampo(entry.key),
                          _valorVisible(entry.value),
                        ),
                ],
              ),
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(dialogContext).pop('hacer_admin');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: usuario['es_superadmin'] == true
                          ? AdminStyle.red
                          : AdminStyle.orange,
                      side: BorderSide(
                        color: usuario['es_superadmin'] == true
                            ? AdminStyle.red
                            : AdminStyle.orange,
                        width: 1.5,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      usuario['es_superadmin'] == true
                          ? Icons.remove_moderator_outlined
                          : Icons.admin_panel_settings_outlined,
                    ),
                    label: Text(
                      usuario['es_superadmin'] == true
                          ? 'Quitar Super Admin'
                          : 'Hacer Super Admin',
                    ),
                  ),

                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop('cerrar');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminStyle.orange,
                      side: BorderSide(color: AdminStyle.orange, width: 1.5),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Cerrar'),
                  ),

                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(dialogContext).pop('eliminar');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminStyle.red,
                      side: BorderSide(color: AdminStyle.red, width: 1.5),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(Icons.delete_outline),
                    label: Text('Eliminar cuenta'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    // Si seleccionó eliminar, abre la confirmación existente.
    if (!mounted) return;

    if (accion == 'eliminar') {
      await _confirmarEliminar(usuario);
    } else if (accion == 'hacer_admin') {
      await _confirmarSuperAdmin(usuario);
    }
  }

  Future<void> _confirmarSuperAdmin(Map<String, dynamic> usuario) async {
    if (_otorgandoPermisos || _eliminando) return;
    final id = _idUsuario(usuario);
    final nombre = _nombreUsuario(usuario);
    final nombreVisible = nombre.isEmpty ? 'este usuario' : nombre;
    final esAdminActual = usuario['es_superadmin'] == true;
    final nuevoEstado = !esAdminActual;
    if (id.isEmpty) {
      _mostrarMensaje('No se encontró el ID del usuario.');
      return;
    }
    setState(() => _otorgandoPermisos = true);
    try {
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          UnixTheme.watch(dialogContext);
          return AlertDialog(
            backgroundColor: AdminStyle.card,
            title: Text(
              esAdminActual
                  ? 'Quitar permisos de Super Admin'
                  : 'Otorgar permisos de Super Admin',
            ),
            content: Text(
              esAdminActual
                  ? '¿Estás seguro de que quieres quitar los permisos de Super Admin a $nombreVisible?'
                  : '¿Estás seguro de que quieres hacer Super Admin a $nombreVisible?',
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: esAdminActual
                      ? AdminStyle.red
                      : AdminStyle.orange,
                  foregroundColor: UnixColors.text,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(esAdminActual ? 'Quitar permisos' : 'Confirmar'),
              ),
            ],
          );
        },
      );
      if (!mounted || confirmado != true) return;
      final headers = await _obtenerHeaders();
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/usuarios/${Uri.encodeComponent(id)}/'),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({'es_superadmin': nuevoEstado}),
          )
          .timeout(Duration(seconds: 20));
      if (response.statusCode == 401) {
        throw Exception('Tu sesión venció. Vuelve a iniciar sesión.');
      }
      if (response.statusCode == 403) {
        throw Exception('No tienes permiso para realizar esta acción.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String detalle = '';
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          if (body is Map) detalle = _texto(body['error'] ?? body['detail']);
        } catch (_) {}
        throw Exception(
          detalle.isNotEmpty
              ? detalle
              : 'No se pudo actualizar el permiso. Código: ${response.statusCode}.',
        );
      }
      if (!mounted) return;
      _mostrarMensaje(
        nuevoEstado
            ? '$nombreVisible ahora tiene permisos de Super Admin.'
            : 'Se quitaron los permisos de Super Admin a $nombreVisible.',
      );
      await _cargarUsuarios();
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(_mensajeError(error));
    } finally {
      if (mounted) setState(() => _otorgandoPermisos = false);
    }
  }

  Widget _filaDetalle(String titulo, String valor) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$titulo: ',
              style: TextStyle(
                color: AdminStyle.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: valor.isEmpty ? 'No disponible' : valor,
              style: TextStyle(color: UnixColors.text),
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
      'profesor_actual': 'Profesor actual',
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

  Future<void> _confirmarEliminar(Map<String, dynamic> usuario) async {
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
        UnixTheme.watch(dialogContext);
        return AlertDialog(
          backgroundColor: AdminStyle.card,
          title: Text('Eliminar usuario'),
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
              child: Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AdminStyle.red,
                foregroundColor: UnixColors.text,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text('Eliminar'),
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

      final uri = Uri.parse('$_baseUrl/usuarios/${Uri.encodeComponent(id)}/');

      final response = await http
          .delete(uri, headers: headers)
          .timeout(Duration(seconds: 20));

      if (response.statusCode == 401) {
        throw Exception(
          'Tu sesión venció o no es válida. '
          'Vuelve a iniciar sesión.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception('No tienes permiso para eliminar este usuario.');
      }

      if (response.statusCode == 404) {
        throw Exception('No se encontró el usuario o la ruta de eliminación.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String detalle = '';

        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));

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
    UnixTheme.watch(context);
    return AdminPanel(
      title: 'Usuarios registrados',
      action: IconButton(
        tooltip: 'Actualizar lista',
        onPressed: _cargando ? null : _cargarUsuarios,
        icon: Icon(Icons.refresh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _busquedaController,
            onChanged: _alBuscar,
            decoration: InputDecoration(
              hintText: 'Buscar nombre, ID o correo',
              prefixIcon: Icon(Icons.search),
            ),
          ),

          SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final rol in ['Todos', 'Alumno', 'Maestro', 'Externo'])
                ChoiceChip(
                  label: Text(rol),
                  selected: _rolSeleccionado == rol,
                  onSelected: (_) => _seleccionarRol(rol),
                ),
            ],
          ),

          SizedBox(height: 20),

          if (_cargando)
            Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AdminStyle.orange),
              ),
            )
          else if (_error != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_error!, style: TextStyle(color: AdminStyle.red)),
                SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _cargarUsuarios,
                  icon: Icon(Icons.refresh),
                  label: Text('Reintentar'),
                ),
              ],
            )
          else if (_usuarios.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No se encontraron usuarios.',
                style: TextStyle(color: AdminStyle.muted),
              ),
            )
          else ...[
            Text(
              '${_usuarios.length} usuario(s)',
              style: TextStyle(color: AdminStyle.muted, fontSize: 12),
            ),
            SizedBox(height: 12),
            for (final usuario in _usuarios) _tarjetaUsuario(usuario),
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
      padding: EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AdminStyle.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminStyle.border),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          leading: CircleAvatar(
            backgroundColor: AdminStyle.orange,
            child: Text(
              inicial,
              style: TextStyle(
                color: AdminStyle.background,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            nombre.isEmpty ? 'Sin nombre' : nombre,
            style: TextStyle(
              color: UnixColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 6),

              Text(
                'ID: ${identificador.isEmpty ? 'No disponible' : identificador}',
                style: TextStyle(color: AdminStyle.muted),
              ),

              SizedBox(height: 4),

              Text(
                correo.isEmpty ? 'Sin correo' : correo,
                style: TextStyle(color: AdminStyle.muted),
              ),

              SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  AdminBadge(rol),

                  if (activo is bool)
                    AdminBadge(
                      activo ? 'Activo' : 'Inactivo',
                      color: activo ? AdminStyle.green : AdminStyle.red,
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
            itemBuilder: (_) => [
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
