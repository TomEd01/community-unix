import 'api.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/unix_theme.dart';

const portalOrange = Color(0xFFFF8A24);
Widget panel({
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsets.all(20),
}) => Container(
  padding: padding,
  decoration: BoxDecoration(
    color: UnixColors.card,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: UnixColors.border),
  ),
  child: child,
);
Widget heading(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: Text(
    text,
    style: TextStyle(
      color: UnixColors.text,
      fontWeight: FontWeight.w800,
      fontSize: 23,
    ),
  ),
);
Widget muted(String text) =>
    Text(text, style: TextStyle(color: UnixColors.muted));
Widget badge(String text) => Chip(
  label: Text(text, style: TextStyle(color: UnixColors.link, fontSize: 12)),
  backgroundColor: UnixColors.selected,
  side: BorderSide.none,
);
void notice(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
Future<void> openPortalLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !['http', 'https'].contains(uri.scheme)) {
    notice(context, 'Enlace no válido.');
    return;
  }
  try {
    if (!await launchUrl(uri, mode: LaunchMode.platformDefault) &&
        context.mounted) {
      notice(context, 'No se pudo abrir el enlace.');
    }
  } catch (_) {
    if (context.mounted) notice(context, 'No se pudo abrir el enlace.');
  }
}

Widget errorPanel(String error, VoidCallback retry) => panel(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(error, style: const TextStyle(color: Colors.red)),
      TextButton.icon(
        onPressed: retry,
        icon: const Icon(Icons.refresh),
        label: const Text('Reintentar'),
      ),
    ],
  ),
);
Widget emptyPanel(String message) => panel(
  child: Row(
    children: [
      Icon(Icons.info_outline, color: UnixColors.muted),
      const SizedBox(width: 12),
      Expanded(child: muted(message)),
    ],
  ),
);

class PortalScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const PortalScaffold({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Scaffold(
      backgroundColor: UnixColors.background,
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [portalDataNotice(), child],
            ),
          ),
        ),
      ),
    );
  }
}

Widget portalDataNotice() => !PortalApi.useExamples
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          'Datos de ejemplo · Solo pruebas de interfaz · No se guardan en el servidor',
          style: TextStyle(color: UnixColors.muted, fontSize: 12),
        ),
      );
