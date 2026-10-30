import '../../theme/unix_theme.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ Paleta ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
Color get _card => UnixColors.adapt(const Color(0xFF0A2947));
Color get _border => UnixColors.border;
const _orange = Color(0xFFFF8A24);
Color get _muted => UnixColors.adapt(const Color(0xFF91A9BE));
Color get _red => UnixColors.adapt(const Color(0xFFFF6577));
Color get _sheet => UnixColors.adapt(const Color(0xFF102B46));
Color get _field => UnixColors.adapt(const Color(0xFF0A223A));
const _green = Color(0xFF30D158);
const _yellow = Color(0xFFFFD60A);

// Colores de sistema de iOS (modo oscuro) para distinguir materias y alumnos.
const _paleta = [
  Color(0xFF0A84FF),
  Color(0xFF30D158),
  Color(0xFFFF9F0A),
  Color(0xFFFF375F),
  Color(0xFFBF5AF2),
  Color(0xFF64D2FF),
  Color(0xFF5E5CE6),
  Color(0xFFFFD60A),
];

TextStyle _t(
  double size, {
  FontWeight w = FontWeight.w400,
  Color? c,
  double? ls,
}) => TextStyle(
  fontSize: size,
  fontWeight: w,
  color: c ?? UnixColors.text,
  letterSpacing: ls,
  decoration: TextDecoration.none,
);

Color _colorPara(String texto) {
  final hash = texto.codeUnits.fold<int>(
    7,
    (a, b) => (a * 31 + b) & 0x7fffffff,
  );
  return _paleta[hash % _paleta.length];
}

String _iniciales(String nombre) {
  final p = nombre
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  if (p.isEmpty) return '?';
  if (p.length == 1) return p.first.substring(0, 1).toUpperCase();
  return (p.first.substring(0, 1) + p[1].substring(0, 1)).toUpperCase();
}

Widget _oscuro(Widget child) => CupertinoTheme(
  data: const CupertinoThemeData(brightness: Brightness.dark),
  child: child,
);

// ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ Horas ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
String _dos(int v) => v.toString().padLeft(2, '0');

// Mismo formato que ya espera el backend: "08:00 AM ÔÇô 09:30 AM".
String _formatoHora(int minutos) {
  final h = minutos ~/ 60;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '${_dos(h12)}:${_dos(minutos % 60)} ${h < 12 ? 'AM' : 'PM'}';
}

String _horaCorta(int minutos) {
  final h = minutos ~/ 60;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${_dos(minutos % 60)}';
}

String _periodo(int minutos) => (minutos ~/ 60) < 12 ? 'AM' : 'PM';

class _Rango {
  const _Rango(this.inicio, this.fin);

  final int inicio;
  final int fin;

  String get duracion {
    final d = fin - inicio;
    if (d <= 0) return '';
    final h = d ~/ 60;
    final m = d % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '$h h';
    return '$h h $m min';
  }
}

_Rango? _leerRango(Object? horario) {
  final coincidencias = RegExp(
    r'(\d{1,2}):(\d{2})\s*([AaPp])\.?\s*[Mm]',
  ).allMatches('$horario').toList();

  if (coincidencias.length < 2) return null;

  int? minutos(RegExpMatch m) {
    final h = int.parse(m.group(1)!);
    final mm = int.parse(m.group(2)!);
    if (h < 1 || h > 12 || mm > 59) return null;
    final pm = m.group(3)!.toLowerCase() == 'p';
    return ((h % 12) + (pm ? 12 : 0)) * 60 + mm;
  }

  final a = minutos(coincidencias[0]);
  final b = minutos(coincidencias[1]);
  if (a == null || b == null) return null;
  return _Rango(a, b);
}

// ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ P├ígina ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
class InstructorHorariosPage extends StatefulWidget {
  const InstructorHorariosPage({super.key});

  @override
  State<InstructorHorariosPage> createState() => _InstructorHorariosPageState();
}

class _InstructorHorariosPageState extends State<InstructorHorariosPage> {
  static const _url = 'http://127.0.0.1:8000/api/auth/instructor/horarios/';

