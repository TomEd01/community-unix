import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';

class AlumnoPerfilPage extends StatefulWidget {
  const AlumnoPerfilPage({super.key});

  @override
  State<AlumnoPerfilPage> createState() => _AlumnoPerfilPageState();
}

class _AlumnoPerfilPageState extends State<AlumnoPerfilPage> {
  static const Color _bg = Color(0xFF031426);
  static const Color _card = Color(0xFF0A2947);
  static const Color _field = Color(0xFF0C3152);
  static const Color _border = Color(0xFF174064);
  static const Color _orange = Color(0xFFFF8A24);
  static const Color _blue = Color(0xFF2796FF);
  static const Color _red = Color(0xFFFF4D5A);
  static const Color _muted = Color(0xFF91A9BE);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController(text: 'Alumno');

  String _displayName = 'Alumno';
  bool _logoutInProgress = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  void _updateProfile() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _displayName = _nameController.text.trim();
      _nameController.text = _displayName;
    });

    // Pendiente: guardar el nombre mediante la API del backend.
    _showMessage(
      'Nombre actualizado en esta pantalla. '
      'El guardado en el servidor está pendiente.',
    );
  }

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(mobile),
                    const SizedBox(height: 22),
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

  Widget _buildHeader(bool mobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
      ],
    );
  }

  // ============================================================
  // DISTRIBUCIÓN PARA PC
  // ============================================================

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 260,
          child: _buildProfileCard(),
        ),
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

  // ============================================================
  // DISTRIBUCIÓN PARA TABLET
  // ============================================================

  Widget _buildTabletLayout() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 240,
              child: _buildProfileCard(),
            ),
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

  // ============================================================
  // DISTRIBUCIÓN PARA TELÉFONO
  // ============================================================

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
  // TARJETA DE PERFIL
  // ============================================================

  Widget _buildProfileCard() {
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 105,
                height: 105,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _field,
                  border: Border.all(color: _border, width: 3),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 62,
                ),
              ),
              Positioned(
                right: -5,
                bottom: 0,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: _card, width: 3),
                  ),
                  child: IconButton(
                    tooltip: 'Cambiar foto',
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _showMessage(
                        'El cambio de foto está pendiente de implementar.',
                      );
                    },
                    icon: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            _displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _buildBadge(
            text: 'Alumno',
            icon: Icons.person_rounded,
            color: _blue,
          ),
          const SizedBox(height: 9),
          _buildBadge(
            text: 'Nivel principiante',
            icon: Icons.bar_chart_rounded,
            color: _field,
          ),
          const SizedBox(height: 24),
          const Divider(color: _border),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Mi aprendizaje',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                child: _ProfileStat(
                  icon: Icons.menu_book_rounded,
                  value: '3',
                  label: 'Cursos\ninscritos',
                ),
              ),
              Expanded(
                child: _ProfileStat(
                  icon: Icons.workspace_premium_rounded,
                  value: '2',
                  label: 'Insignias\nobtenidas',
                ),
              ),
              Expanded(
                child: _ProfileStat(
                  icon: Icons.bar_chart_rounded,
                  value: 'Principiante',
                  label: 'Nivel actual',
                  smallValue: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String text,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMACIÓN PERSONAL
  // ============================================================

  Widget _buildPersonalInfo() {
    return _panel(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información personal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Nombre completo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _updateProfile(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Escribe tu nombre completo.';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Escribe tu nombre',
                hintStyle: const TextStyle(color: _muted),
                filled: true,
                fillColor: _field,
                enabledBorder: _inputBorder(_border),
                focusedBorder: _inputBorder(_blue, width: 2),
                errorBorder: _inputBorder(_red),
                focusedErrorBorder: _inputBorder(_red, width: 2),
                errorStyle: const TextStyle(color: _red),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildGoogleAccount(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _updateProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: _bg,
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

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _buildGoogleAccount() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 21,
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
                  'alumno@ejemplo.com',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Cuenta vinculada con Google',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Icon(
            Icons.lock_outline_rounded,
            color: _muted,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TARJETA DE SESIÓN
  // ============================================================

  Widget _buildSession() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Material(
            color: _field,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _logoutInProgress ? null : _showLogoutDialog,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    if (_logoutInProgress)
                      const SizedBox(
                        width: 27,
                        height: 27,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _orange,
                        ),
                      )
                    else
                      const Icon(
                        Icons.logout_rounded,
                        color: _muted,
                        size: 27,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _logoutInProgress
                                ? 'Cerrando sesión...'
                                : 'Cerrar sesión',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Salir de tu cuenta en este dispositivo.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CIERRE DE SESIÓN
  // ============================================================

  Future<void> _showLogoutDialog() async {
    if (_logoutInProgress) return;

    // Bloquea aperturas repetidas mientras el diálogo está visible.
    setState(() => _logoutInProgress = true);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _card,
          title: const Text(
            '¿Cerrar sesión?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '¿Deseas salir de tu cuenta en este dispositivo?',
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

    if (!mounted) return;

    if (confirmed != true) {
      setState(() => _logoutInProgress = false);
      return;
    }

    try {
      // Borra únicamente los datos de sesión de la aplicación.
      final prefs = await SharedPreferences.getInstance();

      final tokenRemoved = await prefs.remove('jwt_token');
      final roleRemoved = await prefs.remove('user_rol');

      if (!tokenRemoved || !roleRemoved) {
        throw StateError('No se pudo limpiar la sesión guardada.');
      }
    } catch (error) {
      debugPrint('Error al limpiar la sesión: $error');

      if (!mounted) return;

      setState(() => _logoutInProgress = false);

      _showMessage(
        'No se pudo cerrar la sesión. Inténtalo nuevamente.',
      );
      return;
    }

    try {
      await GoogleSignIn.instance.signOut();
    } catch (error) {
      // Aunque Google falle, la sesión local ya fue eliminada.
      debugPrint('No se pudo cerrar la sesión de Google: $error');
    }

    if (!mounted) return;

    // Abre el acceso y elimina las pantallas anteriores.
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const AccessScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // ELIMINAR CUENTA
  // ============================================================

  Widget _buildDeleteAccount() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _red.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: _red,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Solicita la eliminación permanente de tu perfil '
                  'y tu progreso.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logoutInProgress ? null : _showDeleteDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: _red,
                side: const BorderSide(color: _red),
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
              ),
              label: const Text(
                'Eliminar cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _red),
          ),
          icon: const Icon(
            Icons.delete_forever_rounded,
            color: _red,
            size: 38,
          ),
          title: const Text(
            '¿Eliminar tu cuenta?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'La eliminación de la cuenta y su progreso sería permanente.\n\n'
            'Esta opción todavía no está conectada al servidor; '
            'confirmar no eliminará datos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              height: 1.4,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: _border),
              ),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: _bg,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    // Pendiente: solicitar la eliminación al backend.
    _showMessage(
      'No se eliminó ninguna cuenta. '
      'Falta conectar esta función al backend.',
    );
  }

  // ============================================================
  // CONTENEDOR DE TARJETAS
  // ============================================================

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

// ================================================================
// ESTADÍSTICAS DE EJEMPLO
// ================================================================

class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool smallValue;

  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 3),
        Icon(
          icon,
          color: const Color(0xFF2796FF),
          size: 25,
        ),
        const SizedBox(height: 7),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: smallValue ? 10 : 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF91A9BE),
            fontSize: 10,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}