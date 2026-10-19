import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';

class InstructorPerfilPage extends StatefulWidget {
  const InstructorPerfilPage({super.key});

  @override
  State<InstructorPerfilPage> createState() =>
      _InstructorPerfilPageState();
}

class _InstructorPerfilPageState extends State<InstructorPerfilPage> {
  static const _bg = Color(0xFF031426);
  static const _card = Color(0xFF0A2947);
  static const _field = Color(0xFF0C3152);
  static const _border = Color(0xFF174064);
  static const _orange = Color(0xFFFF8A24);
  static const _blue = Color(0xFF2796FF);
  static const _red = Color(0xFFFF4D5A);
  static const _muted = Color(0xFF91A9BE);

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: 'Profesor');

  String _displayName = 'Profesor';
  bool _logoutBusy = false;
  bool _logoutDialogOpen = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text)),
      );
  }

  void _updateProfile() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _displayName = _nameController.text.trim();
      _nameController.text = _displayName;
    });

    // Conectar aquí la actualización del nombre con el backend.
    _message(
      'Nombre actualizado en esta pantalla. '
      'El guardado en el servidor está pendiente.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1050;
        final tablet = constraints.maxWidth >= 650;

        if (desktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 250,
                child: _profileCard(),
              ),
              const SizedBox(width: 18),
              Expanded(child: _personalInfo()),
              const SizedBox(width: 18),
              SizedBox(
                width: 280,
                child: _accountActions(),
              ),
            ],
          );
        }

        if (tablet) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 230,
                    child: _profileCard(),
                  ),
                  const SizedBox(width: 18),
                  Expanded(child: _personalInfo()),
                ],
              ),
              const SizedBox(height: 18),
              _accountActions(),
            ],
          );
        }

        return Column(
          children: [
            _profileCard(),
            const SizedBox(height: 16),
            _personalInfo(),
            const SizedBox(height: 16),
            _accountActions(),
          ],
        );
      },
    );
  }

  Widget _profileCard() {
    return _panel(
      title: 'Perfil del profesor',
      child: Column(
        children: [
          const SizedBox(height: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _field,
                  border: Border.all(
                    color: _border,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 65,
                ),
              ),
              Positioned(
                right: -4,
                bottom: 0,
                child: Material(
                  color: _blue,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Cambiar foto',
                    onPressed: () {
                      _message(
                        'El cambio de foto está pendiente de implementar.',
                      );
                    },
                    icon: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
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
              color: _blue,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 17,
                ),
                SizedBox(width: 7),
                Text(
                  'Profesor',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Divider(color: _border),
          const SizedBox(height: 12),
          const Text(
            'Comunidad UNIX ITC',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Consulta tus cursos, eventos y alumnos '
            'desde tu panel de instructor.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _personalInfo() {
    return _panel(
      title: 'Información personal',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nombre completo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              enabled: !_logoutBusy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _updateProfile(),
              style: const TextStyle(color: Colors.white),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Escribe tu nombre completo.';
                }
                return null;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: _field,
                hintText: 'Nombre del profesor',
                hintStyle: const TextStyle(color: _muted),
                enabledBorder: _inputBorder(_border),
                disabledBorder: _inputBorder(_border),
                focusedBorder: _inputBorder(_blue),
                errorBorder: _inputBorder(_red),
                focusedErrorBorder: _inputBorder(_red),
                errorStyle: const TextStyle(color: _red),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: Colors.white,
                    child: Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
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
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Correo pendiente de cargar',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.lock_outline_rounded,
                    color: _muted,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _logoutBusy ? null : _updateProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: _bg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                icon: const Icon(Icons.save_outlined),
                label: const Text(
                  'Actualizar perfil',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );
  }

  Widget _accountActions() {
    return Column(
      children: [
        _panel(
          title: 'Sesión',
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logoutBusy ? null : _confirmLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: _border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              icon: _logoutBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: _orange,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.logout_rounded),
              label: Text(
                _logoutBusy ? 'Cerrando sesión...' : 'Cerrar sesión',
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _panel(
          title: 'Eliminar cuenta',
          borderColor: _red,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'La eliminación de tu cuenta requiere '
                'confirmación y conexión con el servidor.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logoutBusy ? null : _confirmDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _red,
                    side: const BorderSide(color: _red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 15,
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Eliminar cuenta'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout() async {
    if (_logoutBusy || _logoutDialogOpen) return;

    _logoutDialogOpen = true;

    bool? confirmed;

    try {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: _card,
            title: const Text(
              '¿Cerrar sesión?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Se cerrará tu sesión en este dispositivo.',
              style: TextStyle(color: _muted),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: _bg,
                ),
                child: const Text('Cerrar sesión'),
              ),
            ],
          );
        },
      );
    } finally {
      _logoutDialogOpen = false;
    }

    if (!mounted || confirmed != true) return;

    setState(() => _logoutBusy = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      final tokenRemoved = await prefs.remove('jwt_token');
      final roleRemoved = await prefs.remove('user_rol');

      if (!tokenRemoved || !roleRemoved) {
        throw StateError('No se pudo limpiar la sesión guardada.');
      }
    } catch (error) {
      debugPrint('Error al limpiar la sesión: $error');

      if (!mounted) return;

      setState(() => _logoutBusy = false);
      _message('No se pudo cerrar la sesión. Inténtalo nuevamente.');
      return;
    }

    try {
      await GoogleSignIn.instance.signOut();
    } catch (error) {
      // La sesión local de la app ya se eliminó.
      debugPrint('No se pudo cerrar la sesión de Google: $error');
    }

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const AccessScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _confirmDelete() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _card,
          icon: const Icon(
            Icons.delete_forever_rounded,
            color: _red,
            size: 38,
          ),
          title: const Text(
            'Eliminar cuenta',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'La eliminación todavía no está conectada al servidor. '
            'No se eliminará ninguna cuenta desde esta pantalla.',
            style: TextStyle(color: _muted, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Widget _panel({
    required String title,
    required Widget child,
    Color borderColor = _border,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}