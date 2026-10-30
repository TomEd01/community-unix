import 'package:flutter/material.dart';
import 'unix_theme.dart';

class UnixRoleBrand extends StatelessWidget {
  const UnixRoleBrand({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Row(
      mainAxisAlignment: compact
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        const Text('🐧', style: TextStyle(fontSize: 29)),
        if (!compact) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Comunidad\nUNIX ITC',
              style: TextStyle(
                color: UnixColors.text,
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
