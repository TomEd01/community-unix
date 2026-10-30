import '../../theme/unix_theme.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Vínculo real del alumno autenticado. No utiliza datos de demostración.
class AlumnoVinculoProfesor extends StatefulWidget {
  const AlumnoVinculoProfesor({super.key});
  @override
  State<AlumnoVinculoProfesor> createState() => _AlumnoVinculoProfesorState();
}

class _AlumnoVinculoProfesorState extends State<AlumnoVinculoProfesor>
    with WidgetsBindingObserver {
  static const _base = 'http://127.0.0.1:8000/api/auth/alumno';
  static Color get _card => UnixColors.adapt(Color(0xFF0A2947));
  static Color get _border => UnixColors.border;
  static const _orange = Color(0xFFFF8A24);
  static Color get _muted => UnixColors.adapt(Color(0xFF91A9BE));
  static Color get _red => UnixColors.adapt(Color(0xFFFF6577));
  static Color get _green => UnixColors.adapt(Color(0xFF35D59A));
  final _buscador = TextEditingController();
  Timer? _timer;
  bool _consultando = false;
  bool _cargandoCatalogo = false;
  bool _guardando = false;
  bool _enPrimerPlano = true;
  Map<String, dynamic>? _vinculo;
  List<Map<String, dynamic>> _profesores = [];
  String? _errorVinculo;
  String? _errorCatalogo;
  String? _instructorId;
  String? _horarioId;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _actualizar();
    _timer = Timer.periodic(Duration(seconds: 30), (_) {
      if (_enPrimerPlano && !_guardando) _consultarVinculo();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _buscador.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _enPrimerPlano = state == AppLifecycleState.resumed;
    if (_enPrimerPlano && !_guardando) _actualizar();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.trim().isEmpty) {
      throw Exception('Inicia sesión para consultar tu profesor.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  dynamic _leer(http.Response response) {
    dynamic body;
    try {
      if (response.bodyBytes.isNotEmpty) {
        body = jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {
      throw Exception(
        'Respuesta inesperada del servidor (${response.statusCode}).',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        throw Exception('Tu sesión venció. Vuelve a ingresar.');
      }
      throw Exception(
        body is Map
            ? (body['error'] ?? body['detail'] ?? body.values.join('\n'))
                  .toString()
            : 'No se pudo completar la petición (${response.statusCode}).',
      );
    }
    return body;
  }

  String _mensaje(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
  void _aviso(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _actualizar() async {
    await Future.wait([_consultarVinculo(), _cargarCatalogo()]);
  }

  Future<void> _consultarVinculo() async {
    if (!mounted || _consultando) return;
    setState(() => _consultando = true);
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$_base/mi-vinculo/'), headers: headers)
          .timeout(Duration(seconds: 20));
      final body = _leer(response);
      if (body is! Map ||
          body['vinculado'] is! bool ||
          body['horario_eliminado'] is! bool) {
        throw Exception(
          'El servidor no devolvió un estado de vinculación válido.',
        );
      }
      if (!mounted) return;
      final eliminadoAntes = _vinculo?['horario_eliminado'] == true;
      setState(() {
        _vinculo = Map<String, dynamic>.from(body);
        _errorVinculo = null;
      });
      if (!eliminadoAntes && body['horario_eliminado'] == true) {
        // El catálogo se renueva para retirar el grupo que acaba de borrarse.
        await _cargarCatalogo();
      }
    } catch (error) {
      if (mounted) setState(() => _errorVinculo = _mensaje(error));
    } finally {
      if (mounted) setState(() => _consultando = false);
    }
  }

  Future<void> _cargarCatalogo() async {
    if (!mounted || _cargandoCatalogo) return;
    setState(() => _cargandoCatalogo = true);
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$_base/profesores/'), headers: headers)
          .timeout(Duration(seconds: 20));
      final body = _leer(response);
      if (body is! List)
        throw Exception('No se recibió el catálogo de profesores.');
      final lista = body
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        _profesores = lista;
        _errorCatalogo = null;
        if (!_profesores.any((p) => '${p['instructor_id']}' == _instructorId)) {
          _instructorId = null;
          _horarioId = null;
        }
        if (!_horarios.any((h) => '${h['horario_id']}' == _horarioId))
          _horarioId = null;
      });
    } catch (error) {
      if (mounted) setState(() => _errorCatalogo = _mensaje(error));
    } finally {
      if (mounted) setState(() => _cargandoCatalogo = false);
    }
  }

  List<Map<String, dynamic>> get _horarios {
    for (final p in _profesores) {
      if ('${p['instructor_id']}' == _instructorId) {
        return (p['horarios_disponibles'] as List? ?? [])
            .map((h) => Map<String, dynamic>.from(h as Map))
            .toList();
      }
    }
    return [];
  }

  Future<void> _vincular() async {
    if (_guardando || _consultando || _horarioId == null) return;
    final id = int.tryParse(_horarioId!);
    if (id == null) {
      _aviso('Selecciona un horario válido.');
      return;
    }
    setState(() => _guardando = true);
    try {
      final headers = await _headers();
      final response = await http
          .post(
            Uri.parse('$_base/mi-vinculo/'),
            headers: headers,
            body: jsonEncode({'horario_id': id}),
          )
          .timeout(Duration(seconds: 20));
      _leer(response);
      if (!mounted) return;
      setState(() {
        _vinculo = null;
        _errorVinculo = null;
      });
      _aviso('Te vinculaste correctamente al horario de clase.');
      await _consultarVinculo();
    } catch (error) {
      _aviso(_mensaje(error));
      // Un horario puede haber sido eliminado mientras se elegía.
      await _actualizar();
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _desvincular() async {
    if (_guardando || _consultando) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        UnixTheme.watch(dialogContext);
        return AlertDialog(
          backgroundColor: _card,
          title: Text(
            'Desvincularme del profesor',
            style: TextStyle(color: UnixColors.text),
          ),
          content: Text(
            '¿Seguro que quieres desvincularte? Podrás elegir otro profesor y horario después.',
            style: TextStyle(color: UnixColors.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancelar'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: OutlinedButton.styleFrom(
                foregroundColor: _red,
                side: BorderSide(color: _red),
              ),
              child: Text('Desvincularme'),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmar != true || _guardando || _consultando) return;
    setState(() => _guardando = true);
    try {
      final headers = await _headers();
      final response = await http
          .delete(Uri.parse('$_base/mi-vinculo/'), headers: headers)
          .timeout(Duration(seconds: 20));
      _leer(response);
      if (!mounted) return;
      setState(() {
        _vinculo = null;
        _errorVinculo = null;
        _instructorId = null;
        _horarioId = null;
      });
      _aviso('Te has desvinculado correctamente.');
      await _consultarVinculo();
    } catch (error) {
      _aviso(_mensaje(error));
      await _consultarVinculo();
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  InputDecoration _campo(String titulo) => InputDecoration(
    labelText: titulo,
    labelStyle: TextStyle(color: _muted),
    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _border)),
    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _orange)),
    border: OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    final activo = _vinculo?['vinculado'] == true;
    final eliminado = _vinculo?['horario_eliminado'] == true;
    final ocupado = _guardando || _consultando || _cargandoCatalogo;
    final resultados = _profesores
        .where(
          (p) =>
              '${p['nombre_profesor'] ?? ''}'.toLowerCase().contains(_busqueda),
        )
        .toList();
    // Conserva la selección aunque el alumno cambie el texto de búsqueda.
    final opciones = _profesores
        .where(
          (p) =>
              resultados.contains(p) ||
              '${p['instructor_id']}' == _instructorId,
        )
        .toList();
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, color: _orange),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¿Con qué profesor tomas clase?',
                  style: TextStyle(
                    color: UnixColors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Actualizar vínculo y profesores',
                onPressed: ocupado ? null : _actualizar,
                icon: Icon(Icons.refresh, color: _orange),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (ocupado) LinearProgressIndicator(color: _orange),
          if (_errorVinculo != null) ...[
            SizedBox(height: 10),
            Text(
              'No se pudo comprobar tu vínculo: $_errorVinculo',
              style: TextStyle(color: _red),
            ),
            TextButton(
              onPressed: ocupado ? null : _consultarVinculo,
              child: Text('Reintentar'),
            ),
          ],
          if (eliminado) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: _orange),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ups, al parecer ya no da clases durante este horario, ¿Deseas vincularte con otro profesor?',
                    style: TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_vinculo?['ultimo_registro'] != null) ...[
                    SizedBox(height: 8),
                    Text(
                      'Grupo anterior: ${_vinculo!['ultimo_registro']}',
                      style: TextStyle(color: _muted),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (activo) ...[
            SizedBox(height: 12),
            Text(
              'Profesor vinculado',
              style: TextStyle(color: _green, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              '${_vinculo!['nombre_profesor']}',
              style: TextStyle(color: UnixColors.text, fontSize: 17),
            ),
            Text(
              '${_vinculo!['horario']} · ${_vinculo!['materia']}',
              style: TextStyle(color: _muted),
            ),
          ] else if (_vinculo != null) ...[
            SizedBox(height: 12),
            Text(
              'Aún no estás vinculado con ningún profesor.',
              style: TextStyle(color: _muted),
            ),
          ],
          SizedBox(height: 18),
          TextField(
            controller: _buscador,
            enabled: !_guardando,
            style: TextStyle(color: UnixColors.text),
            decoration: _campo(
              'Buscar instructor por nombre',
            ).copyWith(prefixIcon: Icon(Icons.search, color: _muted)),
            onChanged: (v) =>
                setState(() => _busqueda = v.trim().toLowerCase()),
          ),
          SizedBox(height: 12),
          if (_errorCatalogo != null) ...[
            Text(_errorCatalogo!, style: TextStyle(color: _red)),
            TextButton(
              onPressed: ocupado ? null : _cargarCatalogo,
              child: Text('Recargar profesores'),
            ),
          ] else if (!_cargandoCatalogo && resultados.isEmpty)
            Text(
              _profesores.isEmpty
                  ? 'Todavía no hay profesores con horarios disponibles.'
                  : 'No se encontraron profesores con ese nombre.',
              style: TextStyle(color: _muted),
            ),
          SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey('profesor-$_instructorId'),
            initialValue: _instructorId,
            isExpanded: true,
            dropdownColor: _card,
            style: TextStyle(color: UnixColors.text),
            decoration: _campo('Instructor'),
            items: opciones
                .map(
                  (p) => DropdownMenuItem(
                    value: '${p['instructor_id']}',
                    child: Text(
                      '${p['nombre_profesor']}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: ocupado || _errorCatalogo != null
                ? null
                : (id) => setState(() {
                    _instructorId = id;
                    _horarioId = null;
                  }),
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('horario-$_instructorId-$_horarioId'),
            initialValue: _horarioId,
            isExpanded: true,
            dropdownColor: _card,
            style: TextStyle(color: UnixColors.text),
            decoration: _campo('Horario + Materia'),
            items: _horarios
                .map(
                  (h) => DropdownMenuItem(
                    value: '${h['horario_id']}',
                    child: Text(
                      '${h['etiqueta_completa'] ?? '${h['horario']} - ${h['materia']}'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged:
                ocupado || _instructorId == null || _errorCatalogo != null
                ? null
                : (id) => setState(() => _horarioId = id),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed:
                    ocupado ||
                        _vinculo == null ||
                        _errorVinculo != null ||
                        _errorCatalogo != null ||
                        _horarioId == null
                    ? null
                    : _vincular,
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.black,
                ),
                icon: Icon(Icons.link),
                label: Text(activo ? 'Cambiar de grupo' : 'Vincularme'),
              ),
              if (activo || eliminado)
                OutlinedButton.icon(
                  onPressed: ocupado || _errorVinculo != null
                      ? null
                      : _desvincular,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _red,
                    side: BorderSide(color: _red),
                  ),
                  icon: Icon(Icons.link_off),
                  label: Text('Desvincularme'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
