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
  static const _card = Color(0xFF0A2947);
  static const _border = Color(0xFF174064);
  static const _orange = Color(0xFFFF8A24);
  static const _muted = Color(0xFF91A9BE);
  static const _red = Color(0xFFFF6577);
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
    return {'Authorization': 'Bearer $token',
      'Accept': 'application/json', 'Content-Type': 'application/json'};
  }

  dynamic _respuesta(http.Response response) {
    dynamic body;
    try {
      if (response.bodyBytes.isNotEmpty) {
        body = jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {
      throw Exception('El servidor devolvió una respuesta inesperada (${response.statusCode}).');
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

  String _mensaje(Object error) => error.toString().replaceFirst('Exception: ', '');
  void _aviso(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() { _cargando = true; _error = null; });
    try {
      final headers = await _headers();
      final response = await http.get(Uri.parse(_url), headers: headers)
          .timeout(const Duration(seconds: 20));
      final body = _respuesta(response);
      if (body is! Map || body['bloques_horarios'] is! List) {
        throw Exception('No se encontró la lista de bloques horarios en la respuesta.');
      }
      final bloques = (body['bloques_horarios'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map)).toList();
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
    String materia = '';
    String horario = '';
    final formKey = GlobalKey<FormState>();
    Map<String, String>? datos;
    datos = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: _card,
          title: const Text('Nuevo horario de clase', style: TextStyle(color: Colors.white)),
          content: SizedBox(width: 420, child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(onChanged: (v) => materia = v, maxLength: 120,
                style: const TextStyle(color: Colors.white),
                decoration: _campo('Materia', 'Ej. Programación'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Escribe la materia.' : null),
              const SizedBox(height: 12),
              TextFormField(onChanged: (v) => horario = v, maxLength: 80,
                style: const TextStyle(color: Colors.white),
                decoration: _campo('Horario', 'Ej. Lunes y miércoles, 08:00–09:00'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Escribe el horario.' : null),
            ]),
          )),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.black),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, {'materia': materia.trim(), 'horario': horario.trim()});
                }
              }, child: const Text('Crear horario')),
          ],
        ),
      );
    if (datos == null || !mounted || _guardando) return;
    setState(() => _guardando = true);
    try {
      final headers = await _headers();
      final response = await http.post(Uri.parse(_url), headers: headers, body: jsonEncode(datos))
          .timeout(const Duration(seconds: 20));
      _respuesta(response);
      if (!mounted) return;
      _aviso('Horario creado correctamente.');
      await _cargar();
    } catch (error) { _aviso(_mensaje(error)); }
    finally { if (mounted) setState(() => _guardando = false); }
  }

  Future<void> _eliminar(Map<String, dynamic> bloque) async {
    if (_guardando) return;
    final confirmar = await showDialog<bool>(context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _card,
        title: const Text('Eliminar horario', style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar ${bloque['materia']} (${bloque['horario']})?\n\nLos alumnos vinculados tendrán que elegir otro horario.',
          style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          OutlinedButton(onPressed: () => Navigator.pop(dialogContext, true),
            style: OutlinedButton.styleFrom(foregroundColor: _red, side: const BorderSide(color: _red)),
            child: const Text('Eliminar')),
        ],
      ));
    if (confirmar != true || !mounted || _guardando) return;
    setState(() => _guardando = true);
    try {
      final id = bloque['horario_id'];
      if (id == null) throw Exception('Este horario no tiene ID.');
      final headers = await _headers();
      final response = await http.delete(Uri.parse('$_url${Uri.encodeComponent(id.toString())}/'), headers: headers)
          .timeout(const Duration(seconds: 20));
      _respuesta(response);
      if (!mounted) return;
      _aviso('Horario eliminado correctamente.');
      await _cargar();
    } catch (error) { _aviso(_mensaje(error)); }
    finally { if (mounted) setState(() => _guardando = false); }
  }

  // El backend enviado todavía no devuelve XP ni historial.
  // Este adaptador permite mostrarlos cuando se incluyan en cada alumno:
  // xp_total y actividades: [{tipo, actividad, estado}]. No inventa valores.
  Future<void> _historial(Map<String, dynamic> alumno) async {
    final actividades = alumno['actividades'];
    await showDialog<void>(context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _card,
        title: Text('Historial de ${alumno['nombre_completo'] ?? 'alumno'}', style: const TextStyle(color: Colors.white)),
        content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (actividades is! List)
              const Text('El servidor todavía no proporciona el historial de actividades.', style: TextStyle(color: _muted))
            else if (actividades.isEmpty)
              const Text('No hay ninguna actividad activa', style: TextStyle(color: _muted))
            else
              for (final actividad in actividades.whereType<Map>())
                Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(
                  "(${actividad['tipo'] ?? 'Sin tipo'}) ${actividad['actividad'] ?? 'Sin nombre'}: ${actividad['estado'] ?? 'Sin estado'}",
                  style: const TextStyle(color: Colors.white))),
          ],
        ))),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar'))],
      ));
  }

  InputDecoration _campo(String label, String hint) => InputDecoration(
    labelText: label, hintText: hint,
    labelStyle: const TextStyle(color: _muted), hintStyle: const TextStyle(color: _muted),
    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: _border)),
    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _orange)),
    border: const OutlineInputBorder(),
  );

  Widget _bloque(Map<String, dynamic> bloque) {
    final alumnos = (bloque['alumnos'] as List? ?? []).whereType<Map>()
        .map((a) => Map<String, dynamic>.from(a)).where((a) =>
          '${a['nombre_completo']} ${a['numero_control']} ${a['email']}'.toLowerCase().contains(_busqueda)).toList();
    return Container(
      margin: const EdgeInsets.only(top: 16), padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.schedule, color: _orange), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${bloque['horario'] ?? ''} · ${bloque['materia'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${bloque['total_alumnos'] ?? 0} alumnos vinculados', style: const TextStyle(color: _muted)),
          ])),
          IconButton(tooltip: 'Eliminar horario', onPressed: _guardando ? null : () => _eliminar(bloque),
            icon: const Icon(Icons.delete_outline, color: _red)),
        ]),
        const SizedBox(height: 12),
        if (alumnos.isEmpty)
          Text(_busqueda.isEmpty ? 'Aún no hay alumnos vinculados a este horario.' : 'No hay alumnos que coincidan con la búsqueda.', style: const TextStyle(color: _muted))
        else
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Theme(
            data: Theme.of(context).copyWith(dividerColor: _border),
            child: DataTable(headingTextStyle: const TextStyle(color: _muted, fontWeight: FontWeight.bold),
              dataTextStyle: const TextStyle(color: Colors.white),
              columns: const [DataColumn(label: Text('Alumno')), DataColumn(label: Text('N.º de control')),
                DataColumn(label: Text('XP')), DataColumn(label: Text('Historial'))],
              rows: alumnos.map((a) => DataRow(cells: [
                DataCell(Text('${a['nombre_completo'] ?? 'Sin nombre'}')),
                DataCell(Text('${a['numero_control'] ?? 'No disponible'}')),
                DataCell(Text('${a['xp_total'] ?? 'No disponible'}')),
                DataCell(OutlinedButton(onPressed: () => _historial(a),
                  style: OutlinedButton.styleFrom(foregroundColor: _orange, side: const BorderSide(color: _orange)),
                  child: const Text('Ver Historial'))),
              ])).toList()),
          )),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        FilledButton.icon(onPressed: _guardando || _cargando ? null : _crear,
          style: FilledButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.black),
          icon: const Icon(Icons.add), label: Text(_guardando ? 'Guardando…' : 'Crear horario')),
        OutlinedButton.icon(onPressed: _cargando || _guardando ? null : _cargar,
          style: OutlinedButton.styleFrom(foregroundColor: _orange, side: const BorderSide(color: _orange)),
          icon: const Icon(Icons.refresh), label: const Text('Actualizar')),
      ]),
      const SizedBox(height: 16),
      TextField(style: const TextStyle(color: Colors.white),
        decoration: _campo('Buscar alumnos', 'Nombre, número de control o correo'),
        onChanged: (v) => setState(() => _busqueda = v.trim().toLowerCase())),
      const SizedBox(height: 12),
      if (_cargando) const Center(child: CircularProgressIndicator(color: _orange))
      else if (_error != null) ...[
        Text(_error!, style: const TextStyle(color: _red)),
        TextButton(onPressed: _cargar, child: const Text('Reintentar')),
      ] else if (_bloques.isEmpty)
        const Padding(padding: EdgeInsets.all(20), child: Text('Todavía no tienes horarios de clase. Crea tu primer bloque de hora + materia.', style: TextStyle(color: _muted)))
      else ..._bloques.map(_bloque),
    ],
  );
}
