import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:blobatar/flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';

class InstructorPerfilPage extends StatefulWidget {
  const InstructorPerfilPage({super.key});

  @override
  State<InstructorPerfilPage> createState() =>
      _InstructorPerfilPageState();
}

class _InstructorPerfilPageState extends State<InstructorPerfilPage> {
  // Coloca la URL completa de tu backend.
  // Usa la misma URL del login y cambia google/ por perfil/me/.
  static const String _perfilUrl = 'http://127.0.0.1:8000/api/auth/perfil/me/';

  static const Color _background = Color(0xFF031426);
  static const Color _card = Color(0xFF0A2947);
  static const Color _field = Color(0xFF0C3152);
  static const Color _border = Color(0xFF174064);
  static const Color _orange = Color(0xFFFF8A24);
  static const Color _muted = Color(0xFF91A9BE);
  static const Color _red = Color(0xFFFF4D5A);
  static const Color _green = Color(0xFF6ED9AB);

  final _formKey = GlobalKey<FormState>();

  final _nombre = TextEditingController();
  final _procedencia = TextEditingController();
  final _departamento = TextEditingController();
  final _especialidad = TextEditingController();
  final _grado = TextEditingController();

  Map<String, dynamic> _perfil = {};

  bool _cargando = true;
  bool _ocupado = false;
  bool _perfilCargado = false;

  String? _error;

  bool get _puedeEditar =>
      _perfilCargado && !_cargando && !_ocupado;

  String _dato(String campo) {
    return _perfil[campo]?.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _procedencia.dispose();
    _departamento.dispose();
    _especialidad.dispose();
    _grado.dispose();
    super.dispose();
  }

  // ============================================================
  // CONEXIÓN CON EL BACKEND
  // ============================================================

  Future<Map<String, dynamic>> _peticion(
    String metodo, {
    Map<String, dynamic>? datos,
  }) async {
    final uri = Uri.tryParse(_perfilUrl.trim());

    if (uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme)) {
      throw Exception(
        'Falta configurar la dirección del servidor en _perfilUrl.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'No hay una sesión guardada. Cierra sesión y vuelve a ingresar.',
      );
    }

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    late http.Response respuesta;

    try {
      switch (metodo) {
        case 'GET':
          respuesta = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 20));
          break;

        case 'PATCH':
          respuesta = await http
              .patch(
                uri,
                headers: headers,
                body: jsonEncode(datos),
              )
              .timeout(const Duration(seconds: 20));
          break;

