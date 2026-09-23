import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ComunidadApp());

const ink = Color(0xFF080C18);
const orange = Color(0xFFF97316);
const muted = Color(0xFF9899A8);
const white = Colors.white;

enum AccessTab { signin, signup }
enum Role { alumno, instructor, externo }
enum Experience { sector, propia }

class ComunidadApp extends StatelessWidget {
  const ComunidadApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Comunidad Unix ITC',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: ink,
          colorScheme: ColorScheme.fromSeed(seedColor: orange, brightness: Brightness.dark),
          textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 14, color: white)),
          splashFactory: NoSplash.splashFactory,
        ),
        home: const AccessScreen(),
      );
}

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key});
  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  AccessTab tab = AccessTab.signin;
  Role role = Role.alumno;
  Experience? experience;
  String? institution;
  String? degree;
  bool sensitiveFocused = false;
  Offset pupil = Offset.zero;
  Offset targetPupil = Offset.zero;
  bool blink = false;
  Timer? blinkTimer;
  Timer? unblinkTimer;
  Timer? eyeTimer;

  @override
  void initState() {
    super.initState();
    eyeTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || sensitiveFocused || (pupil - targetPupil).distance < 0.03) return;
      setState(() => pupil = Offset.lerp(pupil, targetPupil, 0.14)!);
    });
    blinkTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || sensitiveFocused) return;
      setState(() => blink = true);
      unblinkTimer?.cancel();
      unblinkTimer = Timer(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => blink = false);
      });
    });
  }

  @override
  void dispose() {
    blinkTimer?.cancel();
    unblinkTimer?.cancel();
    eyeTimer?.cancel();
    super.dispose();
  }

  void switchTab(AccessTab value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() { tab = value; sensitiveFocused = false; });
  }

  void switchRole(Role value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() { role = value; sensitiveFocused = false; });
  }

  TextStyle style(double size, {Color color = white, FontWeight weight = FontWeight.w400}) =>
      TextStyle(fontSize: size, color: color, fontWeight: weight, height: 1.25);

  Widget gap(double h) => SizedBox(height: h);

  Widget field(String label, String placeholder, {bool sensitive = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: style(13, color: muted, weight: FontWeight.w500)),
        gap(8),
        Focus(
          onFocusChange: sensitive ? (focus) => setState(() => sensitiveFocused = focus) : null,
          child: TextField(
            style: style(14),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: style(14, color: const Color(0xFF9997A8)),
              filled: true,
              fillColor: const Color(0xFF222033),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3A394C))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: orange)),
            ),
          ),
        ),
      ]);

  Widget dropdown(String label, String? value, List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: style(13, color: muted, weight: FontWeight.w500)),
        gap(8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF222033),
          hint: Text('Selecciona una opción', style: style(14, color: muted)),
          decoration: InputDecoration(
            filled: true, fillColor: const Color(0xFF222033),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3A394C))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: orange)),
          ),
          items: items, onChanged: onChanged,
        ),
      ]);

  Widget roleCard(Role option, IconData icon, String name) {
    final selected = role == option;
    return Expanded(child: InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () => switchRole(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: selected ? const LinearGradient(colors: [Color(0xFF4D2B36), Color(0xFF342748)]) : null,
          color: selected ? null : const Color(0xFF232035),
          border: Border.all(color: selected ? orange : const Color(0xFF403A51)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: selected ? white : muted, size: 22),
          gap(6), Text(name, style: style(12, color: selected ? white : muted, weight: FontWeight.w600)),
        ]),
      ),
    ));
  }

  Widget experienceChoice(Experience choice, String label) {
    final selected = experience == choice;
    return InkWell(
      onTap: () => setState(() => experience = choice),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3B2935) : const Color(0xFF222033),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? orange : const Color(0xFF3A394C)),
        ),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? orange : muted, size: 18),
          const SizedBox(width: 12), Text(label, style: style(14)),
        ]),
      ),
    );
  }

  Widget form() {
    if (tab == AccessTab.signin) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Selecciona tu tipo de registro', style: style(13, color: muted)), gap(10),
      Row(children: [
        roleCard(Role.alumno, Icons.school_outlined, 'Alumno'), const SizedBox(width: 8),
        roleCard(Role.instructor, Icons.co_present_outlined, 'Instructor'), const SizedBox(width: 8),
        roleCard(Role.externo, Icons.people_outline, 'Externo'),
      ]),
      gap(24), field('Nombre completo *', 'Tu nombre completo'), gap(16),
      if (role == Role.alumno || role == Role.instructor) ...[
        field(role == Role.alumno ? 'ID / número de control *' : 'Matrícula del instructor *',
            role == Role.alumno ? 'Ej. 21040123' : 'Tu matrícula', sensitive: true),
        gap(16),
        dropdown('Procedencia / Institución *', institution, const [
          DropdownMenuItem(value: 'itc', child: Text('Instituto Tecnológico de Cancún')),
          DropdownMenuItem(value: 'otra', child: Text('Otra institución')),
        ], (v) => setState(() => institution = v)),
        gap(16),
      ],
      if (role == Role.instructor) ...[
        field('Departamento / Academia *', 'Ej. Academia de Sistemas'), gap(16),
        field('Especialidad / Área de conocimiento *', 'Ej. Desarrollo de Software'), gap(16),
        dropdown('Grado académico / Título *', degree, const [
          DropdownMenuItem(value: 'mtro', child: Text('Mtro.')),
          DropdownMenuItem(value: 'dr', child: Text('Dr.')),
          DropdownMenuItem(value: 'ing', child: Text('Ing.')),
          DropdownMenuItem(value: 'lic', child: Text('Lic.')),
          DropdownMenuItem(value: 'otro', child: Text('Otro (escribe cuál)')),
        ], (v) => setState(() => degree = v)),
        gap(16),
        if (degree == 'otro') ...[field('Especifica tu grado o título *', 'Escribe tu grado o título'), gap(16)],
      ],
      if (role == Role.externo) ...[
        Text('Tipo de experiencia *', style: style(13, color: muted, weight: FontWeight.w500)),
        gap(9), experienceChoice(Experience.sector, 'Trabajo en el sector'), gap(8),
        experienceChoice(Experience.propia, 'Experiencia propia'), gap(16),
        if (experience == Experience.sector) ...[
          field('Organización / procedencia *', 'Escribe tu organización o procedencia'), gap(16),
        ],
      ],
    ]);
  }

  Widget tabSwitcher() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: const Color(0xFF242036), borderRadius: BorderRadius.circular(13)),
        child: Row(children: [
          for (final item in AccessTab.values)
            Expanded(child: InkWell(
              onTap: () => switchTab(item), borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: tab == item ? const LinearGradient(colors: [Color(0xFF59343A), Color(0xFF3D2B55)]) : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(item == AccessTab.signin ? 'Iniciar sesión' : 'Registrarse',
                    style: style(13, color: tab == item ? white : muted, weight: FontWeight.w600)),
              ),
            )),
        ]),
      );

  Widget leftPanel(double availableWidth, double height) {
    final showToucan = availableWidth > 750;
    return Container(
      constraints: BoxConstraints(minHeight: height),
      decoration: const BoxDecoration(gradient: RadialGradient(
        center: Alignment(-0.65, -0.75), radius: 1.3,
        colors: [Color(0xFF231039), Color(0xFF111321), ink],
        stops: [0, 0.55, 1],
      )),
      child: Stack(children: [
        if (showToucan)
          Positioned(top: tab == AccessTab.signin ? 110 : 8, right: 20,
            child: IgnorePointer(child: Image.asset('assets/toucan.png', width: math.min(215, availableWidth * 0.22)))),
        Align(alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 46),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Innovación Tucán', style: style(20, weight: FontWeight.w700)), gap(32),
                Text(tab == AccessTab.signin ? 'Bienvenido a Comunidad Unix ITC' : 'Crea tu cuenta',
                    style: style(36, weight: FontWeight.w700)),
                gap(8),
                Text(tab == AccessTab.signin ? 'Inicia sesión para continuar aprendiendo.' : 'Únete y comienza aprender.',
                    style: style(14, color: muted)),
                gap(28), tabSwitcher(), gap(28), form(),
                GestureDetector(
                  onTap: () {}, // Tu compañero puede conectar la autenticación aquí.
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(colors: [orange, Color(0xFFEA580C)]),
                      boxShadow: const [BoxShadow(color: Color(0x553F1E0D), blurRadius: 20, offset: Offset(0, 8))],
                    ),
                    alignment: Alignment.center,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('G', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: white)),
                      const SizedBox(width: 10),
                      Flexible(child: Text(tab == AccessTab.signin ? 'Iniciar sesión con Google' : 'Registrarse con Google',
                          style: style(15, weight: FontWeight.w700))),
                    ]),
                  ),
                ),
                gap(24),
                Center(child: Wrap(alignment: WrapAlignment.center, children: [
                  Text(tab == AccessTab.signin ? '¿No tienes cuenta? ' : '¿Ya tienes cuenta? ', style: style(13, color: muted)),
                  InkWell(onTap: () => switchTab(tab == AccessTab.signin ? AccessTab.signup : AccessTab.signin),
                    child: Text(tab == AccessTab.signin ? 'Regístrate' : 'Inicia sesión', style: style(13, color: orange, weight: FontWeight.w600))),
                ])),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget rightPanel(double width, double height) {
    final imageWidth = math.min(260.0, math.min(width * 0.47, height * 0.48 * 300 / 440));
    return SizedBox(height: height, width: width, child: Stack(children: [
        const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF10143C), Color(0xFF202C70), Color(0xFF142052)],
        )))),
        Positioned.fill(child: CustomPaint(painter: SkyPainter())),
        Positioned(bottom: 0, left: 0, right: 0,
          child: SizedBox(height: height * 0.19, child: CustomPaint(painter: MountainPainter()))),
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: imageWidth, height: imageWidth * 440 / 300, child: Stack(fit: StackFit.expand, children: [
            Image.asset(sensitiveFocused ? 'assets/lexus_covered.png' : blink ? 'assets/lexus_blink.png' : 'assets/lexus_base.png', fit: BoxFit.fill),
            if (!sensitiveFocused && !blink) CustomPaint(painter: PupilPainter(pupil)),
          ])),
          const SizedBox(height: 14),
          Text(sensitiveFocused ? '¡No miro, lo prometo!' : '¡Hola! Soy Lexus🐧',
              textAlign: TextAlign.center, style: style(23, weight: FontWeight.w700)),
          gap(7),
          Text(sensitiveFocused ? 'Estoy mirando hacia otro lado.' : 'Tu compañero de confianza en Linux.',
              textAlign: TextAlign.center, style: style(13, color: const Color(0xFFABB4D5))),
        ])),
        Positioned(bottom: 24, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 20, height: 6, decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 8),
          for (var i = 0; i < 2; i++) ...[
            const CircleAvatar(radius: 3, backgroundColor: Color(0xFF6B789B)), const SizedBox(width: 8),
          ],
        ])),
      ]));
  }

  void followPointer(PointerEvent event, double width, double height) {
    if (sensitiveFocused || width < 950) return;
    // Eyes are centered in the illustration, which sits in the right panel.
    final imageWidth = math.min(260.0, math.min(width * 0.36 * 0.47, height * 0.48 * 300 / 440));
    final eyeCenter = Offset(width * 0.82, height * 0.5 - 34 - imageWidth * 68 / 300);
    final direction = event.localPosition - eyeCenter;
    final distance = direction.distance;
    if (distance == 0) { targetPupil = Offset.zero; return; }
    final amount = math.min(distance / 160, 1.0) * 8;
    targetPupil = Offset(direction.dx / distance * amount, direction.dy / distance * amount);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final desktop = box.maxWidth >= 950;
        final panel = box.maxWidth * 0.36;
        return Scaffold(body: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerHover: (event) => followPointer(event, box.maxWidth, box.maxHeight),
          onPointerMove: (event) => followPointer(event, box.maxWidth, box.maxHeight),
          child: SafeArea(child: desktop
          ? Row(children: [
              Expanded(child: SingleChildScrollView(child: leftPanel(box.maxWidth - panel, box.maxHeight))),
              rightPanel(panel, box.maxHeight),
            ])
          : SingleChildScrollView(child: leftPanel(box.maxWidth, box.maxHeight)),
        )));
      });
}

