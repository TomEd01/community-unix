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
*   **Sistema de Verificación Anti-Fraude (El Validador):**
    *   Para evitar la falsificación de capturas de pantalla, cada alumno que complete una actividad (curso/exposición/evento) recibirá un folio único (Ej. `UNIX-21530369-X9Y2A`).
    *   La plataforma contará con un "Verificador de Folios" donde los profesores o jefes de departamento podrán ingresar este código y el sistema lanzará un modal confirmando la autenticidad del registro (Nombre, Número de Control y Actividad acreditada).
    *   Toda esta lógica tambien aplicara para verificar si realizo las 5 exposiciones.
*   **Validación de Asistencia Híbrida:** 
    *   *Principal:* Validación por proximidad (Geocerca).
    *   *Respaldo (Fallback):* Checkbox manual por parte del Expositor o Instructor (Maestro) si falla la ubicación.
    *   *Cupo Estricto:* Límite máximo de inscritos basado en la capacidad física del aula.
*   **Macro Evento:** Basicamente es un *Contenedor Padre*, ej. "Semana de Ingeniería". Al participar, da una base de 5 XP.
    * *Sub-actividades (Hijos):* Dentro del Macro Evento existen tres tipos de actividades:
        1.  **Cursos**: Asíncronos (sin horario). El alumno lo hace a su ritmo y recibe una pantalla de conclusión.
        2.  **Exposiciones**: Síncronas (con horario y aula). Usan la lógica de asistencia por PIN efímero junto a la lógica de geocerca. Ideales para liberar créditos.
        3.  **Talleres**: Síncronos. Misma mecánica de las exposiciones, pero otorgan más XP (esto con el objetivo de que si participarón, ya que los talleres lo haran ya sea los propios maestros y/o administradores del plantel).
*   **Filtro de "Mis Alumnos" (Inscripción a Macro Eventos):** Al momento de que un alumno se inscribe a un Macro Evento, la interfaz exigirá llenar un campo desplegable (Dropdown) con la pregunta: "¿Por parte de qué profesor asistes?" (incluyendo la opción "Ninguno"). Este dato es crítico a nivel de base de datos para generar la relación que alimentará el panel exclusivo de cada maestro.
*   **Ciclo de Vida de Eventos (Máquina de Estados en Base de Datos):**
    *(Nota: La propuesta inicial del maestro ocurre por correo mediante el botón Mailto, por lo que NO existe un estado "Pendiente" en el software).*
    1.  ***Reclutando:*** El Super Admin crea el evento en la plataforma. Se abre la vacante pública para que los alumnos pulsen "Quiero ser Expositor".
    2.  ***Borrador:*** El Super Admin elige y asigna a un Expositor. El evento se oculta al público general mientras el equipo recibe el contenido por correo y maqueta la página final.
    3.  ***Publicado:*** El evento está terminado y las inscripciones se abren a toda la comunidad.
*   **Gestión de Postulantes (Modelo "Pull" - Cero Spam):** Las solicitudes de alumnos que pulsan "Quiero ser expositor" se almacenan de forma silenciosa en la base de datos. El sistema NO enviará notificaciones push ni correos a los administradores. Los Super Admins revisarán la lista de candidatos entrando manualmente a los detalles de la exposición/taller mientras esté en estado "reclutando".

## 5. Roles y Permisos Estrictos
*   **Visitante/Alumno:** Solo puede ver eventos publicados, inscribirse y ver su perfil/XP.
*   **Maestro:** Puede proponer solicitudes de eventos por correo. Su función principal y "superpoder" dentro de la plataforma es acceder a un panel exclusivo donde visualizará una lista filtrada *únicamente con sus propios alumnos* (los que lo seleccionaron en el Dropdown de inscripción). Desde ahí podrá verificar si completaron las actividades requeridas para autorizar físicamente la liberación de su punto extra en esa matería. Lo mismo funciona para los cursos que el proponga y las exposiciones.
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