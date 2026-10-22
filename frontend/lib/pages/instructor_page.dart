import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'alumno/alumno_eventos_page.dart';
import 'instructor/instructor_perfil_page.dart';
import '../main.dart';

class InstructorPage extends StatefulWidget {
  const InstructorPage({super.key});

  @override
  State<InstructorPage> createState() => _InstructorPageState();
}

class _InstructorPageState extends State<InstructorPage> {
  static const String _perfilUrl =
      'http://127.0.0.1:8000/api/auth/perfil/me/';

  static const bg = Color(0xFF031426);
  static const sidebar = Color(0xFF061C31);
  static const card = Color(0xFF0A2947);
  static const border = Color(0xFF174064);
  static const orange = Color(0xFFFF8A24);
  static const blue = Color(0xFF2796FF);
  static const muted = Color(0xFF91A9BE);

  int _selected = 0;
  int _profileVersion = 0;

  String _query = '';
  String _primerNombre = 'profesor';

  bool _loggingOut = false;
  bool _loadingName = false;

  final _searchController = TextEditingController();
  final List<String> _requests = [];

  static const _labels = [
    'Inicio',
    'Mis cursos',
    'Eventos',
    'Alumnos',
    'Mi perfil',
  ];

  static const _icons = [
    Icons.home_rounded,
    Icons.menu_book_rounded,
    Icons.event_rounded,
    Icons.groups_rounded,
    Icons.person_rounded,
  ];

  final List<_Course> _courses = const [
    _Course(
      title: 'Comandos básicos de Linux',
      description:
          'Introducción a la terminal, archivos y comandos fundamentales.',
      modules: 6,
      icon: Icons.terminal_rounded,
      students: [
        'Ana Torres',
        'Luis Pérez',
        'María López',
        'José García',
      ],
      materials: [
        'Guía de comandos.pdf',
        'Permisos y archivos.pdf',
      ],
    ),
    _Course(
      title: 'Fundamentos de programación',
      description:
          'Variables, condicionales, ciclos y funciones mediante ejemplos.',
      modules: 4,
      icon: Icons.code_rounded,
      students: [
        'Sofía Hernández',
        'Carlos Ruiz',
        'Elena Díaz',
      ],
      materials: ['Introducción a Python.pdf'],
    ),
  ];

  List<_Course> get _filteredCourses {
    return _courses
        .where((course) => course.title.toLowerCase().contains(_query))
        .toList();
  }

  int get _studentCount {
    return _courses.fold(
      0,
      (total, course) => total + course.students.length,
    );
  }

