import 'package:flutter/material.dart';
import 'package:blobatar/flutter.dart';

/// Barra común de Instructor y Super Admin, siguiendo el diseño de Alumno.
class UnixAccountBar extends StatelessWidget {
  const UnixAccountBar({
    super.key,
    required this.nombre,
    required this.rol,
    required this.identificador,
    required this.search,
    required this.accountMenu,
    required this.onProfile,
    required this.onNotifications,
    this.leading,
    this.profileError,
    this.notificationsTooltip = 'Notificaciones',
  });

  final String nombre;
  final String rol;
  final String identificador;
  final Widget search;
  final Widget accountMenu;
  final Widget? leading;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;
  final String? profileError;
  final String notificationsTooltip;

  static const _surface = Color(0xFF061C31);
  static const _border = Color(0xFF174064);
  static const _muted = Color(0xFF91A9BE);

  Widget _avatar() => SizedBox(
    width: 40, height: 40,
    child: identificador.isEmpty
        ? const CircleAvatar(backgroundColor: Color(0xFF123451),
            child: Icon(Icons.person_rounded, color: Colors.white))
        : AnimatedBlobatar(
            key: ValueKey('avatar-$identificador-40'),
            name: identificador, size: 40,
            animation: BlobatarAnimation.always,
          ),
  );

  Widget _identity() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(nombre.isEmpty ? 'Mi cuenta' : nombre,
        maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(rol, style: const TextStyle(color: _muted, fontSize: 10)),
      const SizedBox(height: 3),
      Tooltip(message: profileError ?? (identificador.isEmpty ? 'El perfil no devuelve un ID.' : identificador),
        child: Text(identificador.isEmpty ? 'ID no disponible' : 'ID: $identificador',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: profileError == null ? const Color(0xFF6ED9AB) : const Color(0xFFFF6577), fontSize: 10))),
    ],
  );

  Widget _account(double width) => Row(mainAxisSize: MainAxisSize.min, children: [
    IconButton(tooltip: notificationsTooltip, onPressed: onNotifications,
      icon: const Icon(Icons.notifications_none_rounded, color: _muted)),
    const SizedBox(width: 8),
    Container(width: 1, height: 28, color: _border),
    const SizedBox(width: 12),
    InkWell(onTap: onProfile, borderRadius: BorderRadius.circular(22), child: _avatar()),
    const SizedBox(width: 10),
    SizedBox(width: width, child: _identity()),
    accountMenu,
  ]);

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final narrow = constraints.maxWidth < 620;
    final veryNarrow = constraints.maxWidth < 380;
    final identityWidth = narrow
        ? (constraints.maxWidth - (leading == null ? 184 : 232)).clamp(44.0, 160.0).toDouble()
        : (constraints.maxWidth < 850 ? 130.0 : 170.0);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 12 : 20, vertical: narrow ? 10 : 0),
      decoration: const BoxDecoration(color: _surface,
        border: Border(bottom: BorderSide(color: _border))),
      child: narrow
          ? Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                if (leading != null) leading!,
                if (!veryNarrow && leading == null)
                  const Icon(Icons.terminal_rounded, color: Color(0xFFFF8A24)),
                const Spacer(),
                _account(identityWidth),
              ]),
              const SizedBox(height: 8),
              SizedBox(height: 42, child: search),
            ])
          : SizedBox(height: 80, child: Row(children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Expanded(child: SizedBox(height: 42, child: search)),
              const SizedBox(width: 16),
              _account(identityWidth),
            ])),
    );
  });
}
