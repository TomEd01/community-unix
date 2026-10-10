import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main.dart'; // Para poder navegar a AccessScreen

class AlumnoPage extends StatelessWidget {
  const AlumnoPage({super.key});

  static const Color background = Color(0xFF050C1D);
  static const Color card = Color(0xFF081329);
  static const Color border = Color(0xFF34425C);
  static const Color primary = Color(0xFF2F7BFF);
  static const Color textSecondary = Color(0xFF929DB2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: card,
        title: const Text('Comunidad UNIX ITC'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              // Abrimos la memoria del teléfono
              final prefs = await SharedPreferences.getInstance();

              // Borramos absolutamente todo (Token y Rol)
              await prefs.clear();

              // Cerramos la sesión activa de Google en el navegador
              try {
                await GoogleSignIn.instance.signOut();
              } catch (_) {
                // Si falla porque ya estaba cerrada, lo ignoramos silenciosamente
              }

              // Verificamos que el widget siga activo antes de navegar
              if (!context.mounted) return;

              // Navegamos al Login destruyendo el historial hacia atrás
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AccessScreen()),
                (Route<dynamic> route) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Bienvenido, Alumno! 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Este es tu espacio dentro de la Comunidad UNIX ITC.',
                  style: TextStyle(color: textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 35),

                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: const [
                    _AlumnoCard(
                      icon: Icons.person_outline,
                      title: 'Mi perfil',
                      description:
                          'Consulta y actualiza la información de tu perfil.',
                    ),
                    _AlumnoCard(
                      icon: Icons.school_outlined,
                      title: 'Cursos',
                      description:
                          'Consulta los cursos disponibles para la comunidad.',
                    ),
                    _AlumnoCard(
                      icon: Icons.event_outlined,
                      title: 'Eventos',
                      description: 'Conoce los próximos eventos y actividades.',
                    ),
                    _AlumnoCard(
                      icon: Icons.menu_book_outlined,
                      title: 'Recursos',
                      description:
                          'Accede a material y recursos sobre Linux y UNIX.',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlumnoCard extends StatelessWidget {
  const _AlumnoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      height: 180,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AlumnoPage.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AlumnoPage.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Icon(icon, color: AlumnoPage.primary, size: 31),
          const SizedBox(height: 17),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            style: const TextStyle(
              color: AlumnoPage.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
