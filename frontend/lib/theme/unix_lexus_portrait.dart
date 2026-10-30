import 'package:flutter/material.dart';

/// La imagen base deja las pupilas vacías para dibujar la mirada por encima.
/// Imagen y pintura comparten siempre el lienzo original de 300 × 440.
class UnixLexusPortrait extends StatelessWidget {
  const UnixLexusPortrait({
    super.key,
    this.width = 180,
    this.pupilOffset = Offset.zero,
    this.blink = false,
  });
  final double width;
  final Offset pupilOffset;
  final bool blink;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Lexus, mascota de Comunidad UNIX ITC',
    child: SizedBox(
      width: width,
      height: width * 440 / 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            blink ? 'assets/lexus_blink.png' : 'assets/lexus_base.png',
            fit: BoxFit.fill,
            errorBuilder: (_, error, stackTrace) => const Center(
              child: Icon(
                Icons.school_outlined,
                size: 90,
                color: Color(0xFF2796FF),
              ),
            ),
          ),
          if (!blink)
            IgnorePointer(
              child: CustomPaint(painter: LexusPupilPainter(pupilOffset)),
            ),
        ],
      ),
    ),
  );
}

class LexusPupilPainter extends CustomPainter {
  const LexusPupilPainter([this.offset = Offset.zero]);
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300, size.height / 440);
    final direction = offset.distance > 8
        ? offset / offset.distance * 8
        : offset;
    for (final center in const [Offset(120, 152), Offset(180, 152)]) {
      final eye = center + direction;
      canvas.drawCircle(eye, 13, Paint()..color = const Color(0xFF08111F));
      canvas.drawCircle(eye, 10, Paint()..color = const Color(0xFF0D1A30));
      canvas.drawCircle(eye, 6.5, Paint()..color = const Color(0xFF030A15));
      canvas.drawCircle(
        eye + const Offset(-4, -4),
        3.2,
        Paint()..color = const Color(0xE6FFFFFF),
      );
      canvas.drawCircle(
        eye + const Offset(4, 4),
        1.5,
        Paint()..color = const Color(0x73FFFFFF),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LexusPupilPainter oldDelegate) =>
      oldDelegate.offset != offset;
}
