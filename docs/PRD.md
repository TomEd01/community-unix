# Product Requirements Document (PRD)

**Sistema de Gestión de Eventos - Comunidad UNIX**

## 1. El Problema
La comunidad necesita una plataforma para gestionar talleres , cursos y eventos, pero los sistemas actuales (como Moodle) son demasiado pesados para eventos rápidos, no motivan a los alumnos principiantes y carecen de un control de asistencia confiable para validar créditos académicos. Además, los profesores tienen ideas para talleres, pero no tienen tiempo para organizarlos o impartirlos.

## 2. Usuarios Objetivo (Público)
*   **Alumnos:** Estudiantes (de cualquier semestre) que buscan aprender, ganar puntos de experiencia (XP) y obtener folios de validación para exentar materias, y/o generar creditos escolares (esto se hara un tramite fisicamente y autorizado por el profesor).
*   **Maestros / Instructores:** Profesionales que proponen temas para talleres pero no necesariamente los imparten.
*   **Externos:** Ellos como su nombre lo dice, pueden venir de visita a interactuar con la plataforma, ya que para que propongan un tema unicamente debera de ser un instructor.
*   **Super Admins (Nosotros):** El equipo de desarrollo (Fish, Fiscal, Líder Backend). Únicos con control total sobre la creación de contenido final, o si algun día se expande, poderle otorgar el super usuario a x persona.


## 3. Objetivo del Proyecto (Visión)
Crear un ecosistema centralizado, gamificado y cerrado. Un lugar donde los maestros proponen, unicamente contaran con un simple botón "Proponer Tema" que abrirá la aplicación de correo electrónico (Mailto) del profesor, enviando un correo directo a los Super Admins. El resto del proceso (videollamadas, revisión) ocurre fuera del sistema.<br>
Los alumnos exponen y asisten, y el sistema automatiza la asistencia (Geocerca) y la recompensa (XP/Folios), operado bajo la estrategia "Mago de Oz" (el equipo de desarrollo ensambla el contenido final).

## 4. Funcionalidades Core (El MVP)

*   **Identidad sin Contraseñas:** Registro y Login exclusivo con Google/Microsoft OAuth.
*   **Gamificación Inclusiva (Sistema XP):** Recompensas por asistencia y participación, guardadas en un historial (Ledger) inmutable (permite penalizaciones por ausencias).
*   **Recompensa Tangible y Validación Física:**
    *   Generación de un Folio Digital de "Candidato a Liberación de Crédito" automático. Este folio se activa únicamente cuando un alumno demuestra compromiso continuo (Ej. tras impartir 5 o más exposiciones/talleres).
    *   **Proceso de validación:** El alumno presentará este folio digital (mediante captura o en pantalla) al Jefe de Departamento de Sistemas. El Jefe actúa como el filtro oficial de veracidad (aprobando o rechazando según la participación real observada) y otorga la firma física necesaria para que el alumno tramite su crédito (ej. de 5 puntos) ante el área administrativa para su servicio social o residencia.
*   **Sistema de Verificación Anti-Fraude (El Validador en Tiempo Real):**
    *   Para evitar la falsificación de capturas de pantalla y resolver el caso donde más de un profesor solicita evidencia de participación, cada alumno recibirá un folio único desde el momento en que se inscribe a cualquier actividad o evento (Ej. `UNIX-21530369-X9Y2A` o `UNIX-{num_control}-{id_evento}`).
    *   El panel de los Instructores y Jefes de Departamento contará con un **"Verificador de Folios"**. Al ingresar el código, el sistema lanzará un modal con el **detalle extendido de auditoría**:
        *   **Datos del Alumno:** Nombre completo y Número de Control.
        *   **Detalles de la Actividad:** Tipo y nombre (`[Evento]`, `[Curso]`, `[Exposición]` o `[Taller]`), **nombre del Instructor titular** y **nombre del Alumno Expositor** que la impartió.
        *   **Estado en tiempo real:** Mostrará **`Cursando`** o **`Terminado`** (para Cursos), y **`Por asistir`** o **`Asistido`** (para Macro Eventos, Exposiciones y Talleres).
        *   *Si el código ingresado no existe:* Mostrará un aviso claro indicando que el folio no es válido o no tiene registros asociados.
    *   Esta misma lógica aplicará para verificar el folio especial de las 5 exposiciones impartidas para liberación de créditos.
*   **Validación de Asistencia Híbrida (Por tipo de actividad):** 
    *   *Cursos (Asíncronos):* No requieren GPS ni horario; la asistencia y los puntos XP se acreditan automáticamente cuando el alumno concluye el contenido en la plataforma.
    *   *Exposiciones y Talleres (Síncronos - Principal):* Validación obligatoria por proximidad (Geocerca de 50m) combinada con el ingreso de un PIN efímero dictado en el aula y los puntos XP se acreditan automáticamente cuando el expositor concluye.
    *   *Respaldo en caso de fallo de GPS (Override Manual):* Si el GPS del alumno falla dentro del aula, tanto el **Expositor** asignado a esa sesión como el **Instructor** titular del evento tendrán acceso a la lista de inscritos de esa actividad específica para marcar su asistencia manualmente mediante un checkbox.
    *   *Cupo Estricto:* Límite máximo de inscritos basado en la capacidad física del aula.
*   **Macro Evento:** Basicamente es un *Contenedor Padre*, ej. "Semana de Ingeniería". Al participar, da una base de 5 XP.
    * *Sub-actividades (Hijos):* Dentro del Macro Evento existen tres tipos de actividades:
        1.  **Cursos**: Asíncronos (sin horario). El alumno lo hace a su ritmo y recibe una pantalla de conclusión.
        2.  **Exposiciones**: Síncronas (con horario y aula). Usan la lógica de asistencia por PIN efímero junto a la lógica de geocerca. Ideales para liberar créditos.
        3.  **Talleres**: Síncronos. Misma mecánica de las exposiciones, pero otorgan más XP (esto con el objetivo de que si participarón, ya que los talleres lo haran ya sea los propios maestros y/o administradores del plantel).
