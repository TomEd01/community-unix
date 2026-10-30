import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencia única para toda la aplicación, independiente de la sesión.
class UnixTheme extends ChangeNotifier {
  UnixTheme._();
  static final instance = UnixTheme._();
  static const preferenceKey = 'unix_theme_mode';
  bool _dark = true;
  bool _saving = false;
  bool get isDark => _dark;
  bool get saving => _saving;
  ThemeMode get mode => _dark ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _dark = preferences.getString(preferenceKey) != 'light';
  }

  Future<void> toggle() async {
    if (_saving) return;
    _dark = !_dark;
    _saving = true;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        preferenceKey,
        _dark ? 'dark' : 'light',
      );
      if (!saved) throw StateError('No se pudo guardar el tema.');
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// Registra la dependencia incluso en páginas conservadas por el navegador.
  static void watch(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<UnixThemeScope>();
  }
}

class UnixThemeScope extends InheritedNotifier<UnixTheme> {
  UnixThemeScope({super.key, required super.child})
    : super(notifier: UnixTheme.instance);
}

/// Colores compartidos. Las ilustraciones y los colores de marca se conservan.
class UnixColors {
  static bool get dark => UnixTheme.instance.isDark;
  static Color get background =>
      dark ? const Color(0xFF031426) : const Color(0xFFF5F8FC);
  static Color get surface => dark ? const Color(0xFF061C31) : Colors.white;
  static Color get card => dark ? const Color(0xFF0A2947) : Colors.white;
  static Color get field =>
      dark ? const Color(0xFF0D3153) : const Color(0xFFEDF4FB);
  static Color get border =>
      dark ? const Color(0xFF174064) : const Color(0xFFD5E3F1);
  static Color get link =>
      dark ? const Color(0xFF2796FF) : const Color(0xFF1688FF);
  static Color get text =>
      dark ? const Color(0xFFF4F6FA) : const Color(0xFF102A43);
  static Color get muted =>
      dark ? const Color(0xFF91A9BE) : const Color(0xFF52657A);
  static Color get selected =>
      dark ? const Color(0xFF123451) : const Color(0xFFE3F0FF);
  static const orange = Color(0xFFFF8A24);
  static const onOrange = Color(0xFF031426);

  /// Conserva la paleta oscura original y asigna su equivalente claro.
  static Color adapt(Color original) {
    if (dark) return original;
    return _light[original.toARGB32()] ?? original;
  }

  static const _light = <int, Color>{
    0xFF031426: Color(0xFFF5F8FC),
    0xFF080C18: Color(0xFFF8FAFC),
    0xFF050C1D: Color(0xFFF5F8FC),
    0xFF061C31: Color(0xFFFFFFFF),
    0xFF0A2947: Color(0xFFFFFFFF),
    0xFF081329: Color(0xFFFFFFFF),
    0xFF123451: Color(0xFFE3F0FF),
    0xFF0D3153: Color(0xFFEDF4FB),
    0xFF0C3152: Color(0xFFEDF4FB),
    0xFF123F62: Color(0xFFDCEBFC),
    0xFF111D36: Color(0xFFF5F8FC),
    0xFF12264A: Color(0xFFEAF2FF),
    0xFF18243B: Color(0xFFE5ECF5),
    0xFF174064: Color(0xFFD5E3F1),
    0xFF34425C: Color(0xFFD5E3F1),
    0xFF343246: Color(0xFFC3D2E1),
    0xFF91A9BE: Color(0xFF52657A),
    0xFF9899A8: Color(0xFF52657A),
    0xFF929DB2: Color(0xFF52657A),
    0xFFF4F6FA: Color(0xFF102A43),
    0xFFF4F5FF: Color(0xFF102A43),
    0xFF080F22: Color(0xFFF5F8FC),
    0xFF101535: Color(0xFFEDF4FF),
    0xFF171B48: Color(0xFFE7EFFF),
    0xFF101A34: Color(0xFFFFFFFF),
    0xFF182545: Color(0xFFF0F5FC),
    0xFF27345E: Color(0xFFE3F0FF),
    0xFF293A63: Color(0xFFD5E3F1),
    0xFF9BA7C2: Color(0xFF52657A),
    0xFF75819E: Color(0xFF52657A),
    0xFF231039: Color(0xFFF0EBFF),
    0xFF111321: Color(0xFFF8FAFC),
    0xFF10143C: Color(0xFFEAF2FF),
    0xFF202C70: Color(0xFFDCE8FC),
    0xFF142052: Color(0xFFE7EFFF),
    0xFFABB4D5: Color(0xFF52657A),
    0xFF6B789B: Color(0xFFB4C8E5),
    0xFF321C26: Color(0xFFFFEEF0),
    0xFF713446: Color(0xFFB4233C),
    0xFF35D59A: Color(0xFF087B52),
    0xFF6ED9AB: Color(0xFF087B52),
    0xFF53D39A: Color(0xFF087B52),
    0xFF41D6A3: Color(0xFF087B52),
    0xFF52D7A7: Color(0xFF087B52),
    0xFFFF6577: Color(0xFFC32946),
    0xFFFF4D5A: Color(0xFFC32946),
    0xFF2796FF: Color(0xFF1688FF),
    0xFF62B9FF: Color(0xFF0868C9),
    0xFF68A4FF: Color(0xFF0868C9),
    0xFF65A7FF: Color(0xFF0868C9),
    0xFF22D3C5: Color(0xFF007F78),
    0xFFFFB067: Color(0xFFA94700),
    0xFFB6A6FA: Color(0xFF6544B7),
  };
}

