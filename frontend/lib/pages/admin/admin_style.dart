import 'package:flutter/material.dart';

class AdminStyle {
  static const background = Color(0xFF031426);
  static const surface = Color(0xFF061C31);
  static const card = Color(0xFF0A2947);
  static const border = Color(0xFF174064);
  static const orange = Color(0xFFFF8A24);
  static const muted = Color(0xFF91A9BE);
  static const green = Color(0xFF53D39A);
  static const red = Color(0xFFFF6577);
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(primary: orange, surface: surface),
    dividerColor: border,
    appBarTheme: const AppBarTheme(backgroundColor: surface),
    dialogTheme: const DialogThemeData(backgroundColor: surface),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: background,
      labelStyle: const TextStyle(color: muted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      backgroundColor: orange, foregroundColor: background,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    )),
  );
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key, required this.title, required this.child, this.action});
  final String title;
  final Widget child;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: AdminStyle.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AdminStyle.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center,
        children: [Text(title, style: const TextStyle(fontSize: 18,
          fontWeight: FontWeight.bold)), if (action != null) action!]),
      const SizedBox(height: 16), child,
    ]),
  );
}

class AdminBadge extends StatelessWidget {
  const AdminBadge(this.text, {super.key, this.color = AdminStyle.orange});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withAlpha(28),
      borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(color: color, fontSize: 12,
      fontWeight: FontWeight.w600)),
  );
}

void adminMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