*   **Vinculación de "Mis Alumnos" por Horario, Materia y Ciclo Semestral:** 
    *   En lugar de preguntar por el profesor en cada inscripción a eventos, la vinculación ocurre desde el **Panel del Alumno**.
    *   El Instructor da de alta en su panel sus bloques de clase especificando obligatoriamente **Horario y Materia** (Ej. `7:00 am - 9:00 am | Redes de Computadoras`).
    *   *Regla de Vínculo Único (Anti-Spam):* El alumno entra a la sección *"¿Con qué profesor tomas clase?"*, busca al Instructor y selecciona su bloque de horario y materia. Un alumno solo puede estar vinculado a una lista de profesor a la vez para evitar registros maliciosos masivos; si elige otro horario o profesor, su registro se mueve automáticamente sin duplicarse. *(Si un segundo profesor solicita evidencia de un mismo evento, el alumno comprobará su asistencia entregándole su Folio en el Verificador de Folios).*
    *   *Cambio de Semestre y Desvinculación Dinámica:* Tanto el Alumno (opción *"Desvincular profesor"*) como el Instructor (opción *"Eliminar horario"*) pueden reiniciar sus vínculos al concluir el semestre. Si un Instructor elimina primero su bloque de horario, el sistema no arrojará errores técnicos al alumno; en su lugar, el panel del alumno detectará la baja y mostrará el aviso: **"Ups, al parecer ya no da clases durante este horario, ¿Deseas vincularte con otro profesor?"**, permitiéndole repetir el proceso limpiamente para el nuevo semestre.
*   **Ciclo de Vida de Eventos (Máquina de Estados en Base de Datos):**
    *(Nota: La propuesta inicial del maestro ocurre por correo mediante el botón Mailto, por lo que NO existe un estado "Pendiente" en el software).*
    1.  ***Reclutando:*** El Super Admin crea el evento en la plataforma. Se abre la vacante pública para que los alumnos pulsen "Quiero ser Expositor".
    2.  ***Borrador:*** El Super Admin elige y asigna a un Expositor. El evento se oculta al público general mientras el equipo recibe el contenido por correo y maqueta la página final.
    3.  ***Publicado:*** El evento está terminado y las inscripciones se abren a toda la comunidad.
*   **Gestión de Postulantes (Modelo "Pull" - Cero Spam):** Las solicitudes de alumnos que pulsan "Quiero ser expositor" se almacenan de forma silenciosa en la base de datos. El sistema NO enviará notificaciones push ni correos a los administradores. Los Super Admins revisarán la lista de candidatos entrando manualmente a los detalles de la exposición/taller mientras esté en estado "reclutando".

## 5. Roles y Permisos Estrictos
*   **Visitante/Alumno:** Solo puede ver eventos publicados, inscribirse y ver su perfil/XP.
*   **Instructor:** Puede proponer solicitudes de eventos por correo (`mailto`). Dentro de la plataforma cuenta con dos secciones independientes para mantener el orden:
    1. *Mis Horarios de Clase (Profesor de Materia):* Crea sus bloques (`Horario + Materia`) y visualiza una tabla limpia con sus alumnos vinculados (Nombre, Número de Control y XP Total), acompañada de un botón **"Ver Historial"**. Al pulsarlo, se abre un resumen rápido de ese alumno con el formato: `(Evento) Nombre: Por asistir / Asistido`, `(Curso) Nombre: Cursando / Terminado`, `(Taller/Exposición) Nombre: Por asistir / Asistido`. Si el alumno no tiene registros, mostrará el texto: **"No hay ninguna actividad activa"**.
    2. *Mis Actividades a Cargo (Dueño de Actividad):* Si el Instructor es el responsable titular de un Curso, Taller o Exposición, verá aquí la lista general de todos los alumnos inscritos a esa actividad (sin importar de qué grupo u horario provengan) para supervisar la asistencia o aplicar el pase de lista manual (*override*) si falla el GPS.
*   **Externos** Es una manera de registrar a los candidatos que vienen de visita, pero manteniendo un interes en querer aprender sobre la comunidad y basicamente tendrían los mismos privilegios que los alumnos, simplemente colocando una etiqueta.
*   **Expositor (Etiqueta Temporal):** Un Alumno asignado a un evento. SOLO en ese evento, puede ver la lista de inscritos y pasar lista (override manual).
*   **Super Admin:** Puede aprobar solicitudes, editar la información de los eventos, asignar expositores y modificar cupos. No existe un CMS (Creador de cursos) para el público.

<br>**_Nota:_** Si un profesor quiere participar en los eventos para ganar XP (como si fuera alumno), no usará su cuenta de Maestro. Deberá crearse una cuenta independiente con rol "Externo". Esto protege el dashboard del maestro para que sea exclusivamente administrativo.

## 6. Fuera del Alcance (Fase 1 - NO PROGRAMAR)
*   Foros de discusión de la comunidad.
*   Motor de ejecución/validación de código (ej. evaluar scripts de Python).
*   Generación de archivos PDF complejos (usaremos folios en pantalla).
*   Escáneres QR / Acceso a cámara de hardware.
*   Panel de auto-creación de cursos para profesores (CMS).
*   Automatización del trámite de créditos con el área administrativa del instituto (el sistema solo llega hasta la generación del Folio para el Jefe de Departamento; el trámite restante es físico y manual).