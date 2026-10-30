import '../../theme/unix_theme.dart';
import 'package:flutter/material.dart';

class InstructorActividadesPage extends StatelessWidget {
  const InstructorActividadesPage({super.key});

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: UnixColors.adapt(Color(0xFF0A2947)),
        border: Border.all(color: Color(0xFF174064)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.assignment_ind_outlined,
            color: Color(0xFFFF8A24),
            size: 36,
          ),
          SizedBox(height: 16),
          Text(
            'Mis Actividades a Cargo',
            style: TextStyle(
              color: UnixColors.text,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Aquí podrás consultar las actividades en las que estés a cargo.',
            style: TextStyle(color: UnixColors.adapt(Color(0xFF91A9BE))),
          ),
          SizedBox(height: 8),
          Text(
            'Esta sección está preparada y todavía no consulta actividades del servidor.',
            style: TextStyle(color: UnixColors.adapt(Color(0xFF91A9BE))),
          ),
        ],
      ),
    );
  }
}
