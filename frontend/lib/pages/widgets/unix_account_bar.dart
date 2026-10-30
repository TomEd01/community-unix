import '../../theme/unix_theme.dart';
import 'package:flutter/material.dart';
import 'package:blobatar/flutter.dart';

/// Barra común de Instructor y Super Admin, siguiendo el diseño de Alumno.
class UnixAccountBar extends StatelessWidget {
  const UnixAccountBar({
    super.key,
    required this.nombre,
    required this.rol,
    required this.identificador,
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
  final Widget accountMenu;
  final Widget? leading;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;
  final String? profileError;
  final String notificationsTooltip;

  static Color get _surface => UnixColors.adapt(Color(0xFF061C31));
  static Color get _border => UnixColors.border;
  static Color get _muted => UnixColors.adapt(Color(0xFF91A9BE));

  Widget _avatar() => SizedBox(
    width: 40,
    height: 40,
    child: identificador.isEmpty
        ? CircleAvatar(
            backgroundColor: UnixColors.adapt(Color(0xFF123451)),
            child: Icon(Icons.person_rounded, color: UnixColors.text),
          )
        : AnimatedBlobatar(
            key: ValueKey('avatar-$identificador-40'),
            name: identificador,
            size: 40,
            animation: BlobatarAnimation.always,
          ),
  );

  Widget _identity() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        nombre.isEmpty ? 'Mi cuenta' : nombre,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: UnixColors.text,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      SizedBox(height: 3),
      Text(rol, style: TextStyle(color: _muted, fontSize: 10)),
      SizedBox(height: 3),
      Tooltip(
        message:
            profileError ??
            (identificador.isEmpty
                ? 'El perfil no devuelve un ID.'
                : identificador),
        child: Text(
          identificador.isEmpty ? 'ID no disponible' : 'ID: $identificador',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: profileError == null
                ? UnixColors.adapt(Color(0xFF6ED9AB))
                : UnixColors.adapt(Color(0xFFFF6577)),
            fontSize: 10,
          ),
        ),
      ),
    ],
  );

  Widget _account(double width, {bool compact = false, bool tiny = false}) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UnixThemeToggle(compact: compact),
          const SizedBox(width: 8),
          if (!tiny) ...[
            IconButton(
              tooltip: notificationsTooltip,
              onPressed: onNotifications,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              padding: const EdgeInsets.all(8),
              icon: Icon(Icons.notifications_none_rounded, color: _muted),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 28, color: _border),
            const SizedBox(width: 12),
          ],
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(22),
            child: _avatar(),
          ),
          if (!tiny && width > 0) ...[
            const SizedBox(width: 10),
            SizedBox(width: width, child: _identity()),
          ],
          accountMenu,
        ],
      );

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 620;
        final tiny = constraints.maxWidth < 380;
        final width = narrow
            ? (constraints.maxWidth - (leading == null ? 256 : 280))
                  .clamp(0.0, 130.0)
                  .toDouble()
            : (constraints.maxWidth < 850 ? 130.0 : 170.0);
        return Container(
          height: 70,
          padding: EdgeInsets.symmetric(horizontal: narrow ? 12 : 20),
          decoration: BoxDecoration(
            color: _surface,
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              if (leading != null) leading!,
              if (!narrow)
                Expanded(
                  child: Text(
                    'Comunidad UNIX ITC',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: UnixColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else ...[
                if (!tiny && leading == null)
                  const Icon(Icons.terminal_rounded, color: UnixColors.orange),
                const Spacer(),
              ],
              _account(width, compact: constraints.maxWidth < 1000, tiny: tiny),
            ],
          ),
        );
      },
    );
  }
}
