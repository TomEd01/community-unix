import 'package:flutter/material.dart';
import '../../theme/unix_theme.dart';

class UnixNotifications extends StatefulWidget {
  final bool showExamples;

  const UnixNotifications({
    super.key,
    this.showExamples = false,
  });

  @override
  State<UnixNotifications> createState() =>
      _UnixNotificationsState();
}

class _UnixNotificationsState
    extends State<UnixNotifications> {

  final GlobalKey _bellKey = GlobalKey();

  late final List<Map<String, dynamic>> _notifications;

  bool _onlyUnread = false;

  @override
  void initState() {
    super.initState();

    _notifications = widget.showExamples
        ? [
            {
              'tipo': 'evento',
              'titulo': 'Recordatorio de evento',
              'mensaje': 'Linux Install Fest comienza mañana.',
              'tiempo': 'Hace 10 min',
              'leida': false,
            },
            {
              'tipo': 'taller',
              'titulo': 'Próximo taller',
              'mensaje': 'Recuerda tu próximo taller de Python.',
              'tiempo': 'Hace 30 min',
              'leida': false,
            },
            {
              'tipo': 'solicitud',
              'titulo': 'Solicitud aprobada',
              'mensaje': 'Tu solicitud para ser expositor fue aceptada.',
              'tiempo': 'Hace 1 hora',
              'leida': false,
            },
            {
              'tipo': 'invitacion',
              'titulo': 'Invitación de Super Admin',
              'mensaje': 'Has recibido una invitación para ser administrador.',
              'tiempo': 'Hace 2 horas',
              'leida': false,
              'respuesta': 'pendiente',
            },
          ]
        : [];
  }

  int get _unreadCount => _notifications
      .where((n) => n['leida'] == false)
      .length;

  IconData _notificationIcon(String type) {
    return switch (type) {
      'evento' => Icons.event_rounded,
      'taller' => Icons.school_rounded,
      'foro' => Icons.co_present_outlined,
      'solicitud' => Icons.check_circle_outline,
      'invitacion' => Icons.admin_panel_settings_outlined,
      _ => Icons.notifications_outlined,
    };
  }

  // ABRIR PANEL FLOTANTE

  Future<void> _openNotifications() async {
    final box = _bellKey.currentContext!
        .findRenderObject() as RenderBox;

    final position = box.localToGlobal(Offset.zero);

    final screen = MediaQuery.sizeOf(context);

    final top = position.dy + box.size.height + 8;

    final right = (
      screen.width - position.dx - box.size.width
    ).clamp(12.0, screen.width - 12).toDouble();

    final width = (screen.width - 24)
        .clamp(0.0, 390.0)
        .toDouble();

    final height = (screen.height - top - 16)
        .clamp(100.0, 580.0)
        .toDouble();

    await showDialog<void>(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.transparent,

      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, updatePanel) {
            final notifications = _notifications
                .where(
                  (n) =>
                      !_onlyUnread || n['leida'] == false,
                )
                .toList();

            return Dialog(
              alignment: Alignment.topRight,

              insetPadding: EdgeInsets.only(
                top: top,
                right: screen.width < 650 ? 12 : right,
                left: 12,
                bottom: 12,
              ),

              backgroundColor: UnixColors.surface,

              elevation: 15,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: UnixColors.border,
                ),
              ),

              child: SizedBox(
                width: width,

                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: height,
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(18),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        // ENCABEZADO

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Notificaciones',
                                style: TextStyle(
                                  color: UnixColors.text,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            IconButton(
                              tooltip: 'Cerrar',
                              onPressed: () =>
                                  Navigator.pop(dialogContext),

                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),

                        if (widget.showExamples)
                          Text(
                            'Datos de ejemplo',
                            style: TextStyle(
                              color: UnixColors.muted,
                              fontSize: 12,
                            ),
                          ),

                        const SizedBox(height: 12),

                        // FILTROS

                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Todas'),
                              selected: !_onlyUnread,

                              onSelected: (_) {
                                updatePanel(() {
                                  _onlyUnread = false;
                                });
                              },
                            ),

                            ChoiceChip(
                              label: const Text('No leídas'),
                              selected: _onlyUnread,

                              onSelected: (_) {
                                updatePanel(() {
                                  _onlyUnread = true;
                                });
                              },
                            ),
                          ],
                        ),

                        if (_unreadCount > 0)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                for (final n in _notifications) {
                                  n['leida'] = true;
                                }
                              });

                              updatePanel(() {});
                            },

                            child: const Text(
                              'Marcar todas como leídas',
                            ),
                          ),

                        const Divider(),

                        // SIN NOTIFICACIONES

                        if (notifications.isEmpty)
                          Flexible(
                            child: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(24),

                                child: Column(
                                  mainAxisSize: MainAxisSize.min,

                                  children: [
                                    Icon(
                                      Icons.notifications_off_outlined,
                                      size: 58,
                                      color: UnixColors.muted,
                                    ),

                                    const SizedBox(height: 16),

                                    Text(
                                      'No tienes notificaciones',
                                      textAlign: TextAlign.center,

                                      style: TextStyle(
                                        color: UnixColors.text,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      'Aquí aparecerán tus avisos, '
                                      'recordatorios e invitaciones.',
                                      textAlign: TextAlign.center,

                                      style: TextStyle(
                                        color: UnixColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )

                        // LISTA DE NOTIFICACIONES

                        else
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,

                              itemCount: notifications.length,

                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),

                              itemBuilder: (context, index) {
                                final n = notifications[index];

                                return Container(
                                  padding: const EdgeInsets.all(12),

                                  decoration: BoxDecoration(
                                    color: n['leida'] == false
                                        ? UnixColors.selected
                                        : UnixColors.card,

                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),

                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      ListTile(
                                        contentPadding:
                                            EdgeInsets.zero,

                                        leading: CircleAvatar(
                                          backgroundColor:
                                              UnixColors.orange,

                                          child: Icon(
                                            _notificationIcon(
                                              n['tipo'],
                                            ),
                                            color: Colors.white,
                                          ),
                                        ),

                                        title: Text(
                                          n['titulo'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,

                                          children: [
                                            const SizedBox(height: 5),

                                            Text(n['mensaje']),

                                            const SizedBox(height: 5),

                                            Text(
                                              n['tiempo'],

                                              style: TextStyle(
                                                color: UnixColors.orange,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),

                                        trailing: n['leida'] == false
                                            ? const Icon(
                                                Icons.circle,
                                                color: Colors.blue,
                                                size: 10,
                                              )
                                            : null,

                                        onTap: () {
                                          setState(() {
                                            n['leida'] = true;
                                          });

                                          updatePanel(() {});
                                        },
                                      ),

                                      // INVITACIONES

                                      if (n['tipo'] == 'invitacion' &&
                                          n['respuesta'] == 'pendiente')
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,

                                          children: [
                                            FilledButton(
                                              onPressed: () {
                                                setState(() {
                                                  n['respuesta'] =
                                                      'aceptada';
                                                  n['leida'] = true;
                                                });

                                                updatePanel(() {});
                                              },

                                              child: const Text(
                                                'Aceptar',
                                              ),
                                            ),

                                            OutlinedButton(
                                              onPressed: () {
                                                setState(() {
                                                  n['respuesta'] =
                                                      'rechazada';
                                                  n['leida'] = true;
                                                });

                                                updatePanel(() {});
                                              },

                                              child: const Text(
                                                'Rechazar',
                                              ),
                                            ),
                                          ],
                                        ),

                                      if (n['tipo'] == 'invitacion' &&
                                          n['respuesta'] != 'pendiente')
                                        Text(
                                          'Respuesta de prueba: '
                                          '${n['respuesta']}',

                                          style: TextStyle(
                                            color: UnixColors.muted,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);

    return Stack(
      key: _bellKey,
      clipBehavior: Clip.none,

      children: [
        IconButton(
          tooltip: 'Notificaciones',

          onPressed: _openNotifications,

          icon: Icon(
            Icons.notifications_none_rounded,
            color: UnixColors.muted,
          ),
        ),

        if (_unreadCount > 0)
          Positioned(
            top: 2,
            right: 2,

            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(4),

                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),

                child: Text(
                  '$_unreadCount',

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}