  List<Map<String, dynamic>> _bloques = [];
  final Set<String> _abiertos = {};
  final TextEditingController _buscador = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;
  String? _error;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  // ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ Red ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.trim().isEmpty) {
      throw Exception('Inicia sesi├│n para consultar tus horarios.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  dynamic _respuesta(http.Response response) {
    dynamic body;

    try {
      if (response.bodyBytes.isNotEmpty) {
        body = jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {
      throw Exception(
        'El servidor devolvi├│ una respuesta inesperada (${response.statusCode}).',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        throw Exception('Tu sesi├│n venci├│. Vuelve a ingresar.');
      }

      final mensaje = body is Map
          ? (body['error'] ?? body['detail'] ?? body.values.join('\n'))
          : 'No se pudo completar la petici├│n (${response.statusCode}).';

      throw Exception(mensaje.toString());
    }

    return body;
  }

  String _mensaje(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  // Aviso tipo banner de iOS (no depende de un Scaffold).
  void _aviso(String mensaje, {bool error = false}) {
    if (!mounted) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) =>
          _Toast(mensaje: mensaje, error: error, alTerminar: entry.remove),
    );
    overlay.insert(entry);
  }

  Future<void> _cargar() async {
    if (!mounted) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final headers = await _headers();

      final response = await http
          .get(Uri.parse(_url), headers: headers)
          .timeout(const Duration(seconds: 20));

      final body = _respuesta(response);

      if (body is! Map || body['bloques_horarios'] is! List) {
        throw Exception(
          'No se encontr├│ la lista de bloques horarios en la respuesta.',
        );
      }

      final bloques = (body['bloques_horarios'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (!mounted) return;

      setState(() => _bloques = bloques);
    } catch (error) {
      if (!mounted) return;

      setState(() => _error = _mensaje(error));
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _crear() async {
    if (_guardando) return;
    HapticFeedback.lightImpact();

    final datos = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const _NuevoHorarioSheet(),
    );

    if (datos == null || !mounted || _guardando) return;

    setState(() => _guardando = true);

    try {
      final headers = await _headers();

      final response = await http
          .post(Uri.parse(_url), headers: headers, body: jsonEncode(datos))
          .timeout(const Duration(seconds: 20));

      _respuesta(response);

      if (!mounted) return;

      HapticFeedback.mediumImpact();
      _aviso('Horario creado correctamente.');
      await _cargar();
    } catch (error) {
      _aviso(_mensaje(error), error: true);
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  Future<void> _eliminar(Map<String, dynamic> bloque) async {
    if (_guardando) return;

    final confirmar = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => _oscuro(
        CupertinoAlertDialog(
          title: const Text('Eliminar horario'),
          content: Text(
            '┬┐Eliminar ${bloque['materia']} (${bloque['horario']})?\n\n'
            'Los alumnos vinculados tendr├ín que elegir otro horario.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true || !mounted || _guardando) return;

    setState(() => _guardando = true);

    try {
      final id = bloque['horario_id'];

      if (id == null) {
        throw Exception('Este horario no tiene ID.');
      }

      final headers = await _headers();

      final response = await http
          .delete(
            Uri.parse('$_url${Uri.encodeComponent(id.toString())}/'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));

      _respuesta(response);

      if (!mounted) return;

      HapticFeedback.mediumImpact();
      _aviso('Horario eliminado correctamente.');
      await _cargar();
    } catch (error) {
      _aviso(_mensaje(error), error: true);
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  void _acciones(Map<String, dynamic> bloque) {
    HapticFeedback.selectionClick();

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => _oscuro(
        CupertinoActionSheet(
          title: Text('${bloque['materia'] ?? ''}'),
          message: Text('${bloque['horario'] ?? ''}'),
          actions: [
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                _eliminar(bloque);
              },
              child: const Text('Eliminar horario'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ),
      ),
    );
  }

  // El backend enviado todav├¡a no devuelve XP ni historial.
  // Este adaptador permite mostrarlos cuando se incluyan en cada alumno:
  // xp_total y actividades: [{tipo, actividad, estado}]. No inventa valores.
  Future<void> _historial(Map<String, dynamic> alumno) async {
    HapticFeedback.selectionClick();

    final actividades = alumno['actividades'];
    final nombre = '${alumno['nombre_completo'] ?? 'alumno'}';
    final control = alumno['numero_control'];
    final xp = alumno['xp_total'];

    Widget mensaje(String texto) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: _t(15, c: _muted),
        ),
      ),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => _Hoja(
        titulo: 'Historial',
        derecha: _Tap(
          onTap: () => Navigator.pop(ctx),
          child: Text(
            'Listo',
            style: _t(17, w: FontWeight.w600, c: _orange),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                _Avatar(nombre: nombre, tamano: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: _t(18, w: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'N.┬║ de control: ${control ?? 'No disponible'}',
                        style: _t(13, c: _muted),
                      ),
                    ],
                  ),
                ),
                if (xp != null) _PildoraXp(xp: '$xp'),
              ],
            ),
            const SizedBox(height: 16),
            if (actividades is! List)
              mensaje(
                'El servidor todav├¡a no proporciona el historial de actividades.',
              )
            else if (actividades.isEmpty)
              mensaje('No hay ninguna actividad activa')
            else
              Container(
                decoration: BoxDecoration(
                  color: _field,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    for (final (i, a)
                        in actividades.whereType<Map>().toList().indexed)
                      _filaActividad(
                        Map<String, dynamic>.from(a),
                        separador: i > 0,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _colorEstado(String estado) {
    final e = estado.toLowerCase();
    if (e.contains('complet') || e.contains('termin') || e.contains('aprob')) {
      return _green;
    }
    if (e.contains('pend') || e.contains('curso') || e.contains('progres')) {
      return _orange;
    }
    if (e.contains('venc') || e.contains('reprob') || e.contains('fall')) {
      return _red;
    }
    return _muted;
  }

  Widget _filaActividad(Map<String, dynamic> a, {required bool separador}) {
    final estado = '${a['estado'] ?? 'Sin estado'}';
    final color = _colorEstado(estado);

    return Column(
      children: [
        if (separador) Container(height: 0.5, color: _border),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${a['tipo'] ?? 'Sin tipo'}'.toUpperCase(),
                      style: _t(11, w: FontWeight.w600, c: _muted, ls: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text('${a['actividad'] ?? 'Sin nombre'}', style: _t(16)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  estado,
                  style: _t(12, w: FontWeight.w600, c: color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ Datos derivados ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
  String _idBloque(Map<String, dynamic> b) =>
      b['horario_id']?.toString() ?? '${b['materia']}|${b['horario']}';

  int _total(Map<String, dynamic> b) {
    final todos = b['alumnos'];
    return int.tryParse('${b['total_alumnos']}') ??
        (todos is List ? todos.length : 0);
  }

  List<Map<String, dynamic>> _alumnosDe(Map<String, dynamic> bloque) {
    return (bloque['alumnos'] as List? ?? [])
        .whereType<Map>()
        .map((a) => Map<String, dynamic>.from(a))
        .where(
          (a) =>
              _busqueda.isEmpty ||
              '${a['nombre_completo']} ${a['numero_control']} ${a['email']}'
                  .toLowerCase()
                  .contains(_busqueda),
        )
        .toList();
  }

  // Ordena por hora de inicio, como un calendario.
  List<Map<String, dynamic>> _ordenados() {
    final lista = _bloques.asMap().entries.toList();

    lista.sort((a, b) {
      final ra = _leerRango(a.value['horario']);
      final rb = _leerRango(b.value['horario']);
      if (ra == null && rb == null) return a.key.compareTo(b.key);
      if (ra == null) return 1;
      if (rb == null) return -1;
      final c = ra.inicio.compareTo(rb.inicio);
      return c != 0 ? c : a.key.compareTo(b.key);
    });

    return lista.map((e) => e.value).toList();
  }

  // ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ Widgets ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
  Widget _cabecera() {
    final totalAlumnos = _bloques.fold<int>(0, (s, b) => s + _total(b));
    final n = _bloques.length;

    final resumen = n == 0
        ? 'Sin horarios todav├¡a'
        : '$n ${n == 1 ? 'horario' : 'horarios'} ┬À '
              '$totalAlumnos ${totalAlumnos == 1 ? 'alumno' : 'alumnos'}';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mis horarios', style: _t(30, w: FontWeight.w700, ls: -0.6)),
              const SizedBox(height: 2),
              Text(resumen, style: _t(14, c: _muted)),
            ],
          ),
        ),
        _BotonRedondo(
          icono: CupertinoIcons.arrow_clockwise,
          cargando: _cargando,
          onTap: _cargando || _guardando ? null : _cargar,
        ),
        const SizedBox(width: 10),
        _BotonRedondo(
          icono: CupertinoIcons.plus,
          relleno: true,
          onTap: _guardando || _cargando ? null : _crear,
        ),
      ],
    );
  }

  Widget _campoBusqueda() => CupertinoSearchTextField(
    controller: _buscador,
    placeholder: 'Buscar alumnos',
    style: _t(16),
    placeholderStyle: _t(16, c: _muted),
    itemColor: _muted,
    backgroundColor: _card,
    borderRadius: BorderRadius.circular(12),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
    onChanged: (v) => setState(() => _busqueda = v.trim().toLowerCase()),
    onSuffixTap: () {
      _buscador.clear();
      setState(() => _busqueda = '');
    },
  );

  Widget _vistaError() => Container(
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border),
    ),
    child: Column(
      children: [
        Icon(
          CupertinoIcons.exclamationmark_triangle_fill,
          color: _red,
          size: 32,
        ),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center, style: _t(15)),
        const SizedBox(height: 16),
        _Pildora(
          texto: 'Reintentar',
          icono: CupertinoIcons.arrow_clockwise,
          relleno: false,
          onTap: _cargar,
        ),
      ],
    ),
  );

  Widget _vistaVacia() => Container(
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border),
    ),
    child: Column(
      children: [
        const Icon(
          CupertinoIcons.calendar_badge_plus,
          color: _orange,
          size: 46,
        ),
        const SizedBox(height: 14),
        Text('Sin horarios', style: _t(20, w: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'Todav├¡a no tienes horarios de clase. '
          'Crea tu primer bloque de hora + materia.',
          textAlign: TextAlign.center,
          style: _t(15, c: _muted),
        ),
        const SizedBox(height: 20),
        _Pildora(
          texto: 'Crear horario',
          icono: CupertinoIcons.plus,
          onTap: _guardando ? null : _crear,
        ),
      ],
    ),
  );

  Widget _bloque(Map<String, dynamic> bloque) {
    final id = _idBloque(bloque);
    final rango = _leerRango(bloque['horario']);
    final materia = '${bloque['materia'] ?? 'Sin materia'}';
    final color = _colorPara(materia);
    final alumnos = _alumnosDe(bloque);
    final total = _total(bloque);
    final buscando = _busqueda.isNotEmpty;
    final abierto = buscando || _abiertos.contains(id);

    final duracion = rango?.duracion ?? '';
    final subtitulo =
        '$total ${total == 1 ? 'alumno' : 'alumnos'}'
        '${duracion.isEmpty ? '' : ' ┬À $duracion'}';

    final cabecera = _Tap(
      onTap: buscando
          ? null
          : () {
              HapticFeedback.selectionClick();
              setState(() {
                if (!_abiertos.remove(id)) _abiertos.add(id);
              });
            },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            SizedBox(
              width: 86,
              child: rango == null
                  ? Text(
                      '${bloque['horario'] ?? 'ÔÇö'}',
                      style: _t(13, w: FontWeight.w600),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: _horaCorta(rango.inicio),
                                style: _t(21, w: FontWeight.w700, ls: -0.4),
                              ),
                              TextSpan(
                                text: ' ${_periodo(rango.inicio)}',
                                style: _t(11, w: FontWeight.w600, c: _muted),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          softWrap: false,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_horaCorta(rango.fin)} ${_periodo(rango.fin)}',
                          style: _t(13, c: _muted),
                        ),
                      ],
                    ),
            ),
            Container(
              width: 4,
              height: 42,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materia,
                    style: _t(17, w: FontWeight.w600, ls: -0.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.person_2_fill,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          subtitulo,
                          style: _t(13, c: _muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _Tap(
              onTap: _guardando ? null : () => _acciones(bloque),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  CupertinoIcons.ellipsis_circle,
                  size: 24,
                  color: _muted,
                ),
              ),
            ),
            AnimatedRotation(
              turns: abierto ? 0.25 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Icon(
                CupertinoIcons.chevron_right,
                size: 18,
                color: _muted,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );

    final cuerpo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 0.5, color: _border),
        if (alumnos.isEmpty)
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(CupertinoIcons.person_2, color: _muted, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    buscando
                        ? 'No hay alumnos que coincidan con la b├║squeda.'
                        : 'A├║n no hay alumnos vinculados a este horario.',
                    style: _t(14, c: _muted),
                  ),
                ),
              ],
            ),
          )
        else
          for (var i = 0; i < alumnos.length; i++)
            _filaAlumno(alumnos[i], ultimo: i == alumnos.length - 1),
        const SizedBox(height: 4),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Dismissible(
        key: ValueKey('bloque-$id'),
        direction: _guardando
            ? DismissDirection.none
            : DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 26),
          decoration: BoxDecoration(
            color: const Color(0xFFFF453A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(CupertinoIcons.trash, color: Colors.white),
        ),
        // La tarjeta regresa a su sitio; el borrado real lo hace _eliminar
        // despu├®s de que el servidor confirme.
        confirmDismiss: (_) async {
          unawaited(_eliminar(bloque));
          return false;
        },
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cabecera,
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: abierto
                    ? cuerpo
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filaAlumno(Map<String, dynamic> a, {required bool ultimo}) {
    final nombre = '${a['nombre_completo'] ?? 'Sin nombre'}';
    final control = a['numero_control'];
    final xp = a['xp_total'];

    return Column(
      children: [
        _Tap(
          onTap: () => _historial(a),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            child: Row(
              children: [
                _Avatar(nombre: nombre, tamano: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: _t(16, w: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'N.┬║ de control: ${control ?? 'No disponible'}',
                        style: _t(13, c: _muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (xp != null) ...[
                  _PildoraXp(xp: '$xp'),
                  const SizedBox(width: 6),
                ],
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 15,
                  color: _muted.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
        if (!ultimo)
          Padding(
            padding: const EdgeInsets.only(left: 66),
            child: Container(height: 0.5, color: _border),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    final ordenados = _ordenados();
    final visibles = _busqueda.isEmpty
        ? ordenados
        : ordenados.where((b) => _alumnosDe(b).isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cabecera(),
        if (_bloques.isNotEmpty && _error == null) ...[
          const SizedBox(height: 16),
          _campoBusqueda(),
        ],
        if (_cargando && _bloques.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 56),
            child: Center(
              child: CupertinoActivityIndicator(radius: 14, color: _muted),
            ),
          )
        else if (_error != null)
          _vistaError()
        else if (_bloques.isEmpty)
          _vistaVacia()
        else if (visibles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Sin resultados para ÔÇ£${_buscador.text.trim()}ÔÇØ',
                style: _t(15, c: _muted),
              ),
            ),
          )
        else
          ...visibles.map(_bloque),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ Hoja para crear horario ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
class _NuevoHorarioSheet extends StatefulWidget {
  const _NuevoHorarioSheet();

  @override
  State<_NuevoHorarioSheet> createState() => _NuevoHorarioSheetState();
}

class _NuevoHorarioSheetState extends State<_NuevoHorarioSheet> {
  // Los controladores viven aqu├¡, as├¡ se liberan solo cuando la hoja
  // termina de cerrarse (evita usar un controller ya descartado).
  final TextEditingController _materia = TextEditingController();
  late int _inicio;
  late int _fin;
  String? _editando; // 'inicio' | 'fin' | null

  @override
  void initState() {
    super.initState();
    final h = DateTime.now().hour;
    final base = (h >= 21 || h < 5) ? 7 : h + 1;
    _inicio = base * 60;
    _fin = _inicio + 60;
  }

  @override
  void dispose() {
    _materia.dispose();
    super.dispose();
  }

  bool get _valido => _materia.text.trim().isNotEmpty && _fin > _inicio;

  void _guardar() {
    if (!_valido) return;
    HapticFeedback.lightImpact();

    Navigator.pop<Map<String, String>>(context, {
      'materia': _materia.text.trim(),
      'horario': '${_formatoHora(_inicio)} ÔÇô ${_formatoHora(_fin)}',
    });
  }

  Widget _filaHora({
    required String clave,
    required String etiqueta,
    required IconData icono,
    required Color color,
    required int minutos,
    required ValueChanged<int> alCambiar,
  }) {
    final activo = _editando == clave;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Tap(
          onTap: () {
            FocusScope.of(context).unfocus();
            HapticFeedback.selectionClick();
            setState(() => _editando = activo ? null : clave);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(etiqueta, style: _t(17)),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: activo ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    _formatoHora(minutos),
                    style: _t(17, c: activo ? _orange : Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: activo
              ? _SelectorHora(
                  key: ValueKey(clave),
                  minutos: minutos,
                  alCambiar: alCambiar,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    final invalido = _fin <= _inicio;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: CupertinoTheme(
        data: const CupertinoThemeData(
          brightness: Brightness.dark,
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 21,
            ),
          ),
        ),
        child: _Hoja(
          titulo: 'Nuevo horario',
          izquierda: _Tap(
            onTap: () => Navigator.pop(context),
            child: Text('Cancelar', style: _t(17, c: _orange)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: _field,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: CupertinoTextField(
                  controller: _materia,
                  placeholder: 'Materia (Ej. Programaci├│n)',
                  placeholderStyle: _t(17, c: _muted),
                  style: _t(17),
                  cursorColor: _orange,
                  maxLength: 120,
                  decoration: null,
                  padding: const EdgeInsets.all(16),
                  clearButtonMode: OverlayVisibilityMode.editing,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onTap: () => setState(() => _editando = null),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: _field,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _filaHora(
                      clave: 'inicio',
                      etiqueta: 'Inicio',
                      icono: CupertinoIcons.play_fill,
                      color: _green,
                      minutos: _inicio,
                      alCambiar: (v) => setState(() {
                        _inicio = v;
                        if (_fin <= _inicio)
                          _fin = math.min(_inicio + 60, 1439);
                      }),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 56),
                      child: Container(height: 0.5, color: _border),
                    ),
                    _filaHora(
                      clave: 'fin',
                      etiqueta: 'T├®rmino',
                      icono: CupertinoIcons.stop_fill,
                      color: const Color(0xFFFF453A),
                      minutos: _fin,
                      alCambiar: (v) => setState(() => _fin = v),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
                child: Text(
                  invalido
                      ? 'La hora de t├®rmino debe ser posterior a la de inicio.'
                      : 'Duraci├│n: ${_Rango(_inicio, _fin).duracion}',
                  style: _t(13, c: invalido ? _red : _muted),
                ),
              ),
              const SizedBox(height: 20),
              _Pildora(
                texto: 'Crear horario',
                ancho: true,
                onTap: _valido ? _guardar : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ Piezas reutilizables ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
class _Hoja extends StatelessWidget {
  const _Hoja({
    required this.titulo,
    required this.child,
    this.izquierda,
    this.derecha,
  });

  final String titulo;
  final Widget child;
  final Widget? izquierda;
  final Widget? derecha;

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: _sheet,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          // Borde uniforme: los bordes parciales no admiten esquinas redondeadas.
          border: Border.all(color: _border),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _muted.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (izquierda != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: izquierda,
                        ),
                      Text(titulo, style: _t(17, w: FontWeight.w600)),
                      if (derecha != null)
                        Align(alignment: Alignment.centerRight, child: derecha),
                    ],
                  ),
                ),
                Flexible(child: SingleChildScrollView(child: child)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Respuesta t├íctil estilo iOS: se aten├║a mientras se presiona.
class _Tap extends StatefulWidget {
  const _Tap({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> {
  bool _presionado = false;

  void _marcar(bool valor) {
    if (widget.onTap == null) return;
    setState(() => _presionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _marcar(true),
      onTapUp: (_) => _marcar(false),
      onTapCancel: () => _marcar(false),
      onTap: widget.onTap,
      child: AnimatedOpacity(
        opacity: _presionado ? 0.5 : 1,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({
    required this.icono,
    required this.onTap,
    this.relleno = false,
    this.cargando = false,
  });

  final IconData icono;
  final VoidCallback? onTap;
  final bool relleno;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null && !cargando ? 0.4 : 1,
      child: _Tap(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: relleno ? _orange : _card,
            border: relleno ? null : Border.all(color: _border),
          ),
          child: Center(
            child: cargando
                ? CupertinoActivityIndicator(radius: 9, color: _muted)
                : Icon(
                    icono,
                    size: 20,
                    color: relleno ? Colors.black : _orange,
                  ),
          ),
        ),
      ),
    );
  }
}

class _Pildora extends StatelessWidget {
  const _Pildora({
    required this.texto,
    required this.onTap,
    this.icono,
    this.relleno = true,
    this.ancho = false,
  });

  final String texto;
  final VoidCallback? onTap;
  final IconData? icono;
  final bool relleno;
  final bool ancho;

  @override
  Widget build(BuildContext context) {
    final fg = relleno ? Colors.black : _orange;

    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: _Tap(
        onTap: onTap,
        child: Container(
          width: ancho ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: relleno ? _orange : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: relleno ? null : Border.all(color: _orange),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icono != null) ...[
                Icon(icono, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                texto,
                style: _t(16, w: FontWeight.w600, c: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.nombre, required this.tamano});

  final String nombre;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final color = _colorPara(nombre);

    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
      ),
      child: Text(
        _iniciales(nombre),
        style: _t(tamano * 0.38, w: FontWeight.w700, c: color),
      ),
    );
  }
}

class _PildoraXp extends StatelessWidget {
  const _PildoraXp({required this.xp});

  final String xp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _yellow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.bolt_fill, size: 12, color: _yellow),
          const SizedBox(width: 3),
          Text(
            '$xp XP',
            style: _t(12, w: FontWeight.w600, c: _yellow),
          ),
        ],
      ),
    );
  }
}

class _Toast extends StatefulWidget {
  const _Toast({
    required this.mensaje,
    required this.error,
    required this.alTerminar,
  });

  final String mensaje;
  final bool error;
  final VoidCallback alTerminar;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();

    Future.delayed(const Duration(milliseconds: 2600), () async {
      if (!mounted) return;
      await _c.reverse();
      widget.alTerminar();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curva = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 20,
      right: 20,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: curva,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.5),
              end: Offset.zero,
            ).animate(curva),
            child: Material(
              type: MaterialType.transparency,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3550),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.error
                            ? CupertinoIcons.exclamationmark_circle_fill
                            : CupertinoIcons.checkmark_circle_fill,
                        color: widget.error ? _red : _green,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.mensaje,
                          style: _t(15, w: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ Selector de hora (rueda + flechas) ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
// Permite arrastrar la rueda tambi├®n con mouse/trackpad en web y escritorio.
class _ArrastreConMouse extends MaterialScrollBehavior {
  const _ArrastreConMouse();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class _SelectorHora extends StatefulWidget {
  const _SelectorHora({
    super.key,
    required this.minutos,
    required this.alCambiar,
  });

  final int minutos;
  final ValueChanged<int> alCambiar;

  @override
  State<_SelectorHora> createState() => _SelectorHoraState();
}

class _SelectorHoraState extends State<_SelectorHora> {
  static const _wHora = 76.0;
  static const _wDos = 16.0;
  static const _wMin = 76.0;
  static const _wGap = 8.0;
  static const _wPer = 80.0;
  static const _alto = 44.0;
  static const _suave = Duration(milliseconds: 200);

  late int _h12;
  late int _min;
  late int _pm;
  late final FixedExtentScrollController _ch;
  late final FixedExtentScrollController _cm;
  late final FixedExtentScrollController _cp;

  @override
  void initState() {
    super.initState();
    final h24 = widget.minutos ~/ 60;
    _h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    _min = widget.minutos % 60;
    _pm = h24 >= 12 ? 1 : 0;

    _ch = FixedExtentScrollController(initialItem: _h12 - 1);
    _cm = FixedExtentScrollController(initialItem: _min);
    _cp = FixedExtentScrollController(initialItem: _pm);
  }

  @override
  void dispose() {
    _ch.dispose();
    _cm.dispose();
    _cp.dispose();
    super.dispose();
  }

  void _emitir() {
    final h24 = (_h12 % 12) + (_pm == 1 ? 12 : 0);
    widget.alCambiar(h24 * 60 + _min);
  }

  // Las flechas animan la rueda en lugar de saltar de golpe.
  void _mover(FixedExtentScrollController c, int d) {
    if (!c.hasClients) return;
    c.animateToItem(
      c.selectedItem + d,
      duration: _suave,
      curve: Curves.easeOutCubic,
    );
  }

  void _alternarPeriodo() {
    if (!_cp.hasClients) return;
    _cp.animateToItem(
      _pm == 1 ? 0 : 1,
      duration: _suave,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _rueda({
    required FixedExtentScrollController c,
    required int cantidad,
    required bool bucle,
    required double ancho,
    required String Function(int) texto,
    required ValueChanged<int> alCambiar,
  }) {
    return SizedBox(
      width: ancho,
      height: _alto * 3,
      child: CupertinoPicker(
        scrollController: c,
        itemExtent: _alto,
        looping: bucle,
        diameterRatio: 2.4,
        squeeze: 1.0,
        useMagnifier: true,
        magnification: 1.08,
        selectionOverlay: null,
        onSelectedItemChanged: (i) {
          HapticFeedback.selectionClick();
          alCambiar(((i % cantidad) + cantidad) % cantidad);
          _emitir();
        },
        children: List.generate(
          cantidad,
          (i) => Center(
            child: Text(texto(i), style: _t(30, w: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _filaFlechas({required bool arriba}) {
    final icono = arriba
        ? CupertinoIcons.chevron_up
        : CupertinoIcons.chevron_down;
    final d = arriba ? 1 : -1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: _wHora,
          child: Center(
            child: _Flecha(icono: icono, alPulsar: () => _mover(_ch, d)),
          ),
        ),
        const SizedBox(width: _wDos),
        SizedBox(
          width: _wMin,
          child: Center(
            child: _Flecha(icono: icono, alPulsar: () => _mover(_cm, d)),
          ),
        ),
        const SizedBox(width: _wGap),
        SizedBox(
          width: _wPer,
          child: Center(
            child: _Flecha(icono: icono, alPulsar: _alternarPeriodo),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _ArrastreConMouse(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _filaFlechas(arriba: true),
            const SizedBox(height: 4),
            Stack(
              alignment: Alignment.center,
              children: [
                // Una sola franja de selecci├│n para las tres ruedas.
                Container(
                  height: _alto,
                  width: _wHora + _wDos + _wMin + _wGap + _wPer + 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _rueda(
                      c: _ch,
                      cantidad: 12,
                      bucle: true,
                      ancho: _wHora,
                      texto: (i) => _dos(i + 1),
                      alCambiar: (i) => _h12 = i + 1,
                    ),
                    SizedBox(
                      width: _wDos,
                      child: Center(
                        child: Text(
                          ':',
                          style: _t(30, w: FontWeight.w700, c: _muted),
                        ),
                      ),
                    ),
                    _rueda(
                      c: _cm,
                      cantidad: 60,
                      bucle: true,
                      ancho: _wMin,
                      texto: _dos,
                      alCambiar: (i) => _min = i,
                    ),
                    const SizedBox(width: _wGap),
                    _rueda(
                      c: _cp,
                      cantidad: 2,
                      bucle: false,
                      ancho: _wPer,
                      texto: (i) => i == 0 ? 'AM' : 'PM',
                      alCambiar: (i) => _pm = i,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            _filaFlechas(arriba: false),
          ],
        ),
      ),
    );
  }
}

// Flecha que repite la acci├│n mientras se mantiene presionada.
class _Flecha extends StatefulWidget {
  const _Flecha({required this.icono, required this.alPulsar});

  final IconData icono;
  final VoidCallback alPulsar;

  @override
  State<_Flecha> createState() => _FlechaState();
}

class _FlechaState extends State<_Flecha> {
  Timer? _espera;
  Timer? _repetir;
  bool _presionada = false;

  void _iniciar() {
    widget.alPulsar();
    setState(() => _presionada = true);
    _espera = Timer(const Duration(milliseconds: 400), () {
      _repetir = Timer.periodic(
        const Duration(milliseconds: 140),
        (_) => widget.alPulsar(),
      );
    });
  }

  void _detener() {
    _espera?.cancel();
    _repetir?.cancel();
    if (mounted && _presionada) setState(() => _presionada = false);
  }

  @override
  void dispose() {
    _espera?.cancel();
    _repetir?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _iniciar(),
      onTapUp: (_) => _detener(),
      onTapCancel: _detener,
      onLongPressEnd: (_) => _detener(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 56,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _presionada ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(widget.icono, size: 20, color: _orange),
      ),
    );
  }
}
