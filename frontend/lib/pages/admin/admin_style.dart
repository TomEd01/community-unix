import '../../theme/unix_theme.dart';
import 'package:flutter/material.dart';

class AdminStyle {
  static Color get background => UnixColors.adapt(Color(0xFF031426));
  static Color get surface => UnixColors.adapt(Color(0xFF061C31));
  static Color get card => UnixColors.adapt(Color(0xFF0A2947));
  static Color get border => UnixColors.border;
  static const orange = Color(0xFFFF8A24);
  static Color get muted => UnixColors.adapt(Color(0xFF91A9BE));
  static Color get green => UnixColors.adapt(Color(0xFF53D39A));
  static Color get red => UnixColors.adapt(Color(0xFFFF6577));
  static ThemeData get theme => UnixThemes.current;
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });
  final String title;
  final Widget child;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminStyle.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminStyle.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (action != null) action!,
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class AdminBadge extends StatelessWidget {
  const AdminBadge(this.text, {super.key, this.color = AdminStyle.orange});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

void adminMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
