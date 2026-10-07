import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'alumno_page.dart';
import 'instructor_page.dart';

import 'package:shared_preferences/shared_preferences.dart';

// Distingo los tres perfiles que puede registrar la pantalla y las dos
// modalidades que especifico cuando alguien se registra como usuario externo.
enum UserRole { alumno, instructor, externo }

enum ExternalExperience { sector, propia }

// Recibo del acceso de Google los datos y el token temporal del registro.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onboardingToken,
    required this.email,
    required this.nombre,
  });

  final String onboardingToken;
  final String email;
  final String nombre;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  // Centralizo la paleta para reutilizar los mismos tonos en campos,
  // estados de selección, texto y elementos de énfasis.
  static const Color background = Color(0xFF050C1D);
  static const Color card = Color(0xFF081329);
  static const Color fieldColor = Color(0xFF111D36);
  static const Color borderColor = Color(0xFF34425C);
  static const Color primary = Color(0xFF2F7BFF);
  static const Color textPrimary = Color(0xFFF4F6FA);
  static const Color textSecondary = Color(0xFF929DB2);
  static const Color orange = Color(0xFFF28A3A);
  static const Color green = Color(0xFF41D6A3);

  // Conservo la clave que valida el formulario y las opciones que determinan
  // qué campos muestro y qué información preparo para cada perfil.
  final _formKey = GlobalKey<FormState>();

  UserRole role = UserRole.alumno;
  ExternalExperience? externalExperience;

  String? institution = 'itc';
  String? academicDegree;

  // Vinculo cada campo de texto con su propio controlador para leerlo,
  // validarlo y liberar sus recursos al cerrar esta pantalla.
  final nameController = TextEditingController();
  final controlNumberController = TextEditingController();
  final departmentController = TextEditingController();
  final specialtyController = TextEditingController();
  final otherDegreeController = TextEditingController();
  final otherInstitutionController = TextEditingController();
  final organizationController = TextEditingController();

  bool submitting = false;

  // Inicio el nombre con el dato de Google, pero lo dejo editable; más abajo
  // libero todos los controladores cuando Flutter retira esta pantalla.
  @override
  void initState() {
    super.initState();
    nameController.text = widget.nombre;
  }

  @override
  void dispose() {
    nameController.dispose();
    controlNumberController.dispose();
    departmentController.dispose();
    specialtyController.dispose();
    otherDegreeController.dispose();
    otherInstitutionController.dispose();
    organizationController.dispose();
    super.dispose();
  }

  // Rechazo los valores vacíos o compuestos solo por espacios para que el
  // usuario no pueda completar el registro con un dato visualmente en blanco.
  String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Este campo es obligatorio.';
    return null;
  }

  // Guardo el perfil elegido para reconstruir sus campos y limpio la
  // experiencia externa si se cambia a un perfil que no la utiliza.
  void selectRole(UserRole selectedRole) {
    setState(() {
      role = selectedRole;
      if (role != UserRole.externo) externalExperience = null;
    });
  }

  // Coordino la validación, la creación del payload, la petición al backend
  // y la navegación que ocurre cuando el perfil queda registrado.
  Future<void> completeRegistration() async {
    FocusManager.instance.primaryFocus?.unfocus();

    // Valido los campos visibles antes de iniciar la petición para evitar
    // enviar datos incompletos o mantener el teclado abierto durante el envío.
    if (!_formKey.currentState!.validate()) return;

    // La experiencia externa no es un campo de texto del Form, por eso
    // compruebo explícitamente que se haya elegido una de sus dos opciones.
    if (role == UserRole.externo && externalExperience == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona tu tipo de experiencia.')),
      );
      return;
    }

    // Bloqueo el botón y muestro el estado de carga mientras espero respuesta.
    setState(() => submitting = true);

    try {
      // Incluyo primero los datos compartidos por todos los perfiles y uso
      // el rol seleccionado para añadir después sus datos particulares.
      final Map<String, dynamic> body = {
        'token': widget.onboardingToken,
        'email': widget.email,
        'nombre_completo': nameController.text.trim(),
        'rol': role.name,
      };

      if (role == UserRole.alumno) {
        // Para el alumno envío su número de control y normalizo la procedencia;
        // solo solicito el nombre cuando eligió una institución distinta.
        body.addAll({
          'numero_control': controlNumberController.text.trim(),
          'procedencia': institution == 'otra'
              ? 'Otra institución'
              : 'Instituto Tecnológico de Cancún',
        });
        if (institution == 'otra') {
          body['nombre_institucion'] = otherInstitutionController.text.trim();
        }
      } else if (role == UserRole.instructor) {
        // Para el instructor agrego sus datos académicos y convierto la opción
        // "Otro" en el valor que espera el backend junto con su especificación.
        body.addAll({
          'numero_control': controlNumberController.text.trim(),
          'departamento': departmentController.text.trim(),
          'especialidad': specialtyController.text.trim(),
          'grado_academico': academicDegree == 'otro' ? 'Otro' : academicDegree,
          'procedencia': institution == 'otra'
              ? 'Otra institución'
              : 'Instituto Tecnológico de Cancún',
        });
        if (academicDegree == 'otro')
          body['especifica_grado'] = otherDegreeController.text.trim();
        if (institution == 'otra')
          body['nombre_institucion'] = otherInstitutionController.text.trim();
      } else if (role == UserRole.externo) {
        // Traduzco la opción elegida a los valores del backend y envío una
        // organización solo cuando la experiencia corresponde al sector.
        final bool trabajaEnSector =
            externalExperience == ExternalExperience.sector;
        body.addAll({
          'tipo_experiencia': trabajaEnSector
              ? 'Trabajo en el sector'
              : 'Experiencia propia',
          'organizacion': trabajaEnSector
              ? organizationController.text.trim()
              : 'Independiente / Autodidacta',
        });
      }

      // Serializo el payload como JSON y lo envío al endpoint de onboarding.
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/auth/completar_perfil/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      // Informo cualquier respuesta no exitosa y conservo al usuario en el form.
      if (response.statusCode < 200 || response.statusCode >= 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error del servidor: ${response.statusCode}'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // ¡El perfil se guardó en Django! Guardamos la sesión en el teléfono
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', widget.onboardingToken);
      
      // Guardamos el rol capitalizado para mantener el estándar ('Alumno', 'Instructor', 'Externo')
      String rolFinal = role.name.substring(0, 1).toUpperCase() + role.name.substring(1);
      await prefs.setString('user_rol', rolFinal);

      // Dirijo al usuario a su área según el perfil que acaba de registrar;
      // por ahora, el perfil externo comparte la pantalla del alumno.
      Widget destination;
      switch (role) {
        case UserRole.alumno:
          destination = const AlumnoPage();
          break;
        case UserRole.instructor:
          destination = const InstructorPage();
          break;
        case UserRole.externo:
          destination = const AlumnoPage();
          break;
      }

      if (!mounted) return;
      // Reemplazo onboarding para que volver atrás no reenvíe el mismo registro.
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => destination));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de red: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      // Muestro los fallos de red sin perder el formulario que ya completó.
      if (mounted) setState(() => submitting = false);
    }
  }
  // Restauro el botón tanto si la petición termina bien como si falla.

  // Construyo estilos reutilizables para los campos y sus etiquetas.
  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      // Defino la decoración común de los campos para que sus estados normal,
      // enfocado y con error mantengan una apariencia coherente.
      hintStyle: const TextStyle(color: textSecondary, fontSize: 16),
      filled: true,
      fillColor: fieldColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
      ),
    );
  }

  // Presento una etiqueta y marco visualmente los campos obligatorios;
  // permito omitir el asterisco cuando una sección sea opcional.
  Widget sectionLabel(String text, {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(text: text),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: orange),
              ),
          ],
        ),
      ),
    );
  }

  // Construyo una opción de perfil que refleja la selección actual y delega
  // el cambio en selectRole para mantener sincronizados sus campos asociados.
  Widget roleOption({
    required UserRole value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = role == value;
    return InkWell(
      onTap: () => selectRole(value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF12264A) : fieldColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? primary : borderColor,
            width: selected ? 2 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.18),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected
                    ? primary.withValues(alpha: 0.14)
                    : const Color(0xFF18243B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected ? const Color(0xFF68A4FF) : textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(color: textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? primary : borderColor,
                  width: 2,
                ),
                color: selected ? primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // Combino etiqueta, validación y decoración para reutilizar el mismo patrón
  // en los campos de texto de los distintos perfiles.
  Widget textField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel(label),
        TextFormField(
          controller: controller,
          validator: requiredValidator,
          style: const TextStyle(color: textPrimary, fontSize: 16),
          decoration: inputDecoration(hint),
        ),
      ],
    );
  }

  // Muestro la procedencia elegida y guardo el valor para adaptar los campos
  // visibles y el dato que envío al backend.
  Widget institutionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel('Procedencia / Institución'),
        DropdownButtonFormField<String>(
          initialValue: institution,
          dropdownColor: fieldColor,
          style: const TextStyle(color: textPrimary, fontSize: 16),
          icon: const Icon(Icons.keyboard_arrow_down, color: textSecondary),
          decoration: inputDecoration('Selecciona una institución'),
          items: const [
            DropdownMenuItem(
              value: 'itc',
              child: Text('Instituto Tecnológico de Cancún'),
            ),
            DropdownMenuItem(value: 'otra', child: Text('Otra institución')),
          ],
          onChanged: (value) => setState(() => institution = value),
        ),
      ],
    );
  }

  // Muestro los grados permitidos y guardo la opción para revelar una
  // especificación adicional cuando el usuario seleccione "Otro".
  Widget academicDegreeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel('Grado académico / Título'),
        DropdownButtonFormField<String>(
          initialValue: academicDegree,
          dropdownColor: fieldColor,
          style: const TextStyle(color: textPrimary, fontSize: 16),
          icon: const Icon(Icons.keyboard_arrow_down, color: textSecondary),
          decoration: inputDecoration('Selecciona tu grado académico'),
          items: const [
            DropdownMenuItem(value: 'ing', child: Text('Ing.')),
            DropdownMenuItem(value: 'lic', child: Text('Lic.')),
            DropdownMenuItem(value: 'mtro', child: Text('Mtro.')),
            DropdownMenuItem(value: 'dr', child: Text('Dr.')),
            DropdownMenuItem(value: 'otro', child: Text('Otro')),
          ],
          onChanged: (value) => setState(() => academicDegree = value),
        ),
      ],
    );
  }

  // Represento cada modalidad externa como una opción seleccionable y
  // mantengo su estado para decidir si debo pedir una organización.
  Widget externalExperienceOption({
    required ExternalExperience value,
    required String title,
  }) {
    final selected = externalExperience == value;
    return InkWell(
      onTap: () => setState(() => externalExperience = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF12264A) : fieldColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primary : borderColor,
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? primary : textSecondary,
            ),
            const SizedBox(width: 13),
            Text(
              title,
              style: const TextStyle(color: textPrimary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Solicito los datos exclusivos del alumno y solo expando la institución
  // cuando su elección requiere capturar un nombre personalizado.
  Widget alumnoFields() {
    return Column(
      children: [
        textField(
          label: 'ID / Número de control',
          hint: 'Ej. 21040123',
          controller: controlNumberController,
        ),
        const SizedBox(height: 24),
        institutionField(),
        if (institution == 'otra') ...[
          const SizedBox(height: 24),
          textField(
            label: 'Nombre de la institución',
            hint: 'Escribe el nombre de tu institución',
            controller: otherInstitutionController,
          ),
        ],
      ],
    );
  }

  // Reúno los datos académicos del instructor y revelo los campos de detalle
  // únicamente cuando selecciona un grado o una institución "Otra".
  Widget instructorFields() {
    return Column(
      children: [
        textField(
          label: 'Matrícula del instructor',
          hint: 'Ingresa tu matrícula',
          controller: controlNumberController,
        ),
        const SizedBox(height: 24),
        textField(
          label: 'Departamento / Academia',
          hint: 'Ej. Academia de Sistemas',
          controller: departmentController,
        ),
        const SizedBox(height: 24),
        textField(
          label: 'Especialidad / Área de conocimiento',
          hint: 'Ej. Desarrollo de Software',
          controller: specialtyController,
        ),
        const SizedBox(height: 24),
        academicDegreeField(),
        if (academicDegree == 'otro') ...[
          const SizedBox(height: 24),
          textField(
            label: 'Especifica tu grado o título',
            hint: 'Escribe tu grado o título',
            controller: otherDegreeController,
          ),
        ],
        const SizedBox(height: 24),
        institutionField(),
        if (institution == 'otra') ...[
          const SizedBox(height: 24),
          textField(
            label: 'Nombre de la institución',
            hint: 'Escribe el nombre de tu institución',
            controller: otherInstitutionController,
          ),
        ],
      ],
    );
  }

  // Solicito la modalidad externa y pido la organización solo para experiencia
  // laboral; para experiencia propia uso el valor independiente predefinido.
  Widget externoFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel('Tipo de experiencia'),
        externalExperienceOption(
          value: ExternalExperience.sector,
          title: 'Trabajo en el sector',
        ),
        const SizedBox(height: 12),
        externalExperienceOption(
          value: ExternalExperience.propia,
          title: 'Experiencia propia',
        ),
        if (externalExperience == ExternalExperience.sector) ...[
          const SizedBox(height: 24),
          textField(
            label: 'Organización / procedencia',
            hint: 'Escribe tu organización o procedencia',
            controller: organizationController,
          ),
        ],
      ],
    );
  }

  // Selecciono los campos que corresponden al rol actual y mantengo cada
  // formulario específico en su propio método.
  Widget roleFields() {
    switch (role) {
      case UserRole.alumno:
        return alumnoFields();
      case UserRole.instructor:
        return instructorFields();
      case UserRole.externo:
        return externoFields();
    }
  }

  // Presento la identidad de la comunidad, el aviso de protección y el
  // propósito de esta etapa antes de que el usuario complete sus datos.
  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(34, 32, 34, 30),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            children: [
              const Text(
                'C O M U N I D A D   U N I X   I T C',
                style: TextStyle(
                  color: Color(0xFF65A7FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.shield_outlined, color: green, size: 21),
                  SizedBox(width: 8),
                  Text(
                    'Datos protegidos',
                    style: TextStyle(color: textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Completa tu registro',
            style: TextStyle(
              color: textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Verifica tu nombre y selecciona tu tipo de usuario.',
            style: TextStyle(color: textSecondary, fontSize: 17, height: 1.55),
          ),
        ],
      ),
    );
  }

  // Ordeno el nombre, la elección del perfil, sus campos dinámicos y la acción
  // final, manteniendo todo dentro del Form asociado a _formKey.
  Widget buildForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 34, 34, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conservo editable el nombre recibido durante el acceso.
            textField(
              label: 'Nombre completo (Editable)',
              hint: 'Tu nombre completo',
              controller: nameController,
            ),
            const SizedBox(height: 34),

            // Hago explícita la selección del perfil antes de mostrar sus datos.
            sectionLabel('Tipo de usuario'),
            roleOption(
              value: UserRole.alumno,
              title: 'Alumno',
              subtitle: 'Estudiante de la comunidad',
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: 14),
            roleOption(
              value: UserRole.instructor,
              title: 'Instructor',
              subtitle: 'Docente o instructor',
              icon: Icons.co_present_outlined,
            ),
            const SizedBox(height: 14),
            roleOption(
              value: UserRole.externo,
              title: 'Externo',
              subtitle: 'Miembro externo',
              icon: Icons.public_outlined,
            ),
            const SizedBox(height: 34),
            // Cambio los campos visibles de acuerdo con el perfil seleccionado.
            roleFields(),
            const SizedBox(height: 34),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: submitting ? null : completeRegistration,
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  disabledBackgroundColor: primary.withValues(alpha: 0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: submitting
                    // Reemplazo el contenido del botón por un indicador durante
                    // la petición para evitar envíos repetidos.
                    ? const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Completar registro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compongo la pantalla desplazable y limito su ancho para conservar la
  // legibilidad del formulario en ventanas grandes y pequeñas.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 38),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 30,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(children: [buildHeader(), buildForm()]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
