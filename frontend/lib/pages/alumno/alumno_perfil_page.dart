import 'package:flutter/material.dart';

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

  bool _editing = false;

  final TextEditingController _nameController =
      TextEditingController(text: 'Alumno');

  final TextEditingController _controlController =
      TextEditingController(text: '202600123');

  final TextEditingController _careerController =
      TextEditingController(text: 'Ingeniería en Sistemas');

  @override
  void dispose() {
    _nameController.dispose();
    _controlController.dispose();
    _careerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final mobile = width < 700;
          final tablet = width >= 700 && width < 1050;

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

  // ============================================================
  // HEADER
  // ============================================================

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
          style: TextStyle(
            color: _muted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LAYOUT DESKTOP
  // ============================================================

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 280,
          child: _buildProfileCard(),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _buildPersonalInfo(),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 320,
          child: Column(
            children: [
              
              _buildSession(),
              
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LAYOUT TABLET
  // ============================================================

  Widget _buildTabletLayout() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 280,
              child: _buildProfileCard(),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _buildPersonalInfo(),
            ),
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
  // LAYOUT MOBILE
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
  // PERFIL
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
                  border: Border.all(
                    color: _border,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 62,
                ),
              ),
              Positioned(
                right: -3,
                bottom: 2,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _blue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _card,
                      width: 3,
                    ),
                  ),
                  child: IconButton(
                    tooltip: 'Cambiar foto',
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                    icon: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'Alumno',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                SizedBox(width: 5),
                Text(
                  'Alumno',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _field,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 15,
                ),
                SizedBox(width: 6),
                Text(
                  'Nivel principiante',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
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

  // ============================================================
  // INFORMACIÓN PERSONAL
  // ============================================================

  Widget _buildPersonalInfo() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Información personal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Editar información',
                onPressed: () {
                  setState(() {
                    _editing = !_editing;
                  });
                },
                icon: Icon(
                  _editing
                      ? Icons.close_rounded
                      : Icons.edit_rounded,
                  color: _blue,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _fieldLabel('Nombre completo'),
          _profileField(
            controller: _nameController,
          ),
          const SizedBox(height: 14),
          _fieldLabel('Matrícula'),
          _profileField(
            controller: _controlController,
          ),
          const SizedBox(height: 14),
          _fieldLabel('Carrera'),
          _profileField(
            controller: _careerController,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _border,
              ),
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
                        style: TextStyle(
                          color: _muted,
                          fontSize: 10,
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
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _editing
                  ? () {
                      setState(() {
                        _editing = false;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Cambios guardados localmente en la interfaz.',
                          ),
                        ),
                      );
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                disabledBackgroundColor:
                    _orange.withValues(alpha: 0.45),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
              ),
              label: const Text(
                'Guardar cambios',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _profileField({
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      enabled: _editing,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: _field,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: _border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: _blue,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: _blue,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
      ),
    );
  }

  


  // ============================================================
  // SESIÓN
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
          InkWell(
            onTap: _showLogoutDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _field,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: _red,
                    size: 27,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cerrar sesión',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Se cerrará tu sesión en este dispositivo.',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BORRAR CUENTA
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
            'Borrar cuenta',
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
                  'Elimina tu perfil y tu progreso de forma permanente.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _showDeleteDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: _red,
                side: const BorderSide(
                  color: _red,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Borrar cuenta',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIÁLOGOS
  // ============================================================

  Future<void> _showLogoutDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(
              color: _border,
            ),
          ),
          title: const Text(
            '¿Cerrar sesión?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Esta acción cerrará tu sesión en este dispositivo.',
            style: TextStyle(
              color: _muted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
              ),
              child: const Text(
                'Cerrar sesión',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: _red.withValues(alpha: 0.7),
            ),
          ),
          icon: Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: _red.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: _red,
              size: 30,
            ),
          ),
          title: const Text(
            '¿Borrar tu cuenta?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Esta acción eliminaría tu perfil y tu progreso. '
            'No se puede deshacer.',
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
                Navigator.pop(dialogContext);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(
                  color: _border,
                ),
              ),
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Función de eliminación pendiente de conectar al backend.',
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Sí, borrar cuenta',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // PANEL
  // ============================================================

  Widget _panel({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _border,
        ),
      ),
      child: child,
    );
  }
}

// =================================================================
// ESTADÍSTICA
// =================================================================

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
          color: Color(0xFF2796FF),
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
            fontSize: 9,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}