class PupilPainter extends CustomPainter {
  const PupilPainter(this.offset);
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300, size.height / 440);
    for (final center in [const Offset(120, 152), const Offset(180, 152)]) {
      final eye = center + offset;
      canvas.drawCircle(eye, 13, Paint()..color = const Color(0xFF08111F));
      canvas.drawCircle(eye, 10, Paint()..color = const Color(0xFF0D1A30));
      canvas.drawCircle(eye, 6.5, Paint()..color = const Color(0xFF030A15));
      canvas.drawCircle(eye + const Offset(-4, -4), 3.2, Paint()..color = const Color(0xE6FFFFFF));
      canvas.drawCircle(eye + const Offset(2.5, -1.5), 1.5, Paint()..color = const Color(0x73FFFFFF));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PupilPainter oldDelegate) => oldDelegate.offset != offset;
}

class SkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xAACCDAFF);
    final random = math.Random(17);
    for (var i = 0; i < 80; i++) {
      paint.color = const Color(0xFFCCD9FF).withValues(alpha: 0.15 + random.nextDouble() * 0.5);
      canvas.drawCircle(Offset(random.nextDouble() * size.width, random.nextDouble() * size.height * 0.9),
          0.5 + random.nextDouble(), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void triangle(double left, double apex, double right, double top, Color color) {
      final p = Path()..moveTo(size.width * left, size.height)..lineTo(size.width * apex, size.height * top)
          ..lineTo(size.width * right, size.height)..close();
      canvas.drawPath(p, Paint()..color = color);
      final snow = Path()..moveTo(size.width * apex, size.height * top)
          ..lineTo(size.width * (apex - 0.035), size.height * (top + 0.2))
          ..lineTo(size.width * (apex + 0.035), size.height * (top + 0.2))..close();
      canvas.drawPath(snow, Paint()..color = const Color(0xFFCCDDFA));
    }
    triangle(-.1, .2, .5, .2, const Color(0xFF102C61));
    triangle(.1, .38, .7, .1, const Color(0xFF15366D));
    triangle(.4, .7, 1.05, .15, const Color(0xFF102D63));
    triangle(.68, .86, 1.1, .38, const Color(0xFF173A76));
    canvas.drawRect(Rect.fromLTWH(0, size.height * .88, size.width, size.height * .12),
        Paint()..color = const Color(0x441D7092));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
