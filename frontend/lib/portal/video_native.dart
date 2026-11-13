import 'package:flutter/material.dart';
import 'ui.dart';

class PortalVideo extends StatelessWidget {
  final String url, embed;
  const PortalVideo({super.key, required this.url, required this.embed});
  @override
  Widget build(BuildContext context) => panel(
    child: Column(
      children: [
        const Icon(Icons.play_circle_outline, size: 64),
        const SizedBox(height: 12),
        const Text('Video alojado en su plataforma original'),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => openPortalLink(context, url),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Ver video'),
        ),
      ],
    ),
  );
}
