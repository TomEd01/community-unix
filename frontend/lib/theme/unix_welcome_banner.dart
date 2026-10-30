import 'package:flutter/material.dart';
import 'unix_theme.dart';

/// Bienvenida decorativa: no añade cifras ni datos de demostración.
class UnixWelcomeBanner extends StatelessWidget {
  const UnixWelcomeBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.terminal_rounded,
  });
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 550;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 20 : 26),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: UnixColors.dark
                  ? const [Color(0xFF0A2947), Color(0xFF123F62)]
                  : const [Color(0xFFEAF3FF), Color(0xFFD8EAFF)],
            ),
            border: Border.all(color: UnixColors.border.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: UnixColors.text,
                        fontSize: compact ? 25 : 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: UnixColors.muted,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 24),
                Transform.rotate(
                  angle: -0.04,
                  child: Container(
                    width: 112,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF061C31),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFF2796FF),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: UnixColors.orange, size: 46),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
