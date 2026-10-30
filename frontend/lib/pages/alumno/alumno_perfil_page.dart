import '../../theme/unix_theme.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:blobatar/flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';

class AlumnoPerfilPage extends StatefulWidget {
  const AlumnoPerfilPage({super.key});

  @override
  State<AlumnoPerfilPage> createState() => _AlumnoPerfilPageState();
}

class _AlumnoPerfilPageState extends State<AlumnoPerfilPage> {
  static const String _perfilUrl = 'http://127.0.0.1:8000/api/auth/perfil/me/';

  static Color get _bg => UnixColors.adapt(Color(0xFF031426));
  static Color get _card => UnixColors.adapt(Color(0xFF0A2947));
  static Color get _field => UnixColors.adapt(Color(0xFF0C3152));
  static Color get _border => UnixColors.border;
  static const Color _orange = Color(0xFFFF8A24);
  static Color get _blue => UnixColors.adapt(Color(0xFF2796FF));
  static Color get _red => UnixColors.adapt(Color(0xFFFF4D5A));
  static Color get _muted => UnixColors.adapt(Color(0xFF91A9BE));
  static Color get _green => UnixColors.adapt(Color(0xFF6ED9AB));

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _procedenciaController = TextEditingController();

  Map<String, dynamic> _perfil = {};

  bool _loading = true;
  bool _busy = false;
  bool _loaded = false;
  String? _error;

  bool get _canEdit => _loaded && !_loading && !_busy;

