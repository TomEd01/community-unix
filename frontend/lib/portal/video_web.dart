import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'ui.dart';

class PortalVideo extends StatefulWidget {
  final String url, embed;
  const PortalVideo({super.key, required this.url, required this.embed});
  @override
  State<PortalVideo> createState() => _PortalVideoState();
}

class _PortalVideoState extends State<PortalVideo> {
  static int _next = 0;
  late String _view;
  void register() {
    _view = 'portal-video-${_next++}';
    ui.platformViewRegistry.registerViewFactory(_view, (id) {
      final frame = web.HTMLIFrameElement()
        ..src = widget.embed
        ..title = 'Video externo'
        ..allow = 'fullscreen; encrypted-media; picture-in-picture';
      frame.style
        ..border = '0'
        ..width = '100%'
        ..height = '100%';
      frame.referrerPolicy = 'strict-origin-when-cross-origin';
      return frame;
    });
  }

  @override
  void initState() {
    super.initState();
    register();
  }

  @override
  void didUpdateWidget(covariant PortalVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embed != widget.embed) register();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AspectRatio(
        aspectRatio: 16 / 9,
        child: HtmlElementView(key: ValueKey(_view), viewType: _view),
      ),
      TextButton.icon(
        onPressed: () => openPortalLink(context, widget.url),
        icon: const Icon(Icons.open_in_new),
        label: const Text('Abrir en plataforma'),
      ),
    ],
  );
}
