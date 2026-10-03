import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;
import 'package:http/http.dart' as http;

import 'pages/onboarding_page.dart';
import 'pages/alumno_page.dart';
import 'pages/instructor_page.dart';

// Inicio la aplicación desde la pantalla de acceso.
void main() {
  runApp(const ComunidadApp());
}

// Centralizo los colores que comparto entre las distintas secciones.
const Color ink = Color(0xFF080C18);
const Color orange = Color(0xFFF97316);
const Color muted = Color(0xFF9899A8);
const Color white = Colors.white;

class ComunidadApp extends StatelessWidget {
  const ComunidadApp({super.key});

  // Configuro el tema general y establezco el acceso como pantalla inicial.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comunidad Unix ITC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ink,
        colorScheme: ColorScheme.fromSeed(
          seedColor: orange,
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 14, color: white),
        ),
        splashFactory: NoSplash.splashFactory,
      ),
      home: const AccessScreen(),
    );
  }
}

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key});

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  // Conservo la posición actual y el destino animado de las pupilas.
  Offset pupil = Offset.zero;
  Offset targetPupil = Offset.zero;

  // Coordino el parpadeo, el envío de credenciales y los eventos de Google.
  bool blink = false;
  bool sendingToken = false;
  bool googleRequestInFlight = false;

  Timer? blinkTimer;
  Timer? unblinkTimer;
  Timer? eyeTimer;

  StreamSubscription<GoogleSignInAuthenticationEvent>? googleSubscription;

  String? authError;

  late final Widget googleButton = web.renderButton();

  // Envío el token de Google y preparo los datos para completar el perfil.
  Future<void> sendGoogleToken(GoogleSignInAccount user) async {
    // Evito procesar más de una solicitud de autenticación a la vez.
    if (googleRequestInFlight) return;
    googleRequestInFlight = true;

    final idToken = user.authentication.idToken;

    // Detengo el flujo si Google no proporciona el token requerido.
    if (idToken == null) {
      googleRequestInFlight = false;
      if (mounted)
        setState(() => authError = 'Google no devolvió un ID token.');
      return;
    }

    if (mounted)
      setState(() {
        sendingToken = true;
        authError = null;
      });

    try {
      // Envío el token al backend para validar la cuenta.
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/auth/google/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );

      if (!mounted) return;

      // Muestro el rechazo del servidor antes de interpretar su respuesta.
      if (response.statusCode < 200 || response.statusCode >= 300) {
        setState(
          () => authError =
              'El servidor rechazó el acceso (${response.statusCode})',
        );
        return;
      }

      final dynamic decoded = jsonDecode(response.body);

      // Compruebo que la respuesta tenga la estructura que espera la aplicación.
      if (decoded is! Map<String, dynamic>) {
        setState(
          () => authError = 'El servidor devolvió una respuesta inválida.',
        );
        return;
      }

      final Map<String, dynamic> data = decoded;
      debugPrint('Respuesta del backend: $data');

      // Extraigo los datos que necesito para abrir el formulario de perfil.
      final String? onboardingToken = data['token']?.toString();
      final String? email = data['Email']?.toString();
      final String? nombre = data['Nombre']?.toString();
      final bool esNuevo = data['Nuevo'] == true;
      final String rol = data['Rol']?.toString() ?? 'Alumno';

      if (onboardingToken == null || onboardingToken.isEmpty || email == null) {
        setState(() => authError = 'El servidor no devolvió los datos necesarios.');
        return;
      }

      if (!mounted) return;

      // Sustituyo la pantalla actual para que el usuario continúe el registro.
      if (esNuevo){
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OnboardingPage(
              onboardingToken: onboardingToken,
              email: email,
              nombre: nombre ?? '',
            ),
          ),
        );
      } else {
        // Si ya existe, entonces se salta directo a su panel según el rol
        Widget destination;
        if (rol == 'Instructor') {
          destination = const InstructorPage();
        } else {
          destination = const AlumnoPage(); // Alumnos y Externos
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => destination),
        );
      }
    } catch (error) {
      // Presento el error de conexión sin actualizar una pantalla desmontada.
      if (mounted)
        setState(
          () => authError = 'No se pudo conectar con el servidor: $error',
        );
    } finally {
      // Restablezco el estado de envío incluso si la solicitud falla.
      googleRequestInFlight = false;
      if (mounted) setState(() => sendingToken = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Escucho los inicios de sesión y envío cada cuenta autenticada al backend.
    GoogleSignIn.instance
        .initialize()
        .then((_) {
          googleSubscription = GoogleSignIn.instance.authenticationEvents
              .listen(
                (event) {
                  if (event is GoogleSignInAuthenticationEventSignIn) {
                    sendGoogleToken(event.user);
                  }
                },
                onError: (Object error) {
                  if (mounted)
                    setState(() => authError = 'Error de Google: $error');
                },
              );
        })
        .catchError((Object error) {
          if (mounted)
            setState(() => authError = 'No se pudo iniciar Google: $error');
        });

    // Animo gradualmente las pupilas hacia la posición indicada por el puntero.
    eyeTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || (pupil - targetPupil).distance < 0.03) return;
      setState(() => pupil = Offset.lerp(pupil, targetPupil, 0.14)!);
    });

    // Reproduzco un parpadeo periódico y restauro enseguida la imagen abierta.
    blinkTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => blink = true);
      unblinkTimer?.cancel();
      unblinkTimer = Timer(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => blink = false);
      });
    });
  }

  @override
  void dispose() {
    // Cancelo temporizadores y eventos para liberar recursos al cerrar la pantalla.
    blinkTimer?.cancel();
    unblinkTimer?.cancel();
    eyeTimer?.cancel();
    googleSubscription?.cancel();
    super.dispose();
  }

  TextStyle style(
    double size, {
    Color color = white,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: 1.25,
    );
  }

  // Mantengo una función breve para espaciar los elementos de la interfaz.
  Widget gap(double height) => SizedBox(height: height);

  // Construyo el panel de acceso y adapto sus elementos al ancho disponible.
  Widget leftPanel(double availableWidth, double height) {
    final bool showToucan = availableWidth > 750;
    return Container(
      constraints: BoxConstraints(minHeight: height),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.65, -0.75),
          radius: 1.3,
          colors: [Color(0xFF231039), Color(0xFF111321), ink],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          if (showToucan)
            // Muestro el tucán solo cuando hay espacio suficiente.
            Positioned(
              top: 95,
              right: 20,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/toucan.png',
                  width: math.min(215, availableWidth * 0.22),
                ),
              ),
            ),
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 46,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Innovación Tucán',
                      style: style(20, weight: FontWeight.w700),
                    ),
                    gap(55),
                    Text(
                      'Bienvenido a Comunidad Unix ITC',
                      style: style(36, weight: FontWeight.w700),
                    ),
                    gap(10),
                    Text(
                      'Inicia sesión con tu cuenta de Google para continuar.',
                      style: style(14, color: muted),
                    ),
                    gap(42),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: Color(0xFF343246)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'ACCESO',
                            style: style(
                              11,
                              color: muted,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: Color(0xFF343246)),
                        ),
                      ],
                    ),
                    gap(28),
                    Text(
                      'Continúa con Google',
                      textAlign: TextAlign.center,
                      style: style(17, weight: FontWeight.w600),
                    ),
                    gap(7),
                    Text(
                      'Usa tu cuenta de Google para registrarte y completar tu perfil.',
                      textAlign: TextAlign.center,
                      style: style(13, color: muted),
                    ),
                    gap(20),
                    Center(child: googleButton),
                    // Explico visualmente que la autenticación sigue en curso.
                    if (sendingToken) ...[
                      gap(24),
                      const Center(
                        child: CircularProgressIndicator(color: orange),
                      ),
                      gap(10),
                      Center(
                        child: Text(
                          'Verificando tu cuenta...',
                          style: style(13, color: muted),
                        ),
                      ),
                    ],
                    // Mantengo visible el detalle del error junto al acceso.
                    if (authError != null) ...[
                      gap(20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF321C26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF713446)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                authError!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    gap(34),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: Color(0xFF52D7A7),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Acceso seguro con Google',
                            style: style(12, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Compongo el panel ilustrado con sus capas y la mascota animada.
  Widget rightPanel(double width, double height) {
    final double imageWidth = math.min(
      260.0,
      math.min(width * 0.47, height * 0.48 * 300 / 440),
    );
    return SizedBox(
      height: height,
      width: width,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF10143C),
                    Color(0xFF202C70),
                    Color(0xFF142052),
                  ],
                ),
              ),
            ),
          ),
          // Superpongo el cielo, las montañas y los ojos sobre el fondo.
          Positioned.fill(child: CustomPaint(painter: SkyPainter())),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: height * 0.19,
              child: CustomPaint(painter: MountainPainter()),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: imageWidth,
                  height: imageWidth * 440 / 300,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        blink
                            ? 'assets/lexus_blink.png'
                            : 'assets/lexus_base.png',
                        fit: BoxFit.fill,
                      ),
                      if (!blink) CustomPaint(painter: PupilPainter(pupil)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '¡Hola! Soy Lexus 🐧',
                  textAlign: TextAlign.center,
                  style: style(23, weight: FontWeight.w700),
                ),
                gap(7),
                Text(
                  'Tu compañero de confianza en Linux.',
                  textAlign: TextAlign.center,
                  style: style(13, color: const Color(0xFFABB4D5)),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 6,
                  decoration: BoxDecoration(
                    color: orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                for (var i = 0; i < 2; i++) ...[
                  const CircleAvatar(
                    radius: 3,
                    backgroundColor: Color(0xFF6B789B),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Calculo el desplazamiento de la mirada únicamente en pantallas amplias.
  void followPointer(PointerEvent event, double width, double height) {
    if (width < 950) return;
    final double imageWidth = math.min(
      260.0,
      math.min(width * 0.36 * 0.47, height * 0.48 * 300 / 440),
    );
    final Offset eyeCenter = Offset(
      width * 0.82,
      height * 0.5 - 34 - imageWidth * 68 / 300,
    );
    final Offset direction = event.localPosition - eyeCenter;
    final double distance = direction.distance;

    if (distance == 0) {
      targetPupil = Offset.zero;
      return;
    }
    final double amount = math.min(distance / 160, 1.0) * 8;
    targetPupil = Offset(
      direction.dx / distance * amount,
      direction.dy / distance * amount,
    );
  }

  // Distribuyo los paneles en escritorio y conservo una columna en pantallas estrechas.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final bool desktop = box.maxWidth >= 950;
        final double panel = box.maxWidth * 0.36;
        return Scaffold(
          body: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerHover: (event) =>
                followPointer(event, box.maxWidth, box.maxHeight),
            onPointerMove: (event) =>
                followPointer(event, box.maxWidth, box.maxHeight),
            child: SafeArea(
              child: desktop
                  ? Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: leftPanel(
                              box.maxWidth - panel,
                              box.maxHeight,
                            ),
                          ),
                        ),
                        rightPanel(panel, box.maxHeight),
                      ],
                    )
                  : SingleChildScrollView(
                      child: leftPanel(box.maxWidth, box.maxHeight),
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// OJOS DE LEXUS
// ============================================================

class PupilPainter extends CustomPainter {
  const PupilPainter(this.offset);

  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    canvas.scale(size.width / 300, size.height / 440);

    for (final Offset center in [
      const Offset(120, 152),
      const Offset(180, 152),
    ]) {
      final Offset eye = center + offset;

      canvas.drawCircle(eye, 13, Paint()..color = const Color(0xFF08111F));

      canvas.drawCircle(eye, 10, Paint()..color = const Color(0xFF0D1A30));

      canvas.drawCircle(eye, 6.5, Paint()..color = const Color(0xFF030A15));

      canvas.drawCircle(
        eye + const Offset(-4, -4),
        3.2,
        Paint()..color = const Color(0xE6FFFFFF),
      );

      canvas.drawCircle(
        eye + const Offset(2.5, -1.5),
        1.5,
        Paint()..color = const Color(0x73FFFFFF),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PupilPainter oldDelegate) {
    return oldDelegate.offset != offset;
  }
}

// ============================================================
// ESTRELLAS
// ============================================================

class SkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = const Color(0xAACCDAFF);

    final math.Random random = math.Random(17);

    for (var i = 0; i < 80; i++) {
      paint.color = const Color(
        0xFFCCD9FF,
      ).withValues(alpha: 0.15 + random.nextDouble() * 0.5);

      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height * 0.9,
        ),
        0.5 + random.nextDouble(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================
// MONTAÑAS
// ============================================================

class MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void triangle(
      double left,
      double apex,
      double right,
      double top,
      Color color,
    ) {
      final Path path = Path()
        ..moveTo(size.width * left, size.height)
        ..lineTo(size.width * apex, size.height * top)
        ..lineTo(size.width * right, size.height)
        ..close();

      canvas.drawPath(path, Paint()..color = color);

      final Path snow = Path()
        ..moveTo(size.width * apex, size.height * top)
        ..lineTo(size.width * (apex - 0.035), size.height * (top + 0.2))
        ..lineTo(size.width * (apex + 0.035), size.height * (top + 0.2))
        ..close();

      canvas.drawPath(snow, Paint()..color = const Color(0xFFCCDDFA));
    }

    triangle(-0.1, 0.2, 0.5, 0.2, const Color(0xFF102C61));

    triangle(0.1, 0.38, 0.7, 0.1, const Color(0xFF15366D));

    triangle(0.4, 0.7, 1.05, 0.15, const Color(0xFF102D63));

    triangle(0.68, 0.86, 1.1, 0.38, const Color(0xFF173A76));

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.88, size.width, size.height * 0.12),
      Paint()..color = const Color(0x441D7092),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