        case 'DELETE':
          respuesta = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 20));
          break;

        default:
          throw Exception('Método no compatible.');
      }
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder. Intenta nuevamente.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar con el servidor. '
        'Revisa la conexión y la dirección del backend.',
      );
    }

    Map<String, dynamic> contenido = {};

    if (respuesta.bodyBytes.isNotEmpty) {
      try {
        final decoded = jsonDecode(
          utf8.decode(respuesta.bodyBytes),
        );

        if (decoded is Map<String, dynamic>) {
          contenido = decoded;
        }
      } catch (_) {
        // Algunas respuestas de error pueden llegar como HTML.
      }
    }

    if (respuesta.statusCode == 401) {
      throw Exception(
        'Tu sesión venció. Cierra sesión y vuelve a ingresar.',
      );
    }

    if (respuesta.statusCode < 200 ||
        respuesta.statusCode >= 300) {
      final mensaje = contenido['error'] ??
          contenido['detail'] ??
          (contenido.isNotEmpty
              ? contenido.entries
                  .map((entry) => '${entry.key}: ${entry.value}')
                  .join('\n')
              : 'Error del servidor (${respuesta.statusCode}).');

      throw Exception(mensaje.toString());
    }

    return contenido;
  }

  String _mensajeError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _avisar(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> _cargarPerfil() async {
    if (!mounted) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final datos = await _peticion('GET');

      if (!mounted) return;

      final rol = datos['rol']?.toString().toLowerCase();

      if (rol != 'instructor') {
        throw Exception(
          'Esta pantalla corresponde al perfil de profesor.',
        );
      }

      setState(() {
        _perfil = datos;

        _nombre.text = _dato('nombre_completo');
        _procedencia.text = _dato('procedencia');
        _departamento.text = _dato('departamento');
        _especialidad.text = _dato('especialidad');
        _grado.text = _dato('grado_academico');

        _perfilCargado = true;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = _mensajeError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _actualizarPerfil() async {
    if (!_puedeEditar) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _ocupado = true);

    final procedencia = _procedencia.text.trim();
    final grado = _grado.text.trim();

    final datos = <String, dynamic>{
      'nombre_completo': _nombre.text.trim(),
      'procedencia': procedencia,
      'departamento': _departamento.text.trim(),
      'especialidad': _especialidad.text.trim(),
      'grado_academico': grado,

      // Compatibilidad con los valores especiales de tu backend.
      if (procedencia == 'Otra institución')
        'nombre_institucion': procedencia,

      if (grado == 'Otro')
        'especifica_grado': grado,
    };

    try {
      await _peticion('PATCH', datos: datos);

      if (!mounted) return;

      _avisar('Perfil actualizado correctamente.');

      // El backend no devuelve todos los campos al actualizar.
      await _cargarPerfil();
    } catch (error) {
      _avisar(_mensajeError(error));
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
      }
    }
  }

  // ============================================================
  // CUENTA Y SESIÓN
  // ============================================================

  Future<bool> _confirmar({
    required String titulo,
    required String mensaje,
    required String accion,
    bool peligro = false,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            titulo,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            mensaje,
            style: const TextStyle(
              color: _muted,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: _muted),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: peligro ? _red : _orange,
                foregroundColor: peligro
                    ? Colors.white
                    : _background,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(accion),
            ),
          ],
        );
      },
    );

    return resultado ?? false;
  }

  Future<void> _salirAlLogin() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('jwt_token');
    await prefs.remove('user_rol');

    try {
      await GoogleSignIn.instance.signOut();
    } catch (error) {
      debugPrint(
        'No se pudo cerrar la sesión de Google: $error',
      );
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const AccessScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _cerrarSesion() async {
    if (_ocupado || _cargando) return;

    setState(() => _ocupado = true);

    try {
      final confirmar = await _confirmar(
        titulo: 'Cerrar sesión',
        mensaje: '¿Quieres salir de tu cuenta?',
        accion: 'Cerrar sesión',
      );

      if (!mounted || !confirmar) return;

      await _salirAlLogin();
    } catch (error) {
      _avisar(_mensajeError(error));
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
      }
    }
  }

  Future<void> _eliminarCuenta() async {
    if (!_puedeEditar) return;

    setState(() => _ocupado = true);

    try {
      final confirmar = await _confirmar(
        titulo: 'Eliminar cuenta',
        mensaje:
            'Tu cuenta será eliminada permanentemente. '
            'Esta acción no se puede deshacer. '
            '¿Deseas continuar?',
        accion: 'Eliminar cuenta',
        peligro: true,
      );

      if (!mounted || !confirmar) return;

      await _peticion('DELETE');

      if (!mounted) return;

      await _salirAlLogin();
    } catch (error) {
      _avisar(_mensajeError(error));
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
      }
    }
  }

  // ============================================================
  // DISEÑO RESPONSIVE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_cargando) ...[
          const LinearProgressIndicator(
            color: _orange,
            backgroundColor: _field,
          ),
          const SizedBox(height: 16),
        ],

        if (_error != null) ...[
          _avisoConexion(),
          const SizedBox(height: 20),
        ],

        LayoutBuilder(
          builder: (context, constraints) {
            final perfil = _tarjetaPerfil();
            final formulario = _formulario();
            final acciones = _accionesCuenta();

            // PC
            if (constraints.maxWidth >= 1050) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 230,
                    child: perfil,
                  ),
                  const SizedBox(width: 20),
                  Expanded(child: formulario),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 250,
                    child: acciones,
                  ),
                ],
              );
            }

            // Tablet / iPad
            if (constraints.maxWidth >= 700) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 220,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        perfil,
                        const SizedBox(height: 20),
                        acciones,
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(child: formulario),
                ],
              );
            }

            // Teléfono
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                perfil,
                const SizedBox(height: 20),
                formulario,
                const SizedBox(height: 20),
                acciones,
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _avisoConexion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: _orange,
                size: 21,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No se pudieron cargar los datos',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(
              color: _muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _cargando || _ocupado
                ? null
                : _cargarPerfil,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar conexión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _orange,
              side: const BorderSide(color: _border),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TARJETA DEL PROFESOR
  // ============================================================

  Widget _tarjetaPerfil() {
    final id = _dato('numero_control').trim();
    final nombre = _dato('nombre_completo').trim();

    return _panel(
      titulo: 'Mi perfil',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _border),
            ),
            child: id.isEmpty
                ? const SizedBox(
                    width: 110,
                    height: 110,
                    child: Icon(
                      Icons.person_rounded,
                      size: 70,
                      color: _muted,
                    ),
                  )
                : AnimatedBlobatar(
                    key: ValueKey(id),
                    name: id,
                    size: 110,
                    animation: BlobatarAnimation.always,
                  ),
          ),
          const SizedBox(height: 18),
          Text(
            nombre.isEmpty ? 'Profesor' : nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF123F62),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Profesor',
              style: TextStyle(
                color: Color(0xFF62B9FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            'ID: ${id.isEmpty ? '—' : id}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _green,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: _border),
          const SizedBox(height: 12),
          const Text(
            'Comunidad UNIX ITC',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMACIÓN PERSONAL
  // ============================================================

  Widget _formulario() {
    return _panel(
      titulo: 'Información del profesor',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _entrada(
              label: 'Nombre completo',
              controller: _nombre,
              icon: Icons.person_outline,
              maxLength: 255,
              obligatorio: true,
            ),
             
            _soloLectura(
              label: 'Rol',
              valor: _dato('rol').isEmpty
                  ? 'Instructor'
                  : _dato('rol'),
              icon: Icons.badge_outlined,
            ),
            _soloLectura(
              label: 'Número de control / ID',
              valor: _dato('numero_control'),
              icon: Icons.fingerprint,
            ),
            _entrada(
              label: 'Institución de procedencia',
              controller: _procedencia,
              icon: Icons.school_outlined,
              maxLength: 100,
              obligatorio: true,
            ),
            _entrada(
              label: 'Departamento',
              controller: _departamento,
              icon: Icons.business_outlined,
              maxLength: 100,
            ),
            _entrada(
              label: 'Especialidad',
              controller: _especialidad,
              icon: Icons.workspace_premium_outlined,
              maxLength: 100,
            ),
            _entrada(
              label: 'Grado académico',
              controller: _grado,
              icon: Icons.history_edu_outlined,
              maxLength: 50,
              obligatorio: true,
            ),
            _cuentaGoogle(),
              const SizedBox(height: 16
              ),
            const Text(
              'Escribe el nombre de tu institución '
              'y tu grado académico.',
              style: TextStyle(
                color: _muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _puedeEditar
                  ? _actualizarPerfil
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: _background,
                disabledBackgroundColor: _field,
                disabledForegroundColor: _muted,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Actualizar perfil'),
            ),
          ],
        ),
      ),
    );
  }
Widget _cuentaGoogle() {
  final correo = _dato('email').trim();

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _background,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _border),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Text(
            'G',
            style: TextStyle(
              color: Color(0xFF4285F4),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cuenta vinculada con Google',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              SelectableText(
                correo.isEmpty
                    ? 'Correo pendiente de cargar'
                    : correo,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const Tooltip(
          message: 'El correo está vinculado a Google y no se puede editar.',
          child: Icon(
            Icons.lock_outline_rounded,
            color: _muted,
            size: 23,
          ),
        ),
      ],
    ),
  );
}

  Widget _entrada({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required int maxLength,
    bool obligatorio = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: _puedeEditar,
        maxLength: maxLength,
        style: const TextStyle(color: Colors.white),
        cursorColor: _orange,
        decoration: _decoracion(
          label: label,
          icon: icon,
        ).copyWith(
          counterText: '',
        ),
        validator: (value) {
          if (obligatorio &&
              (value == null || value.trim().isEmpty)) {
            return 'Completa este campo.';
          }

          return null;
        },
      ),
    );
  }

  Widget _soloLectura({
    required String label,
    required String valor,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: ValueKey('$label:$valor'),
        initialValue: valor,
        readOnly: true,
        style: const TextStyle(color: _muted),
        decoration: _decoracion(
          label: label,
          icon: icon,
        ).copyWith(
          suffixIcon: const Icon(
            Icons.lock_outline,
            color: _muted,
            size: 17,
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracion({
    required String label,
    required IconData icon,
  }) {
    OutlineInputBorder borde(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );
    }

    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(color: _muted),
      floatingLabelStyle: const TextStyle(color: _muted),
      filled: true,
      fillColor: _field,
      prefixIcon: Icon(
        icon,
        color: _muted,
        size: 21,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: borde(_border),
      enabledBorder: borde(_border),
      disabledBorder: borde(_border),
      focusedBorder: borde(_orange),
      errorBorder: borde(_red),
      focusedErrorBorder: borde(_red),
      errorStyle: const TextStyle(color: _red),
    );
  }

  // ============================================================
  // ACCIONES DE LA CUENTA
  // ============================================================

  Widget _accionesCuenta() {
    return _panel(
      titulo: 'Cuenta',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Administra tu sesión y tu cuenta.',
            style: TextStyle(
              color: _muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _ocupado || _cargando
                ? null
                : _cerrarSesion,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: _muted,
              side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: _border),
          const SizedBox(height: 16),
          const Text(
            'Eliminar cuenta',
            style: TextStyle(
              color: _red,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'La eliminación de tu cuenta es permanente.',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _puedeEditar
                ? _eliminarCuenta
                : null,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar cuenta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _red,
              disabledForegroundColor: _muted,
              side: BorderSide(
                color: _puedeEditar ? _red : _border,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_ocupado) ...[
            const SizedBox(height: 18),
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: _orange,
                  strokeWidth: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // CONTENEDOR DE TARJETAS
  // ============================================================

  Widget _panel({
    required String titulo,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}