  String _dato(String key) => _perfil[key]?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _procedenciaController.dispose();
    super.dispose();
  }

  // ============================================================
  // API
  // ============================================================

  Future<Map<String, dynamic>> _request(
    String method, {
    Map<String, dynamic>? data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'No hay una sesión guardada. Cierra sesión y vuelve a ingresar.',
      );
    }

    final uri = Uri.parse(_perfilUrl);
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    late http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await http
              .get(uri, headers: headers)
              .timeout(Duration(seconds: 20));
          break;

        case 'PATCH':
          response = await http
              .patch(uri, headers: headers, body: jsonEncode(data))
              .timeout(Duration(seconds: 20));
          break;

        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(Duration(seconds: 20));
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
        'No se pudo conectar con el backend. '
        'Comprueba que Django esté ejecutándose.',
      );
    }

    Map<String, dynamic> body = {};

    if (response.bodyBytes.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      } catch (_) {
        // El servidor puede devolver HTML en algunos errores.
      }
    }

    if (response.statusCode == 401) {
      throw Exception('Tu sesión venció. Cierra sesión y vuelve a ingresar.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          body['error'] ??
          body['detail'] ??
          (body.isNotEmpty
              ? body.entries
                    .map((entry) => '${entry.key}: ${entry.value}')
                    .join('\n')
              : 'Error del servidor (${response.statusCode}).');

      throw Exception(message.toString());
    }

    return body;
  }

  String _errorText(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _request('GET');

      if (!mounted) return;

      if (data['rol']?.toString().toLowerCase() != 'alumno') {
        throw Exception('La sesión actual no corresponde a un alumno.');
      }

      setState(() {
        _perfil = data;
        _nameController.text = _dato('nombre_completo');
        _procedenciaController.text = _dato('procedencia');
        _loaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _errorText(error));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_canEdit) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    final procedencia = _procedenciaController.text.trim();

    try {
      await _request(
        'PATCH',
        data: {
          'nombre_completo': _nameController.text.trim(),
          'procedencia': procedencia,
          if (procedencia == 'Otra institución')
            'nombre_institucion': procedencia,
        },
      );

      if (!mounted) return;

      _showMessage('Perfil actualizado correctamente.');
      await _loadProfile();
    } catch (error) {
      _showMessage(_errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ============================================================
  // SESIÓN Y ELIMINACIÓN
  // ============================================================

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    bool danger = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            UnixTheme.watch(dialogContext);
            return AlertDialog(
              backgroundColor: _card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(title, style: TextStyle(color: UnixColors.text)),
              content: Text(
                message,
                style: TextStyle(color: _muted, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text('Cancelar', style: TextStyle(color: _muted)),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: danger ? _red : _orange,
                    foregroundColor: danger
                        ? Colors.white
                        : UnixColors.onOrange,
                  ),
                  child: Text(action),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _goToLogin() async {
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
      MaterialPageRoute(builder: (_) => AccessScreen()),
      (route) => false,
    );
  }

  Future<void> _logout() async {
    if (_busy || _loading) return;
    setState(() => _busy = true);

    try {
      final confirmed = await _confirm(
        title: 'Cerrar sesión',
        message: '¿Deseas salir de tu cuenta en este dispositivo?',
        action: 'Cerrar sesión',
      );

      if (!mounted || !confirmed) return;
      await _goToLogin();
    } catch (error) {
      _showMessage(_errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    if (!_canEdit) return;
    setState(() => _busy = true);

    try {
      final confirmed = await _confirm(
        title: '¿Eliminar tu cuenta?',
        message:
            'Tu cuenta será eliminada permanentemente. '
            'Esta acción no se puede deshacer. ¿Deseas continuar?',
        action: 'Eliminar cuenta',
        danger: true,
      );

      if (!mounted || !confirmed) return;

      await _request('DELETE');

      if (!mounted) return;
      await _goToLogin();
    } catch (error) {
      _showMessage(_errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ============================================================
  // DISEÑO RESPONSIVE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Container(
      color: _bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          UnixTheme.watch(context);
          final width = constraints.maxWidth;
          final mobile = width < 700;
          final tablet = width >= 700 && width < 1100;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              mobile ? 16 : 28,
              mobile ? 20 : 28,
              mobile ? 16 : 28,
              50,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1250),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Mi perfil',
                      style: TextStyle(
                        color: UnixColors.text,
                        fontSize: mobile ? 30 : 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Administra tu perfil y tu información personal.',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                    SizedBox(height: 22),
                    if (_loading) ...[
                      LinearProgressIndicator(
                        color: _orange,
                        backgroundColor: _field,
                      ),
                      SizedBox(height: 18),
                    ],
                    if (_error != null) ...[
                      _buildError(),
                      SizedBox(height: 18),
                    ],
                    if (mobile)
                      _buildMobileLayout()
                    else if (tablet)
                      _buildTabletLayout()
                    else
                      _buildDesktopLayout(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No se pudieron cargar los datos',
            style: TextStyle(color: _orange, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: _muted)),
          SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy || _loading ? null : _loadProfile,
            icon: Icon(Icons.refresh),
            label: Text('Reintentar'),
            style: OutlinedButton.styleFrom(foregroundColor: _orange),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 260, child: _buildProfileCard()),
        SizedBox(width: 18),
        Expanded(child: _buildPersonalInfo()),
        SizedBox(width: 18),
        SizedBox(
          width: 280,
          child: Column(
            children: [
              _buildSession(),
              SizedBox(height: 18),
              _buildDeleteAccount(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 240, child: _buildProfileCard()),
            SizedBox(width: 18),
            Expanded(child: _buildPersonalInfo()),
          ],
        ),
        SizedBox(height: 18),
        _buildSession(),
        SizedBox(height: 18),
        _buildDeleteAccount(),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildProfileCard(),
        SizedBox(height: 16),
        _buildPersonalInfo(),
        SizedBox(height: 16),
        _buildSession(),
        SizedBox(height: 16),
        _buildDeleteAccount(),
      ],
    );
  }

  // ============================================================
  // AVATAR Y DATOS DEL ALUMNO
  // ============================================================

  Widget _buildProfileCard() {
    final id = _dato('numero_control').trim();
    final nombre = _dato('nombre_completo').trim();

    return _panel(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Perfil',
              style: TextStyle(
                color: UnixColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: 22),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _border, width: 2),
            ),
            child: id.isEmpty
                ? SizedBox(
                    width: 105,
                    height: 105,
                    child: Icon(Icons.person_rounded, color: _muted, size: 62),
                  )
                : AnimatedBlobatar(
                    key: ValueKey(id),
                    name: id,
                    size: 105,
                    animation: BlobatarAnimation.always,
                  ),
          ),
          SizedBox(height: 15),
          Text(
            nombre.isEmpty ? 'Alumno' : nombre,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: UnixColors.text,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Alumno',
              style: TextStyle(color: _blue, fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(height: 12),
          SelectableText(
            'ID: ${id.isEmpty ? '—' : id}',
            textAlign: TextAlign.center,
            style: TextStyle(color: _green, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 24),
          Divider(color: _border),
          SizedBox(height: 14),
          Text(
            'Comunidad UNIX ITC',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORMULARIO
  // ============================================================

  Widget _buildPersonalInfo() {
    return _panel(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Información personal',
              style: TextStyle(
                color: UnixColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 22),
            _editableField(
              label: 'Nombre completo',
              controller: _nameController,
              icon: Icons.person_outline,
              maxLength: 255,
            ),
            SizedBox(height: 18),
            _readOnlyField(
              label: 'Rol',
              value: _dato('rol'),
              icon: Icons.badge_outlined,
            ),
            SizedBox(height: 18),
            _readOnlyField(
              label: 'Número de control / ID',
              value: _dato('numero_control'),
              icon: Icons.fingerprint,
            ),
            SizedBox(height: 18),
            _editableField(
              label: 'Institución de procedencia',
              controller: _procedenciaController,
              icon: Icons.school_outlined,
              maxLength: 100,
            ),
            SizedBox(height: 18),
            _buildGoogleAccount(),
            SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _canEdit ? _updateProfile : null,
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: UnixColors.onOrange,
                disabledBackgroundColor: _field,
                disabledForegroundColor: _muted,
                minimumSize: Size(0, 48),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: Icon(Icons.save_outlined, size: 20),
              label: Text(
                'Actualizar perfil',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (_busy) ...[
              SizedBox(height: 16),
              Center(
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
      ),
    );
  }

  Widget _editableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required int maxLength,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _canEdit,
      maxLength: maxLength,
      textCapitalization: TextCapitalization.words,
      style: TextStyle(color: UnixColors.text, fontSize: 13),
      cursorColor: _orange,
      decoration: _decoration(label, icon).copyWith(counterText: ''),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Completa este campo.';
        }
        return null;
      },
    );
  }

  Widget _readOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return TextFormField(
      key: ValueKey('$label:$value'),
      initialValue: value,
      readOnly: true,
      style: TextStyle(color: _muted, fontSize: 13),
      decoration: _decoration(label, icon).copyWith(
        suffixIcon: Icon(Icons.lock_outline_rounded, color: _muted, size: 18),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: TextStyle(color: _muted),
      filled: true,
      fillColor: _field,
      prefixIcon: Icon(icon, color: _muted, size: 21),
      enabledBorder: _inputBorder(_border),
      disabledBorder: _inputBorder(_border),
      focusedBorder: _inputBorder(_blue, width: 2),
      errorBorder: _inputBorder(_red),
      focusedErrorBorder: _inputBorder(_red, width: 2),
      errorStyle: TextStyle(color: _red),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _buildGoogleAccount() {
    final email = _dato('email').trim();

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: UnixColors.text,
            child: Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuenta vinculada con Google',
                  style: TextStyle(
                    color: UnixColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                SelectableText(
                  email.isEmpty ? 'Correo pendiente de cargar' : email,
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.lock_outline_rounded, color: _muted, size: 20),
        ],
      ),
    );
  }

  // ============================================================
  // TARJETAS DE CUENTA
  // ============================================================

  Widget _buildSession() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sesión',
            style: TextStyle(
              color: UnixColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Salir de tu cuenta en este dispositivo.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy || _loading ? null : _logout,
            icon: Icon(Icons.logout_rounded),
            label: Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: UnixColors.text,
              disabledForegroundColor: _muted,
              backgroundColor: _field,
              side: BorderSide(color: _border),
              minimumSize: Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccount() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _red.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Eliminar cuenta',
            style: TextStyle(
              color: UnixColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'La eliminación de tu cuenta es permanente '
            'y no se puede deshacer.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
          SizedBox(height: 17),
          OutlinedButton.icon(
            onPressed: _canEdit ? _deleteAccount : null,
            icon: Icon(Icons.delete_outline_rounded, size: 20),
            label: Text(
              'Eliminar cuenta',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _red,
              disabledForegroundColor: _muted,
              side: BorderSide(color: _canEdit ? _red : _border),
              minimumSize: Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }
}