  @override
  void initState() {
    super.initState();
    _cargarNombre();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // NOMBRE REAL DESDE EL BACKEND
  // ============================================================

  Future<void> _cargarNombre({bool mostrarError = false}) async {
    if (_loadingName || _loggingOut) return;
    _loadingName = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.trim().isEmpty) {
        throw Exception('Inicia sesión para cargar tu nombre.');
      }

      final response = await http.get(
        Uri.parse(_perfilUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 401) {
        throw Exception(
          'Tu sesión venció. Cierra sesión y vuelve a ingresar.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'No se pudo cargar el nombre (${response.statusCode}).',
        );
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data is! Map<String, dynamic>) {
        throw Exception('Respuesta inesperada del servidor.');
      }

      if (data['rol']?.toString().toLowerCase() != 'instructor') {
        throw Exception('La sesión no corresponde a un instructor.');
      }

      final nombreCompleto =
          data['nombre_completo']?.toString().trim() ?? '';

      if (!mounted || nombreCompleto.isEmpty) return;

      setState(() {
        _primerNombre = nombreCompleto.split(RegExp(r'\s+')).first;
      });
    } catch (error) {
      debugPrint('No se pudo cargar el nombre: $error');

      if (mostrarError) {
        _message(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      _loadingName = false;
    }
  }

  void _navigate(int index) {
    final previous = _selected;

    setState(() {
      _selected = index;
      _query = '';
      _searchController.clear();
    });

    // Recarga el saludo al volver al inicio o salir del perfil.
    if (index == 0 || previous == 4) {
      _cargarNombre();
    }
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // ============================================================
  // ESTRUCTURA PRINCIPAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 760;
        final compact = constraints.maxWidth < 1150;

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Row(
              children: [
                if (!mobile) _buildSidebar(compact),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(mobile),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(mobile ? 16 : 24),
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 1350),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  if (_selected != 2) ...[
                                    _buildHeading(mobile),
                                    const SizedBox(height: 12),
                                    if (_selected != 4) ...[
                                      const Text(
                                        'Vista de demostración · '
                                        'Datos de ejemplo',
                                        style: TextStyle(
                                          color: muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      _buildSearch(),
                                    ],
                                    const SizedBox(height: 20),
                                  ],
                                  _buildCurrentPage(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: mobile ? _buildBottomBar() : null,
        );
      },
    );
  }

  // ============================================================
  // MENÚ LATERAL
  // ============================================================

  Widget _buildSidebar(bool compact) {
    return Container(
      width: compact ? 82 : 220,
      decoration: const BoxDecoration(
        color: sidebar,
        border: Border(right: BorderSide(color: border)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 26,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🐧', style: TextStyle(fontSize: 32)),
                if (!compact) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Comunidad\nUNIX ITC',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _labels.length,
              itemBuilder: (context, index) {
                final active = _selected == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Tooltip(
                    message: _labels[index],
                    child: Material(
                      color: active
                          ? blue.withValues(alpha: 0.18)
                          : sidebar,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _navigate(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            mainAxisAlignment: compact
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            children: [
                              Icon(
                                _icons[index],
                                color: active ? orange : muted,
                              ),
                              if (!compact) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _labels[index],
                                    style: TextStyle(
                                      color:
                                          active ? Colors.white : muted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BARRA SUPERIOR Y OPCIONES
  // ============================================================

  Widget _buildTopBar(bool mobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 12 : 24,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: sidebar,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          if (mobile)
            const Text('🐧 ', style: TextStyle(fontSize: 25)),
          const Expanded(
            child: Text(
              'Comunidad UNIX ITC',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Solicitudes locales',
            onPressed: _showRequests,
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: muted,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => _navigate(4),
            borderRadius: BorderRadius.circular(20),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: card,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
          if (!mobile) ...[
            const SizedBox(width: 10),
            const Text(
              'Profesor\nInstructor',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            tooltip: 'Opciones de cuenta',
            enabled: !_loggingOut,
            color: sidebar,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: muted,
            ),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _navigate(4);
                  break;

                case 'refresh':
                  setState(() {
                    _selected = 4;
                    _profileVersion++;
                    _query = '';
                    _searchController.clear();
                  });
                  _cargarNombre(mostrarError: true);
                  break;

                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'profile',
                child: Text(
                  'Mi perfil',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              PopupMenuItem<String>(
                value: 'refresh',
                child: Text(
                  'Actualizar datos',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Cerrar sesión',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVEGACIÓN MÓVIL
  // ============================================================

  Widget _buildBottomBar() {
    return BottomNavigationBar(
      backgroundColor: sidebar,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: orange,
      unselectedItemColor: muted,
      currentIndex: _selected <= 2 ? _selected : 3,
      onTap: (index) {
        if (index == 3) {
          _showMore();
        } else {
          _navigate(index);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_rounded),
          label: 'Cursos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_rounded),
          label: 'Eventos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz_rounded),
          label: 'Más',
        ),
      ],
    );
  }

  Future<void> _showMore() async {
    final selectedIndex = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: sidebar,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final index in [3, 4])
              ListTile(
                leading: Icon(_icons[index], color: blue),
                title: Text(
                  _labels[index],
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(sheetContext, index),
              ),
          ],
        ),
      ),
    );

    if (!mounted || selectedIndex == null) return;
    _navigate(selectedIndex);
  }

  Widget _buildHeading(bool mobile) {
    return Text(
      _selected == 0
          ? '¡Hola, $_primerNombre!'
          : _labels[_selected],
      style: TextStyle(
        color: Colors.white,
        fontSize: mobile ? 28 : 34,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() => _query = value.trim().toLowerCase());
      },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: _selected == 3
            ? 'Buscar alumnos o cursos...'
            : 'Buscar cursos...',
        hintStyle: const TextStyle(color: muted),
        prefixIcon: const Icon(Icons.search, color: muted),
        filled: true,
        fillColor: sidebar,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
      ),
    );
  }

  // ============================================================
  // SECCIONES
  // ============================================================

  Widget _buildCurrentPage() {
    switch (_selected) {
      case 1:
        return _buildCourses();

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _requestButton(),
            ),
            const SizedBox(height: 18),
            const AlumnoEventosPage(),
            const SizedBox(height: 18),
            _buildRequestsPanel(),
          ],
        );

      case 3:
        return _buildStudents();

      case 4:
        return InstructorPerfilPage(
          key: ValueKey(_profileVersion),
        );

      default:
        return _buildDashboard();
    }
  }

  // ============================================================
  // INICIO
  // ============================================================

  Widget _buildDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Consulta tus cursos y acompaña a tus alumnos.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 650 ? 1 : 3;
            final width =
                (constraints.maxWidth - (columns - 1) * 12) / columns;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _stat(
                  width,
                  Icons.menu_book,
                  '${_courses.length}',
                  'Cursos activos',
                  1,
                ),
                _stat(width, Icons.event, '1', 'Próximo evento', 2),
                _stat(
                  width,
                  Icons.groups,
                  '$_studentCount',
                  'Alumnos',
                  3,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _requestButton(),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 950) {
              return Column(
                children: [
                  _buildCourses(),
                  const SizedBox(height: 18),
                  _buildEvents(),
                  const SizedBox(height: 18),
                  _buildActivity(),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _buildCourses()),
                const SizedBox(width: 18),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildEvents(),
                      const SizedBox(height: 18),
                      _buildActivity(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _buildStudentsPreview(),
      ],
    );
  }

  Widget _stat(
    double width,
    IconData icon,
    String value,
    String label,
    int destination,
  ) {
    return SizedBox(
      width: width,
      child: Material(
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
        child: InkWell(
          onTap: () => _navigate(destination),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: blue, size: 27),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        label,
                        style:
                            const TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SOLICITAR ASIGNACIÓN
  // ============================================================

  Widget _requestButton() {
    return FilledButton.icon(
      onPressed: _requestEvent,
      style: FilledButton.styleFrom(
        backgroundColor: orange,
        foregroundColor: bg,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: const Icon(Icons.event_available_rounded),
      label: const Text(
        'Solicitar asignación de evento',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  // ============================================================
  // CURSOS
  // ============================================================

  Widget _buildCourses() {
    final courses = _filteredCourses;

    return _panel(
      title: 'Mis cursos',
      action: _selected == 0 ? () => _navigate(1) : null,
      child: courses.isEmpty
          ? _empty('No se encontraron cursos.')
          : LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 600;
                final width = twoColumns
                    ? (constraints.maxWidth - 14) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final course in courses)
                      SizedBox(
                        width: width,
                        child: _courseCard(course),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _courseCard(_Course course) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sidebar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(course.icon, color: blue, size: 38),
          const SizedBox(height: 12),
          Text(
            course.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${course.students.length} alumnos · '
            '${course.modules} módulos',
            style: const TextStyle(color: blue, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            course.description,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _showReport(course),
              style: FilledButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: bg,
              ),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('Ver reporte'),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EVENTOS Y ACTIVIDAD DEL INICIO
  // ============================================================

  Widget _buildEvents() {
    return _panel(
      title: 'Próximos eventos',
      action: _selected == 0 ? () => _navigate(2) : null,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '24\nOCT',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: orange,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: const Text(
          'Taller de Linux',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: const Text(
          '16:00 · En línea\nEvento de ejemplo',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: blue),
        onTap: () => _showDetails(
          'Taller de Linux',
          'Evento de ejemplo\n\n'
              '24 de octubre de 2026\n'
              '16:00 a 18:00 · Hora de Cancún\n'
              'Modalidad: en línea\n\n'
              'Introducción a comandos, archivos y permisos.\n'
              'El enlace real debe proporcionarlo el backend.',
        ),
      ),
    );
  }

  Widget _buildActivity() {
    return _panel(
      title: 'Actividad reciente',
      child: const Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.description, color: blue),
            title: Text(
              'Material publicado',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            subtitle: Text(
              'Guía de comandos · Ejemplo',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_add, color: blue),
            title: Text(
              'Nuevo alumno inscrito',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            subtitle: Text(
              'Ana Torres · Ejemplo',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ALUMNOS
  // ============================================================

  Widget _buildStudentsPreview() {
    return _panel(
      title: 'Alumnos por curso',
      action: () => _navigate(3),
      child: Column(
        children: [
          for (final course in _filteredCourses)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(course.icon, color: blue),
              title: Text(
                course.title,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${course.students.length} alumnos de ejemplo',
                style: const TextStyle(color: muted),
              ),
              trailing: const Icon(Icons.chevron_right, color: blue),
              onTap: () => _showReport(course),
            ),
        ],
      ),
    );
  }

  Widget _buildStudents() {
    final List<Widget> entries = [];

    for (final course in _courses) {
      for (final student in course.students) {
        if (!'$student ${course.title}'
            .toLowerCase()
            .contains(_query)) {
          continue;
        }

        entries.add(
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: sidebar,
              child: Text(
                student[0],
                style: const TextStyle(color: blue),
              ),
            ),
            title: Text(
              student,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              course.title,
              style: const TextStyle(color: muted),
            ),
            onTap: () => _showDetails(
              student,
              'Alumno de ejemplo\n\n'
                  'Curso: ${course.title}\n\n'
                  'El progreso individual estará disponible '
                  'cuando se conecten los datos del backend.',
            ),
          ),
        );
      }
    }

    return _panel(
      title: 'Alumnos inscritos',
      child: entries.isEmpty
          ? _empty('No se encontraron alumnos.')
          : Column(children: entries),
    );
  }

  // ============================================================
  // SOLICITUDES LOCALES
  // ============================================================

  Widget _buildRequestsPanel() {
    return _panel(
      title: 'Mis solicitudes locales',
      child: _requests.isEmpty
          ? _empty(
              'Todavía no has registrado solicitudes en esta pantalla.',
            )
          : Column(
              children: [
                for (final request in _requests)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.pending_actions,
                      color: orange,
                    ),
                    title: Text(
                      request,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Borrador local · No enviado al servidor',
                      style: TextStyle(color: muted),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _requestEvent() async {
    final formKey = GlobalKey<FormState>();
    final eventController = TextEditingController();
    final reasonController = TextEditingController();

    try {
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: card,
            title: const Text(
              'Solicitar asignación de evento',
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: 430,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Indica el evento y tu motivo para participar. '
                        'La solicitud se guardará como borrador local.',
                        style: TextStyle(color: muted),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: eventController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Nombre del evento',
                          labelStyle: TextStyle(color: muted),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Escribe el nombre del evento.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: reasonController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Motivo de la solicitud',
                          labelStyle: TextStyle(color: muted),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Escribe el motivo.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: bg,
                ),
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false)) {
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                    '${eventController.text.trim()}\n'
                    '${reasonController.text.trim()}',
                  );
                },
                child: const Text('Guardar borrador'),
              ),
            ],
          );
        },
      );

      if (!mounted || result == null) return;

      setState(() => _requests.add(result));

      _message(
        'Borrador guardado en esta pantalla. '
        'No se ha enviado al servidor.',
      );
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        eventController.dispose();
        reasonController.dispose();
      });
    }
  }

  // ============================================================
  // REPORTES Y DIÁLOGOS
  // ============================================================

  void _showReport(_Course course) {
    _showDetails(
      'Reporte: ${course.title}',
      'DATOS DE EJEMPLO\n\n'
          'Alumnos inscritos: ${course.students.length}\n'
          'Módulos: ${course.modules}\n'
          'Materiales: ${course.materials.length}\n\n'
          'ALUMNOS\n'
          '${course.students.map((name) => '• $name').join('\n')}\n\n'
          'El avance y las estadísticas reales requieren '
          'conectar el backend.',
    );
  }

  void _showRequests() {
    _showDetails(
      'Solicitudes locales',
      _requests.isEmpty
          ? 'No hay solicitudes guardadas en esta pantalla.'
          : '${_requests.join('\n\n')}\n\n'
              'Estos borradores no se han enviado al servidor.',
    );
  }

  Future<void> _showDetails(String title, String description) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: card,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Text(
              description,
              style: const TextStyle(color: muted, height: 1.6),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CERRAR SESIÓN
  // ============================================================

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: card,
          title: const Text(
            '¿Cerrar sesión?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Se cerrará tu sesión en este dispositivo.',
            style: TextStyle(color: muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: bg,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      );

      if (!mounted || confirmed != true) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('user_rol');

      if (prefs.getString('jwt_token') != null ||
          prefs.getString('user_rol') != null) {
        throw StateError('No se pudo limpiar la sesión.');
      }

      try {
        await GoogleSignIn.instance.signOut();
      } catch (error) {
        debugPrint('Error al cerrar Google: $error');
      }

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AccessScreen()),
        (route) => false,
      );
    } catch (error) {
      debugPrint('Error al cerrar sesión: $error');
      _message('No se pudo cerrar la sesión. Inténtalo nuevamente.');
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  // ============================================================
  // COMPONENTES
  // ============================================================

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(text, style: const TextStyle(color: muted)),
    );
  }

  Widget _panel({
    required String title,
    required Widget child,
    VoidCallback? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (action != null)
                TextButton(
                  onPressed: action,
                  child: const Text(
                    'Ver todos',
                    style: TextStyle(color: blue),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Course {
  final String title;
  final String description;
  final int modules;
  final IconData icon;
  final List<String> students;
  final List<String> materials;

  const _Course({
    required this.title,
    required this.description,
    required this.modules,
    required this.icon,
    required this.students,
    required this.materials,
  });
}