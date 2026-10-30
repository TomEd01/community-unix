import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:blobatar/flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import 'externo_config.dart';

class ExternoPerfilPage extends StatefulWidget {
  const ExternoPerfilPage({super.key});

  @override
  State<ExternoPerfilPage> createState() => _ExternoPerfilPageState();
}

class _ExternoPerfilPageState extends State<ExternoPerfilPage> {
  static const String _perfilUrl = ExternoConfig.perfilUrl;

  static const Color _bg = Color(0xFF031426);
  static const Color _card = Color(0xFF0A2947);
  static const Color _field = Color(0xFF0C3152);
  static const Color _border = Color(0xFF174064);
  static const Color _orange = Color(0xFFFF8A24);
  static const Color _blue = Color(0xFF2796FF);
  static const Color _red = Color(0xFFFF4D5A);
  static const Color _muted = Color(0xFF91A9BE);
  static const Color _green = Color(0xFF6ED9AB);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

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
              .timeout(const Duration(seconds: 20));
          break;

        case 'PATCH':
          response = await http
              .patch(
                uri,
                headers: headers,
                body: jsonEncode(data),
              )
              .timeout(const Duration(seconds: 20));
          break;

        case 'DELETE':
          response = await http
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
      throw Exception(
        'Tu sesión venció. Cierra sesión y vuelve a ingresar.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body['error'] ??
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

      if (data['rol']?.toString().trim().toLowerCase() != 'externo') {
        throw Exception(
          'La sesión actual no corresponde a un externo.',
        );
      }

      setState(() {
        _perfil = data;
        _nameController.text = _dato('nombre_completo');
        _loaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _errorText(error);
        _loaded = false;
      });
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


    try {
      await _request(
        'PATCH',
        data: {
          'nombre_completo': _nameController.text.trim(),
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
          builder: (dialogContext) => AlertDialog(
            backgroundColor: _card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              title,
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              message,
              style: const TextStyle(color: _muted, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: _muted),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: danger ? _red : _orange,
                  foregroundColor: danger ? Colors.white : _bg,
                ),
                child: Text(action),
              ),
            ],
          ),
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
      MaterialPageRoute(builder: (_) => const AccessScreen()),
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
    return Container(
      color: _bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
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
                constraints: const BoxConstraints(maxWidth: 1250),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Mi perfil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: mobile ? 30 : 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Administra tu perfil y tu información personal.',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                    const SizedBox(height: 22),
                    if (_loading) ...[
                      const LinearProgressIndicator(
                        color: _orange,
                        backgroundColor: _field,
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (_error != null) ...[
                      _buildError(),
                      const SizedBox(height: 18),
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
          const Text(
            'No se pudieron cargar los datos',
            style: TextStyle(
              color: _orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: _muted)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy || _loading ? null : _loadProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
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
        const SizedBox(width: 18),
        Expanded(child: _buildPersonalInfo()),
        const SizedBox(width: 18),
        SizedBox(
          width: 280,
          child: Column(
            children: [
              _buildSession(),
              const SizedBox(height: 18),
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
            const SizedBox(width: 18),
            Expanded(child: _buildPersonalInfo()),
          ],
        ),
        const SizedBox(height: 18),
        _buildSession(),
        const SizedBox(height: 18),
        _buildDeleteAccount(),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildProfileCard(),
        const SizedBox(height: 16),
        _buildPersonalInfo(),
        const SizedBox(height: 16),
        _buildSession(),
        const SizedBox(height: 16),
        _buildDeleteAccount(),
      ],
    );
  }

  // ============================================================
  // AVATAR Y DATOS DEL EXTERNO
  // ============================================================

  Widget _buildProfileCard() {
    final id = _dato('numero_control').trim();
    final seed = externoAvatarSeed(_perfil);
    final nombre = _dato('nombre_completo').trim();

    return _panel(
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _border, width: 2),
            ),
            child: seed.isEmpty
                ? const SizedBox(
                    width: 105,
                    height: 105,
                    child: Icon(
                      Icons.person_rounded,
                      color: _muted,
                      size: 62,
                    ),
                  )
                : AnimatedBlobatar(
                    key: ValueKey(seed),
                    name: seed,
                    size: 105,
                    animation: BlobatarAnimation.always,
                  ),
          ),
          const SizedBox(height: 15),
          Text(
            nombre.isEmpty ? 'Externo' : nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Externo',
              style: TextStyle(
                color: _blue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            id.isEmpty ? 'ID no disponible' : 'ID: $id',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _green,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: _border),
          const SizedBox(height: 14),
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
  // FORMULARIO
  // ============================================================

  Widget _buildPersonalInfo() {
    return _panel(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Información personal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 22),
            _editableField(
              label: 'Nombre completo',
              controller: _nameController,
              icon: Icons.person_outline,
              maxLength: 255,
            ),
            const SizedBox(height: 18),
            _readOnlyField(
              label: 'Rol',
              value: _dato('rol'),
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 18),
            _buildGoogleAccount(),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _canEdit ? _updateProfile : null,
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: _bg,
                disabledBackgroundColor: _field,
                disabledForegroundColor: _muted,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: const Icon(Icons.save_outlined, size: 20),
              label: const Text(
                'Actualizar perfil',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
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
      style: const TextStyle(color: Colors.white, fontSize: 13),
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
      style: const TextStyle(color: _muted, fontSize: 13),
      decoration: _decoration(label, icon).copyWith(
        suffixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: _muted,
          size: 18,
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(color: _muted),
      filled: true,
      fillColor: _field,
      prefixIcon: Icon(icon, color: _muted, size: 21),
      enabledBorder: _inputBorder(_border),
      disabledBorder: _inputBorder(_border),
      focusedBorder: _inputBorder(_blue, width: 2),
      errorBorder: _inputBorder(_red),
      focusedErrorBorder: _inputBorder(_red, width: 2),
      errorStyle: const TextStyle(color: _red),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 16,
      ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cuenta vinculada con Google',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                SelectableText(
                  email.isEmpty ? 'Correo pendiente de cargar' : email,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.lock_outline_rounded,
            color: _muted,
            size: 20,
          ),
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
          const Text(
            'Sesión',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Salir de tu cuenta en este dispositivo.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy || _loading ? null : _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: _muted,
              backgroundColor: _field,
              side: const BorderSide(color: _border),
              minimumSize: const Size(0, 48),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _red.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Eliminar cuenta',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'La eliminación de tu cuenta es permanente '
            'y no se puede deshacer.',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 17),
          OutlinedButton.icon(
            onPressed: _canEdit ? _deleteAccount : null,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            label: const Text(
              'Eliminar cuenta',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _red,
              disabledForegroundColor: _muted,
              side: BorderSide(color: _canEdit ? _red : _border),
              minimumSize: const Size(0, 48),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }
}
