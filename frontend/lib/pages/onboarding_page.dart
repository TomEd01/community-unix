import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'alumno_page.dart';
import 'instructor_page.dart';

enum UserRole { alumno, instructor, externo }

enum ExternalExperience { sector, propia }

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onboardingToken,
  });

  final String onboardingToken;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const Color background = Color(0xFF050C1D);
  static const Color card = Color(0xFF081329);
  static const Color fieldColor = Color(0xFF111D36);
  static const Color borderColor = Color(0xFF34425C);
  static const Color primary = Color(0xFF2F7BFF);
  static const Color textPrimary = Color(0xFFF4F6FA);
  static const Color textSecondary = Color(0xFF929DB2);
  static const Color orange = Color(0xFFF28A3A);
  static const Color green = Color(0xFF41D6A3);

  final _formKey = GlobalKey<FormState>();

  UserRole role = UserRole.alumno;
  ExternalExperience? externalExperience;

  String? institution = 'itc';
  String? academicDegree;

  final controlNumberController = TextEditingController();
  final departmentController = TextEditingController();
  final specialtyController = TextEditingController();
  final otherDegreeController = TextEditingController();
  final organizationController = TextEditingController();

  bool submitting = false;

  @override
  void dispose() {
    controlNumberController.dispose();
    departmentController.dispose();
    specialtyController.dispose();
    otherDegreeController.dispose();
    organizationController.dispose();
    super.dispose();
  }

  String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }

    return null;
  }

  void selectRole(UserRole selectedRole) {
    setState(() {
      role = selectedRole;

      if (role != UserRole.externo) {
        externalExperience = null;
      }
    });
  }

  // ============================================================
  // COMPLETAR REGISTRO Y GUARDAR EN DJANGO
  // ============================================================

  Future<void> completeRegistration() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (role == UserRole.externo && externalExperience == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona tu tipo de experiencia.',
          ),
        ),
      );

      return;
    }

    setState(() {
      submitting = true;
    });

    try {
      final Map<String, dynamic> body = {
        'onboarding_token': widget.onboardingToken,
        'rol': role.name,
      };

      // ========================================================
      // ALUMNO
      // ========================================================

      if (role == UserRole.alumno) {
        body.addAll({
          'numero_control': controlNumberController.text.trim(),
          'procedencia': institution ?? 'itc',
        });
      }

      // ========================================================
      // INSTRUCTOR
      // ========================================================

      else if (role == UserRole.instructor) {
        String gradoFinal = academicDegree ?? '';

        if (gradoFinal == 'otro') {
          gradoFinal = otherDegreeController.text.trim();
        }

        body.addAll({
          'numero_control': controlNumberController.text.trim(),
          'departamento': departmentController.text.trim(),
          'especialidad': specialtyController.text.trim(),
          'grado_academico': gradoFinal,
        });
      }

      // ========================================================
      // EXTERNO
      // ========================================================

      else if (role == UserRole.externo) {
        final bool trabajaEnSector =
            externalExperience == ExternalExperience.sector;

        body.addAll({
          'procedencia':
              trabajaEnSector ? 'sector' : 'experiencia_propia',
          'organizacion': trabajaEnSector
              ? organizationController.text.trim()
              : 'Experiencia propia',
        });
      }

      debugPrint('====================================');
      debugPrint('ENVIANDO PERFIL A DJANGO');
      debugPrint(body.toString());
      debugPrint('====================================');

      // ========================================================
      // PETICIÓN AL BACKEND
      // ========================================================

      final response = await http.post(
        Uri.parse(
          'http://127.0.0.1:8000/api/auth/complete-profile/',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (!mounted) {
        return;
      }

      debugPrint(
        'STATUS complete-profile: ${response.statusCode}',
      );

      debugPrint(
        'RESPUESTA complete-profile: ${response.body}',
      );

      Map<String, dynamic>? data;

      try {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (error) {
        debugPrint(
          'No se pudo leer JSON del backend: $error',
        );
      }

      // ========================================================
      // ERROR DEL BACKEND
      // ========================================================

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String mensaje = 'No se pudo completar el registro.';

        if (data != null) {
          if (data['error'] != null) {
            mensaje = data['error'].toString();
          } else if (data['detail'] != null) {
            mensaje = data['detail'].toString();
          }
        }

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.redAccent,
          ),
        );

        return;
      }

      // ========================================================
      // RESPUESTA NO VÁLIDA
      // ========================================================

      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El servidor devolvió una respuesta inválida.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );

        return;
      }

      // ========================================================
      // COMPROBAR QUE EL PERFIL FUE GUARDADO
      // ========================================================

      if (data['perfil_completo'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El servidor no confirmó que el perfil esté completo.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );

        return;
      }

      // ========================================================
      // REDIRECCIÓN SEGÚN EL ROL
      //
      // Alumno     -> AlumnoPage
      // Instructor -> InstructorPage
      // Externo    -> AlumnoPage
      // ========================================================

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

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => destination,
        ),
      );
    } catch (error) {
      debugPrint(
        'ERROR completeRegistration: $error',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo conectar con el servidor: $error',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
        });
      }
    }
  }

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: textSecondary,
        fontSize: 16,
      ),
      filled: true,
      fillColor: fieldColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 19,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: borderColor,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primary,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.8,
        ),
      ),
    );
  }

  Widget sectionLabel(
    String text, {
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
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
                style: TextStyle(
                  color: orange,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget roleOption({
    required UserRole value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = role == value;

    return InkWell(
      onTap: () {
        selectRole(value);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 19,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF12264A)
              : fieldColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? primary : borderColor,
            width: selected ? 2 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: primary.withValues(
                      alpha: 0.18,
                    ),
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
                    ? primary.withValues(
                        alpha: 0.14,
                      )
                    : const Color(0xFF18243B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected
                    ? const Color(0xFF68A4FF)
                    : textSecondary,
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
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(
                milliseconds: 180,
              ),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? primary : borderColor,
                  width: 2,
                ),
                color: selected
                    ? primary
                    : Colors.transparent,
              ),
              child: selected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

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
          style: const TextStyle(
            color: textPrimary,
            fontSize: 16,
          ),
          decoration: inputDecoration(hint),
        ),
      ],
    );
  }

  Widget institutionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel(
          'Procedencia / Institución',
        ),
        DropdownButtonFormField<String>(
          initialValue: institution,
          dropdownColor: fieldColor,
          style: const TextStyle(
            color: textPrimary,
            fontSize: 16,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: textSecondary,
          ),
          decoration: inputDecoration(
            'Selecciona una institución',
          ),
          items: const [
            DropdownMenuItem(
              value: 'itc',
              child: Text(
                'Instituto Tecnológico de Cancún',
              ),
            ),
            DropdownMenuItem(
              value: 'otra',
              child: Text(
                'Otra institución',
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              institution = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Selecciona una institución.';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget academicDegreeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel(
          'Grado académico / Título',
        ),
        DropdownButtonFormField<String>(
          initialValue: academicDegree,
          dropdownColor: fieldColor,
          style: const TextStyle(
            color: textPrimary,
            fontSize: 16,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: textSecondary,
          ),
          decoration: inputDecoration(
            'Selecciona tu grado académico',
          ),
          items: const [
            DropdownMenuItem(
              value: 'ing',
              child: Text('Ing.'),
            ),
            DropdownMenuItem(
              value: 'lic',
              child: Text('Lic.'),
            ),
            DropdownMenuItem(
              value: 'mtro',
              child: Text('Mtro.'),
            ),
            DropdownMenuItem(
              value: 'dr',
              child: Text('Dr.'),
            ),
            DropdownMenuItem(
              value: 'otro',
              child: Text('Otro'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              academicDegree = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Selecciona tu grado académico.';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget externalExperienceOption({
    required ExternalExperience value,
    required String title,
  }) {
    final selected = externalExperience == value;

    return InkWell(
      onTap: () {
        setState(() {
          externalExperience = value;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF12264A)
              : fieldColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primary : borderColor,
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? primary : textSecondary,
            ),
            const SizedBox(width: 13),
            Text(
              title,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      ],
    );
  }

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
      ],
    );
  }

  Widget externoFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel(
          'Tipo de experiencia',
        ),
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

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        34,
        32,
        34,
        30,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: borderColor,
          ),
        ),
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
                  Icon(
                    Icons.shield_outlined,
                    color: green,
                    size: 21,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Datos protegidos',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                    ),
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
            'Selecciona tu tipo de usuario y completa los datos de tu perfil.',
            style: TextStyle(
              color: textSecondary,
              fontSize: 17,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        34,
        34,
        34,
        40,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionLabel(
              'Tipo de usuario',
            ),

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

            roleFields(),

            const SizedBox(height: 34),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed:
                    submitting ? null : completeRegistration,
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  disabledBackgroundColor:
                      primary.withValues(alpha: 0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: submitting
                    ? const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
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
                          Icon(
                            Icons.arrow_forward,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 38,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 720,
              ),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: borderColor,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 30,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    buildHeader(),
                    buildForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}