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

* \[ \] (Frontend - Fish) Pantalla de completado de perfil (Nombre editable, Selección de Rol: Alumno, Maestro, Externo).

* \[ \] (Frontend - Fish) Mostrar/ocultar campos obligatorios según el rol (ej. Procedencia).

* \[ \] (Base de Datos - Fiscal) Asegurar que la tabla Usuarios soporte roles y campos nulos dinámicos.

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

* \[ \] (Frontend - Fish) Añadir el campo Dropdown obligatorio "Seleccionar Profesor (o Ninguno)" en la pantalla de inscripción a Macro Eventos.

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

* \[ \] (Frontend - Fish) Diseñar el Modal de éxito/error al verificar el folio (Mostrar: Nombre del alumno, Número de control, Actividad completada, Fecha).

* \[ \] (Backend) Crear generador de folios criptográficos para finalización de cursos/exposiciones (Formato sugerido: UNIX-{num_control}-{5_letras_random}) y guardarlo en la tabla de asistencias.

* \[ \] (Backend) Crear un endpoint público (GET `/api/verificar-folio/{folio}`) que devuelva el nombre del alumno y el evento completado.