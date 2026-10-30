import '../../theme/unix_theme.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InstructorHorariosPage extends StatefulWidget {
  const InstructorHorariosPage({super.key});
  @override
  State<InstructorHorariosPage> createState() => _InstructorHorariosPageState();
}

class _InstructorHorariosPageState extends State<InstructorHorariosPage> {
  // Mismo prefijo que perfil/me/ en InstructorPage.
  static const _url = 'http://127.0.0.1:8000/api/auth/instructor/horarios/';
  static Color get _card => UnixColors.adapt(Color(0xFF0A2947));
  static Color get _border => UnixColors.border;
  static const _orange = Color(0xFFFF8A24);
  static Color get _muted => UnixColors.adapt(Color(0xFF91A9BE));
  static Color get _red => UnixColors.adapt(Color(0xFFFF6577));
  List<Map<String, dynamic>> _bloques = [];
  bool _cargando = true;
  bool _guardando = false;
  String? _error;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.trim().isEmpty) {
      throw Exception('Inicia sesión para consultar tus horarios.');
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
        'El servidor devolvió una respuesta inesperada (${response.statusCode}).',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        throw Exception('Tu sesión venció. Vuelve a ingresar.');
      }
      final mensaje = body is Map
          ? (body['error'] ?? body['detail'] ?? body.values.join('\n'))
          : 'No se pudo completar la petición (${response.statusCode}).';
      throw Exception(mensaje.toString());
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
          .timeout(Duration(seconds: 20));
      final body = _respuesta(response);
      if (body is! Map || body['bloques_horarios'] is! List) {
        throw Exception(
          'No se encontró la lista de bloques horarios en la respuesta.',
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
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _crear() async {
    if (_guardando) return;

    final formKey = GlobalKey<FormState>();

    String materia = '';
    String inicio = '';
    String termino = '';
    String periodo = 'AM';

    String? validarHora(String? valor) {
      final texto = valor?.trim() ?? '';

      if (texto.isEmpty) {
        return 'Escribe la hora.';
      }

      // Formato de 12 horas: 1:00, 08:30, 12:45...
      final formato = RegExp(r'^(0?[1-9]|1[0-2]):[0-5][0-9]$');

      if (!formato.hasMatch(texto)) {
        return 'Usa el formato 08:30.';
      }

      return null;
    }

    int minutos(String hora) {
      final partes = hora.trim().split(':');
      final horas = int.parse(partes[0]) % 12;
      final minutos = int.parse(partes[1]);

      return horas * 60 + minutos;
    }

    String formatearHora(String hora) {
      final partes = hora.trim().split(':');

      return '${partes[0].padLeft(2, '0')}:${partes[1]}';
    }

    final datos = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        UnixTheme.watch(dialogContext);
        return AlertDialog(
          backgroundColor: _card,
          title: Text(
            'Nuevo horario de clase',
            style: TextStyle(color: UnixColors.text),
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      maxLength: 120,
                      style: TextStyle(color: UnixColors.text),
                      decoration: _campo('Materia', 'Ej. Programación'),
                      onChanged: (valor) => materia = valor,
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'Escribe la materia.';
                        }

                        return null;
                      },
                    ),
                    SizedBox(height: 12),

                    TextFormField(
                      style: TextStyle(color: UnixColors.text),
                      keyboardType: TextInputType.datetime,
                      decoration: _campo('Hora de inicio', 'Ej. 08:00'),
                      onChanged: (valor) => inicio = valor,
                      validator: validarHora,
                    ),
                    SizedBox(height: 16),

                    TextFormField(
                      style: TextStyle(color: UnixColors.text),
                      keyboardType: TextInputType.datetime,
                      decoration: _campo('Hora de término', 'Ej. 09:30'),
                      onChanged: (valor) => termino = valor,
                      validator: (valor) {
                        final error = validarHora(valor);

                        if (error != null) return error;

                        if (validarHora(inicio) == null &&
                            minutos(valor!) <= minutos(inicio)) {
                          return 'Debe ser posterior a la hora de inicio.';
                        }

                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: 'AM',
                      dropdownColor: _card,
                      style: TextStyle(color: UnixColors.text),
                      decoration: _campo('AM / PM', 'Selecciona el período'),
                      items: [
                        DropdownMenuItem(
                          value: 'AM',
                          child: Text('AM — Mañana'),
                        ),
                        DropdownMenuItem(
                          value: 'PM',
                          child: Text('PM — Tarde / Noche'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) periodo = valor;
                      },
                    ),
                    SizedBox(height: 10),
                    Text(
                      'El período seleccionado se aplica a ambas horas.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                final horario =
                    '${formatearHora(inicio)} – '
                    '${formatearHora(termino)} $periodo';

                Navigator.pop<Map<String, String>>(dialogContext, {
                  'materia': materia.trim(),
                  'horario': horario,
                });
              },
              child: Text('Crear horario'),
            ),
          ],
        );
      },
    );

    if (datos == null || !mounted || _guardando) return;

    setState(() => _guardando = true);

    try {
      final headers = await _headers();

      final response = await http
          .post(Uri.parse(_url), headers: headers, body: jsonEncode(datos))
          .timeout(Duration(seconds: 20));

      _respuesta(response);

      if (!mounted) return;

      _aviso('Horario creado correctamente.');
      await _cargar();
    } catch (error) {
      _aviso(_mensaje(error));
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  Future<void> _eliminar(Map<String, dynamic> bloque) async {
    if (_guardando) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        UnixTheme.watch(dialogContext);
        return AlertDialog(
          backgroundColor: _card,
          title: Text(
            'Eliminar horario',
            style: TextStyle(color: UnixColors.text),
          ),
          content: Text(
            '¿Eliminar ${bloque['materia']} (${bloque['horario']})?\n\nLos alumnos vinculados tendrán que elegir otro horario.',
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
              child: Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmar != true || !mounted || _guardando) return;
    setState(() => _guardando = true);
    try {
      final id = bloque['horario_id'];
      if (id == null) throw Exception('Este horario no tiene ID.');
      final headers = await _headers();
      final response = await http
          .delete(
            Uri.parse('$_url${Uri.encodeComponent(id.toString())}/'),
            headers: headers,
          )
          .timeout(Duration(seconds: 20));
      _respuesta(response);
      if (!mounted) return;
      _aviso('Horario eliminado correctamente.');
      await _cargar();
    } catch (error) {
      _aviso(_mensaje(error));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // El backend enviado todavía no devuelve XP ni historial.
  // Este adaptador permite mostrarlos cuando se incluyan en cada alumno:
  // xp_total y actividades: [{tipo, actividad, estado}]. No inventa valores.
  Future<void> _historial(Map<String, dynamic> alumno) async {
    final actividades = alumno['actividades'];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        UnixTheme.watch(dialogContext);
        return AlertDialog(
          backgroundColor: _card,
          title: Text(
            'Historial de ${alumno['nombre_completo'] ?? 'alumno'}',
            style: TextStyle(color: UnixColors.text),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (actividades is! List)
                    Text(
                      'El servidor todavía no proporciona el historial de actividades.',
                      style: TextStyle(color: _muted),
                    )
                  else if (actividades.isEmpty)
                    Text(
                      'No hay ninguna actividad activa',
                      style: TextStyle(color: _muted),
                    )
                  else
                    for (final actividad in actividades.whereType<Map>())
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          "(${actividad['tipo'] ?? 'Sin tipo'}) ${actividad['actividad'] ?? 'Sin nombre'}: ${actividad['estado'] ?? 'Sin estado'}",
                          style: TextStyle(color: UnixColors.text),
                        ),
                      ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _campo(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: TextStyle(color: _muted),
    hintStyle: TextStyle(color: _muted),
    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _border)),
    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _orange)),
    border: OutlineInputBorder(),
  );

  Widget _bloque(Map<String, dynamic> bloque) {
    final alumnos = (bloque['alumnos'] as List? ?? [])
        .whereType<Map>()
        .map((a) => Map<String, dynamic>.from(a))
        .where(
          (a) => '${a['nombre_completo']} ${a['numero_control']} ${a['email']}'
              .toLowerCase()
              .contains(_busqueda),
        )
        .toList();
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: _orange),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${bloque['horario'] ?? ''} · ${bloque['materia'] ?? ''}',
                      style: TextStyle(
                        color: UnixColors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '${bloque['total_alumnos'] ?? 0} alumnos vinculados',
                      style: TextStyle(color: _muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Eliminar horario',
                onPressed: _guardando ? null : () => _eliminar(bloque),
                icon: Icon(Icons.delete_outline, color: _red),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (alumnos.isEmpty)
            Text(
              _busqueda.isEmpty
                  ? 'Aún no hay alumnos vinculados a este horario.'
                  : 'No hay alumnos que coincidan con la búsqueda.',
              style: TextStyle(color: _muted),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: _border),
                child: DataTable(
                  headingTextStyle: TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.bold,
                  ),
                  dataTextStyle: TextStyle(color: UnixColors.text),
                  columns: [
                    DataColumn(label: Text('Alumno')),
                    DataColumn(label: Text('N.º de control')),
                    DataColumn(label: Text('XP')),
                    DataColumn(label: Text('Historial')),
                  ],
                  rows: alumnos
                      .map(
                        (a) => DataRow(
                          cells: [
                            DataCell(
                              Text('${a['nombre_completo'] ?? 'Sin nombre'}'),
                            ),
                            DataCell(
                              Text('${a['numero_control'] ?? 'No disponible'}'),
                            ),
                            DataCell(
                              Text('${a['xp_total'] ?? 'No disponible'}'),
                            ),
                            DataCell(
                              OutlinedButton(
                                onPressed: () => _historial(a),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _orange,
                                  side: BorderSide(color: _orange),
                                ),
                                child: Text('Ver Historial'),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: _guardando || _cargando ? null : _crear,
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.black,
              ),
              icon: Icon(Icons.add),
              label: Text(_guardando ? 'Guardando…' : 'Crear horario'),
            ),
            OutlinedButton.icon(
              onPressed: _cargando || _guardando ? null : _cargar,
              style: OutlinedButton.styleFrom(
                foregroundColor: _orange,
                side: BorderSide(color: _orange),
              ),
              icon: Icon(Icons.refresh),
              label: Text('Actualizar'),
            ),
          ],
        ),
        SizedBox(height: 16),
        TextField(
          style: TextStyle(color: UnixColors.text),
          decoration: _campo(
            'Buscar alumnos',
            'Nombre, número de control o correo',
          ),
          onChanged: (v) => setState(() => _busqueda = v.trim().toLowerCase()),
        ),
        SizedBox(height: 12),
        if (_cargando)
          Center(child: CircularProgressIndicator(color: _orange))
        else if (_error != null) ...[
          Text(_error!, style: TextStyle(color: _red)),
          TextButton(onPressed: _cargar, child: Text('Reintentar')),
        ] else if (_bloques.isEmpty)
          Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Todavía no tienes horarios de clase. Crea tu primer bloque de hora + materia.',
              style: TextStyle(color: _muted),
            ),
          )
        else
          ..._bloques.map(_bloque),
      ],
    );
  }
}
