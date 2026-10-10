import 'package:flutter/material.dart';

class InstructorPage extends StatelessWidget {
  const InstructorPage({super.key});

  static const Color background = Color(0xFF050C1D);
  static const Color card = Color(0xFF081329);
  static const Color border = Color(0xFF34425C);
  static const Color primary = Color(0xFFF28A3A);
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
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
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
                  '¡Bienvenido, Instructor! 👨‍🏫',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Administra tu participación dentro de la Comunidad UNIX ITC.',
                  style: TextStyle(color: textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 35),

                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: const [
                    _InstructorCard(
                      icon: Icons.person_outline,
                      title: 'Mi perfil',
                      description: 'Consulta tu información como instructor.',
                    ),
                    _InstructorCard(
                      icon: Icons.co_present_outlined,
                      title: 'Mis cursos',
                      description: 'Consulta los cursos en los que participas.',
                    ),
                    _InstructorCard(
                      icon: Icons.groups_outlined,
                      title: 'Comunidad',
                      description: 'Consulta información de la comunidad.',
                    ),
                    _InstructorCard(
                      icon: Icons.event_available_outlined,
                      title: 'Actividades',
                      description: 'Consulta eventos y próximas actividades.',
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

class _InstructorCard extends StatelessWidget {
  const _InstructorCard({
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
        color: InstructorPage.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: InstructorPage.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: InstructorPage.primary, size: 31),
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
              color: InstructorPage.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
