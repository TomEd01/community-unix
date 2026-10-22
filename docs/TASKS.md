# Tareas del Proyecto (Vibe Coding Loop)

*Regla del equipo: Nadie avanza a una fase posterior sin haber completado y probado la anterior. Cada tarea debe ser un Pull Request con su clave de Jira (Ej. UNX-15).*

## Fase 1: Arquitectura y Cimientos (Completado ✅)

* \[x\] Inicializar Monorepo en GitHub con ramas protegidas.

* \[x\] Crear estructura base de Django (Backend).

* \[x\] Crear estructura base de Flutter (Frontend).

* \[x\] Definir reglas de colaboración (.gitignore, Guía Jira).

## Fase 2: Identidad y Perfiles (En Progreso ⏳)

**Responsables: Fish (UI) / Backend (Auth) / Fiscal (DB)**

* \[x\] (Backend) Crear modelo de usuario personalizado (Custom User Model) basado en correo.

* \[x\] (Backend) Configurar endpoint de recepción de Token de Google (JWT).

* \[x\] (Frontend - Fish) Pantalla de completado de perfil (Nombre editable, Selección de Rol: Alumno, Maestro, Externo).

* \[x\] (Frontend - Fish) Mostrar/ocultar campos obligatorios según el rol (ej. Procedencia).

* [ ] (DB/Backend) Crear modelo de bloques de clase del Instructor (`horario` y `materia` obligatorios) y tabla de vinculación única con el Alumno (soportando actualización automática de horario, desvinculación manual y manejo de horario eliminado por el profesor sin romper la cuenta del alumno).

* [ ] (Frontend - Fish) Añadir en el Panel del Instructor la creación/eliminación de bloques (`Hora + Materia`) y la vista de tablas divididas por horario mostrando a sus alumnos registrados (con su XP e historial).

* [ ] (Frontend - Fish) Añadir en el Panel del Alumno la sección "¿Con qué profesor tomas clase?" (buscador de Instructor, selector de `Horario + Materia`, botón de desvincular y alerta dinámica: *"Ups, al parecer ya no da clases durante este horario, ¿Deseas vincularte con otro profesor?"* cuando el docente borre el grupo).

* \[x\] (Base de Datos - Fiscal) Asegurar que la tabla Usuarios soporte roles y campos nulos dinámicos.

## Fase 3: Núcleo de Base de Datos y Gamificación

**Responsable: Fiscal (Arquitectura Lógica) / Backend**

* \[ \] (DB - Fiscal) Diseñar la jerarquía de eventos: crear tabla `macro_eventos` (Contenedor Padre) y tabla `actividades` (Cursos, Exposiciones, Talleres) con el campo `estado` (Reclutando, Borrador, Publicado).

* \[ \] (DB - Fiscal) Diseñar el historial de XP (Ledger: usuario_id, evento_id, cantidad_xp, motivo, fecha).

* \[ \] (DB - Fiscal) Crear la tabla `solicitudes_expositor` en Supabase con las llaves foráneas correctas.

* \[ \] (Backend) Programar endpoints CRUD para Super Admins (Aprobar evento, editar contenido, cambiar estado).

* \[ \] (Backend) Programar endpoint público para listar solo eventos en estado "Publicado" y "Reclutando".

* \[ \] (Backend) Crear endpoint (GET) que devuelva la lista de postulantes filtrada por el ID de la sub-actividad.

* \[ \] (Frontend - Fish) Diseñar en el Dashboard Admin, dentro de la vista de un evento en "Reclutamiento", una lista/tabla que muestre a los postulantes con un botón de "Aprobar" al lado de cada nombre.

## Fase 4: Frontend Dashboard y Flujo de Eventos

**Responsable: Fish (UI) / Backend (Conexión)**

* \[ \] (Frontend - Fish) Diseñar Dashboard principal (Saludo, Nivel, Puntos XP totales, Cursos asíncronos, Exposiciones individuales y Eventos).

* \[ \] (Frontend - Fish) Diseñar Vista de Evento (Mostrar límite de cupo y botón dinámico "Agotado" o "Asistir").

* \[ \] (Frontend - Fish) Botón "Quiero ser Expositor" (Solo visible en estado *Reclutando*).

* \[ \] (Backend) Endpoint de inscripción (Validar límite de cupo máximo antes de guardar).

## Fase 5: El Candado de Asistencia (Check-in)

**Responsables: Todo el equipo**

* \[ \] (Backend) Crear lógica de validación de proximidad (Validar la distancia GPS de 50 metros).

* \[ \] (Frontend - Fish) Botón "Registrar mi Asistencia" que envía la información de ubicación al backend. Para Exposiciones/Talleres, debe incluir también la pantalla de ingreso del PIN Efímero.

* \[ \] (Backend) Función para otorgar XP al terminar el evento y escribir en el historial al validar asistencia exitosa y así mismo registrar a los que no fueron y hacerle su penalización, al finalizar el evento.

* \[ \] (Frontend/Backend) Panel "Override Manual" para el Expositor y el Instructor (Maestro): una tabla simple con checkboxes para pasar lista manualmente si la ubicación llegara a fallar.

## Fase 6: Recompensas (El Folio)

**Responsable: Fish / Backend**

* \[ \] (Backend) Lógica que cuente cuántos talleres ha impartido un usuario con la etiqueta Expositor.

* \[ \] (Frontend - Fish) Pantalla visual de "Certificado / Liberación de Crédito" para mostrar al profesor físicamente.

* \[ \] (Frontend - Fish) Diseñar la pantalla de "Verificador de Folios" para Maestros y Jefes de Departamento (Un simple input de texto).

* \[ \] (Frontend - Fish) Diseñar el Modal de resultado al verificar el folio mostrando: Nombre del alumno, Número de control, Actividad y el **Estado actual** (`Cursando` / `Terminado` para cursos, o `Por asistir` / `Asistido` para eventos, exposiciones y talleres).

* \[ \] (Backend) Crear generador de folios únicos al momento de la inscripción a cualquier evento/actividad (Ej. `UNIX-{num_control}-{id_evento}`) y actualizar su estado automáticamente al validar la asistencia o conclusión.

* \[ \] (Backend) Crear endpoint de consulta (`GET /api/verificar-folio/{folio}`) que devuelva los datos del alumno, el tipo de actividad y su estado en tiempo real (`Por asistir`, `Asistido`, `Cursando` o `Terminado`).