class UnixThemes {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get current => UnixTheme.instance.isDark ? dark : light;

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark ? const Color(0xFF031426) : const Color(0xFFF5F8FC);
    final surface = dark ? const Color(0xFF061C31) : Colors.white;
    final text = dark ? const Color(0xFFF4F6FA) : const Color(0xFF102A43);
    final muted = dark ? const Color(0xFF91A9BE) : const Color(0xFF52657A);
    final scheme = ColorScheme.fromSeed(
      seedColor: UnixColors.orange,
      brightness: brightness,
      primary: UnixColors.orange,
      onPrimary: UnixColors.onOrange,
      surface: surface,
      onSurface: text,
      error: dark ? const Color(0xFFFF6577) : const Color(0xFFC32946),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: dark ? const Color(0xFF174064) : const Color(0xFFD5E3F1),
        width: 1,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      iconTheme: IconThemeData(color: muted),
      dividerColor: dark ? const Color(0xFF174064) : const Color(0xFFD5E3F1),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        textStyle: TextStyle(color: text),
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? background : const Color(0xFFF5F8FC),
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted),
        border: outline,
        enabledBorder: outline,
        focusedBorder: outline.copyWith(
          borderSide: const BorderSide(color: Color(0xFF2796FF), width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: UnixColors.orange,
          foregroundColor: UnixColors.onOrange,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark ? UnixColors.orange : const Color(0xFF174064),
        ),
      ),
      splashFactory: NoSplash.splashFactory,
    );
  }
}

/// Selector integrado en las cabeceras; no reserva una barra adicional.
class UnixThemeToggle extends StatelessWidget {
  const UnixThemeToggle({super.key, this.compact = false});
  final bool compact;

  Future<void> _change(BuildContext context, bool dark) async {
    if (dark == UnixTheme.instance.isDark) return;
    try {
      await UnixTheme.instance.toggle();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text(
              'El tema cambió, pero no se pudo guardar la preferencia.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    final controller = UnixTheme.instance;
    if (compact) {
      return IconButton.outlined(
        tooltip: controller.isDark ? 'Cambiar a claro' : 'Cambiar a oscuro',
        onPressed: controller.saving
            ? null
            : () => _change(context, !controller.isDark),
        icon: Icon(
          controller.isDark
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
          size: 19,
        ),
        style: IconButton.styleFrom(
          foregroundColor: UnixColors.text,
          backgroundColor: UnixColors.surface,
          side: BorderSide(color: UnixColors.border.withValues(alpha: 0.45)),
          minimumSize: const Size(40, 40),
          maximumSize: const Size(40, 40),
          padding: const EdgeInsets.all(8),
        ),
      );
    }
    return Semantics(
      label: 'Tema de la aplicación',
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: false,
            icon: Icon(Icons.light_mode_outlined, size: 17),
            label: Text('Claro'),
          ),
          ButtonSegment(
            value: true,
            icon: Icon(Icons.dark_mode_outlined, size: 17),
            label: Text('Oscuro'),
          ),
        ],
        selected: {controller.isDark},
        showSelectedIcon: false,
        onSelectionChanged: controller.saving
            ? null
            : (values) => _change(context, values.single),
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 12)),
          side: WidgetStatePropertyAll(
            BorderSide(color: UnixColors.border.withValues(alpha: 0.45)),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? UnixColors.onOrange
                : UnixColors.text,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? UnixColors.orange.withValues(alpha: 0.85)
                : UnixColors.surface,
          ),
        ),
      ),
    );
  }
}
