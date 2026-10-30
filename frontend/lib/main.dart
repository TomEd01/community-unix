import 'theme/unix_lexus_portrait.dart';
import 'theme/unix_theme.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;
import 'package:http/http.dart' as http;

import 'pages/onboarding_page.dart';
import 'pages/bienvenida_page.dart';
import 'pages/alumno_page.dart';
import 'pages/instructor_page.dart';
import 'pages/externo_page.dart';
import 'pages/admin/admin_page.dart';

import 'package:shared_preferences/shared_preferences.dart';

// Se consulta el perfil del servidor para no reutilizar un rol antiguo.
const String authBaseUrl = 'http://127.0.0.1:8000/api/auth';

String resolverRol(Map<String, dynamic> data) {
  final rol =
      (data['rol'] ?? data['Rol'])?.toString().trim().toLowerCase() ?? '';
  if (data['es_superadmin'] == true || rol == 'superadmin' || rol == 'admin') {
    return 'superadmin';
  }
  return rol;
}

Widget? pantallaParaRol(String? rol) {
  switch (rol?.trim().toLowerCase()) {
    case 'alumno':
      return AlumnoPage();
    case 'instructor':
      return InstructorPage();
    case 'externo':
      return ExternoPage();
    case 'superadmin':
    case 'admin':
      return AdminPage();
    default:
      return null;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UnixTheme.instance.load();
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('jwt_token');
  String? rol;

  if (token != null && token.trim().isNotEmpty) {
    try {
      final response = await http
          .get(
            Uri.parse('$authBaseUrl/perfil/me/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          final actual = resolverRol(decoded);
          debugPrint(
            'Perfil inicial: rol=${decoded['rol']}, '
            'es_superadmin=${decoded['es_superadmin']}, destino=$actual',
          );
          if (pantallaParaRol(actual) != null) {
            rol = actual;
            await prefs.setString('user_rol', actual);
          }
        }
      } else if (response.statusCode == 401) {
        await prefs.remove('jwt_token');
        await prefs.remove('user_rol');
        token = null;
      } else {
        debugPrint('No se pudo verificar el perfil: ${response.statusCode}');
      }
    } catch (_) {
      debugPrint('No se pudo verificar el perfil. Se mostrará el acceso.');
    }
  }
  runApp(
    UnixThemeScope(
      child: ComunidadApp(tokenInicial: token, rolInicial: rol),
    ),
  );
}

// Centralizo los colores que comparto entre las distintas secciones.
Color get ink => UnixColors.adapt(Color(0xFF080C18));
const Color orange = Color(0xFFF97316);
Color get muted => UnixColors.adapt(Color(0xFF9899A8));
Color get white => UnixColors.text;

class ComunidadApp extends StatelessWidget {
  final String? tokenInicial;
  final String? rolInicial;
  const ComunidadApp({super.key, this.tokenInicial, this.rolInicial});

  // Configuro el tema general y establezco el acceso como pantalla inicial.
  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    // Lógica de enrutamiento inicial
    Widget pantallaInicial;

    if (tokenInicial != null && tokenInicial!.trim().isNotEmpty) {
      pantallaInicial = pantallaParaRol(rolInicial) ?? AccessScreen();
    } else {
      pantallaInicial = Builder(
        builder: (context) {
          UnixTheme.watch(context);
          return BienvenidaPage(
            onRegister: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => AccessScreen()));
            },
          );
        },
      );
    }
    return MaterialApp(
      title: 'Comunidad Unix ITC',
      debugShowCheckedModeBanner: false,
      theme: UnixThemes.light,
      darkTheme: UnixThemes.dark,
      themeMode: UnixTheme.instance.mode,
      themeAnimationDuration: Duration.zero,
      home: pantallaInicial,
    );
  }
}

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key});

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  static bool _googleIniciado = false;
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
        Uri.parse('$authBaseUrl/google/'),
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

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

      // Compruebo que la respuesta tenga la estructura que espera la aplicación.
      if (decoded is! Map<String, dynamic>) {
        setState(
          () => authError = 'El servidor devolvió una respuesta inválida.',
        );
        return;
      }

      final Map<String, dynamic> data = decoded;

      debugPrint('Rol recibido: ${data['Rol']}');
      debugPrint('Es superadmin: ${data['es_superadmin']}');
      debugPrint('Usuario nuevo: ${data['Nuevo']}');

      // Extraigo los datos que necesito para abrir el formulario de perfil.

      final String? onboardingToken = data['token']?.toString();
      final String? email = data['Email']?.toString();
      final String? nombre = data['Nombre']?.toString();
      final bool esNuevo = data['Nuevo'] == true;
      final String rol = resolverRol(data);

      if (onboardingToken == null || onboardingToken.isEmpty || email == null) {
        setState(
          () => authError = 'El servidor no devolvió los datos necesarios.',
        );
        return;
      }

      if (!mounted) return;

      // Sustituyo la pantalla actual para que el usuario continúe el registro.
      if (esNuevo && rol != 'superadmin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) {
              UnixTheme.watch(context);
              return OnboardingPage(
                onboardingToken: onboardingToken,
                email: email,
                nombre: nombre ?? '',
              );
            },
          ),
        );
      } else {
        final destination = pantallaParaRol(rol);
        if (destination == null) {
          setState(
            () => authError =
                'Rol no reconocido: $rol. '
                'Revisa Rol y es_superadmin en la respuesta del backend.',
          );
          return;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', onboardingToken);
        await prefs.setString('user_rol', rol);
        if (!mounted) return;
        debugPrint('Navegación después de Google: $rol');
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
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
    // Función auxiliar para no repetir código
    void activarEscuchaGoogle() {
      if (!mounted) return;
      googleSubscription = GoogleSignIn.instance.authenticationEvents.listen(
        (event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            sendGoogleToken(event.user);
          }
        },
        onError: (Object error) {
          if (mounted) setState(() => authError = 'Error de Google: $error');
        },
      );
    }

    // Escucho los inicios de sesión y envío cada cuenta autenticada al backend, manteniendo
    // una mejora de logica inteligente de inicialización.
    if (!_googleIniciado) {
      GoogleSignIn.instance
          .initialize()
          .then((_) {
            _googleIniciado = true;
            activarEscuchaGoogle();
          })
          .catchError((Object error) {
            // Si el navegador ya lo había iniciado (ej. por recargas en desarrollo), nos recuperamos silenciosamente
            if (error.toString().contains('already been called')) {
              _googleIniciado = true;
              activarEscuchaGoogle();
            } else {
              if (mounted)
                setState(() => authError = 'No se pudo iniciar Google: $error');
            }
          });
    } else {
      activarEscuchaGoogle();
    }

    // Animo gradualmente las pupilas hacia la posición indicada por el puntero.
    eyeTimer = Timer.periodic(Duration(milliseconds: 16), (_) {
      if (!mounted || (pupil - targetPupil).distance < 0.03) return;
      setState(() => pupil = Offset.lerp(pupil, targetPupil, 0.14)!);
    });

    // Reproduzco un parpadeo periódico y restauro enseguida la imagen abierta.
    blinkTimer = Timer.periodic(Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => blink = true);
      unblinkTimer?.cancel();
      unblinkTimer = Timer(Duration(milliseconds: 150), () {
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
    Color? color,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontSize: size,
      color: color ?? white,
      fontWeight: weight,
      height: 1.25,
    );
  }

  // Mantengo una función breve para espaciar los elementos de la interfaz.
  Widget gap(double height) => SizedBox(height: height);

  void _volverAlInicio() {
    final navigator = Navigator.of(context);

    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => BienvenidaPage(
          onRegister: () {
            navigator.push(
              MaterialPageRoute<void>(
                builder: (_) => const AccessScreen(),
              ),
            );
          },
        ),
      ),
      (route) => false,
    );
  }

  // Construyo el panel de acceso y adapto sus elementos al ancho disponible.
 Widget leftPanel(double availableWidth, double height) {
  final bool showToucan = availableWidth > 750;

  return Container(
    constraints: BoxConstraints(minHeight: height),
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(-0.65, -0.75),
        radius: 1.3,
        colors: [
          UnixColors.adapt(const Color(0xFF231039)),
          UnixColors.adapt(const Color(0xFF111321)),
          ink,
        ],
        stops: const [0, 0.55, 1],
      ),
    ),
    child: Stack(
      children: [
        if (showToucan)
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

        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: availableWidth < 600 ? 24 : 48,
            vertical: 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: sendingToken || googleRequestInFlight
                          ? null
                          : _volverAlInicio,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 19,
                      ),
                      label: const Text('Volver al inicio'),
                      style: TextButton.styleFrom(
                        foregroundColor: UnixColors.text,
                      ),
                    ),
                  ),
                  gap(16),

                  Text(
                    'Innovación Tucán',
                    style: style(20, weight: FontWeight.w700),
                  ),
                  gap(48),

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
                      Expanded(
                        child: Divider(
                          color: UnixColors.adapt(
                            const Color(0xFF343246),
                          ),
                        ),
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
                      Expanded(
                        child: Divider(
                          color: UnixColors.adapt(
                            const Color(0xFF343246),
                          ),
                        ),
                      ),
                    ],
                  ),
                  gap(28),

                  Center(
                    child: Text(
                      'Continúa con Google',
                      textAlign: TextAlign.center,
                      style: style(17, weight: FontWeight.w600),
                    ),
                  ),
                  gap(7),

                  Center(
                    child: Text(
                      'Usa tu cuenta de Google para registrarte y completar tu perfil.',
                      textAlign: TextAlign.center,
                      style: style(13, color: muted),
                    ),
                  ),
                  gap(20),

                  Center(child: googleButton),

                  if (sendingToken) ...[
                    gap(24),
                    Center(
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

                  if (authError != null) ...[
                    gap(20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: UnixColors.adapt(
                          const Color(0xFF321C26),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: UnixColors.adapt(
                            const Color(0xFF713446),
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: UnixColors.adapt(
                              const Color(0xFFFF6577),
                            ),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authError!,
                              style: TextStyle(
                                color: UnixColors.adapt(
                                  const Color(0xFFFF6577),
                                ),
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
                        Icon(
                          Icons.shield_outlined,
                          color: UnixColors.adapt(
                            const Color(0xFF52D7A7),
                          ),
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
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    UnixColors.adapt(Color(0xFF10143C)),
                    UnixColors.adapt(Color(0xFF202C70)),
                    UnixColors.adapt(Color(0xFF142052)),
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
                UnixLexusPortrait(
                  width: imageWidth,
                  pupilOffset: pupil,
                  blink: blink,
                ),
                SizedBox(height: 14),
                Text(
                  '¡Hola! Soy Lexus 🐧',
                  textAlign: TextAlign.center,
                  style: style(23, weight: FontWeight.w700),
                ),
                gap(7),
                Text(
                  'Tu compañero de confianza en Linux.',
                  textAlign: TextAlign.center,
                  style: style(13, color: UnixColors.adapt(Color(0xFFABB4D5))),
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
                SizedBox(width: 8),
                for (var i = 0; i < 2; i++) ...[
                  CircleAvatar(
                    radius: 3,
                    backgroundColor: UnixColors.adapt(Color(0xFF6B789B)),
                  ),
                  SizedBox(width: 8),
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
    UnixTheme.watch(context);
    return LayoutBuilder(
      builder: (context, box) {
        UnixTheme.watch(context);
        final bool desktop = box.maxWidth >= 950;
        final double panel = box.maxWidth * 0.36;
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              Listener(
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
              Positioned(
                top: 16,
                right: 16,
                child: SafeArea(child: UnixThemeToggle(compact: !desktop)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// OJOS DE LEXUS
// ============================================================

// ============================================================
// ESTRELLAS
// ============================================================

class SkyPainter extends CustomPainter {
  SkyPainter() : super(repaint: UnixTheme.instance);
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    final math.Random random = math.Random(17);

    for (var i = 0; i < 80; i++) {
      paint.color =
          (UnixColors.dark ? const Color(0xFFCCD9FF) : const Color(0xFF3F7CD3))
              .withValues(alpha: 0.15 + random.nextDouble() * 0.5);

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
