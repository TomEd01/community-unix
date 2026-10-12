# Documentación de Arquitectura y Lógica del Sistema

**Stack Tecnológico:** Frontend (Flutter) ↔ Lógica de Negocio (Django) ↔ Base de Datos (Supabase / PostgreSQL)

---

## 1. Interfaz de Comunidad (Alumnos / Visitantes / Externos)

| Pantalla / Componente (Flutter) | Campos y DB (Supabase / PostgreSQL) | Lógica de Negocio (Django) | Acción / Endpoint |
| :--- | :--- | :--- | :--- |
| **Completar Perfil**<br>(Onboarding único) | **Tabla:** `perfiles`<br>`nombre_completo` (Varchar)<br>`num_control` (Varchar, Nullable)<br>`institucion` (Varchar)<br>`rol` (Enum: Alumno, Maestro, Externo, Super_admin) | Pre-llena el nombre desde el token de Google (OAuth). Bloquea la auto-asignación de roles administrativos (`Super_admin`). El nivel de acceso se protege por base de datos usando RLS de Supabase. | **POST**<br>`/api/usuarios/perfil/` |
| **Dashboard (Home)** | **Tabla:** `historial_xp`, `macro_eventos`<br>`nivel_actual` (Varchar)<br>`total_xp` (Integer) | Consulta el saldo total sumando registros del Ledger (`historial_xp`). Retorna lista de `macro_eventos` activos. | **GET** `/api/macro_eventos/`<br>**GET** `/api/usuarios/me/` |
| **Inscripción a Macro Evento**<br>(Contenedor Padre) | **Tabla:** `inscripciones_macro`<br>`usuario_id` (UUID)<br>`macro_evento_id` (UUID)<br>`profesor_referencia_id` (UUID, Nullable) | **Regla Crítica:** Flutter exige llenar el Dropdown "¿Por parte de qué profesor asistes?". Permite valor "Ninguno" (Null). Al inscribirse exitosamente, otorga 5 XP base en el Ledger. | **POST**<br>`/api/inscripciones/macro/` |
| **Detalle: Postulación a Actividad**<br>(Si estado = *reclutando*) | **Tabla Silenciosa:** `solicitudes_expositor`<br>`actividad_id` (UUID)<br>`usuario_id` (UUID)<br>`tema_propuesto` (Varchar, 100)<br>`objetivo_platica` (Text) | **Modelo Pull:** Django inserta el registro en Supabase. *NO dispara correos ni notificaciones push*. Espera revisión manual del Super Admin. | **POST**<br>`/api/solicitudes/` |
| **Check-in / Registrar Asistencia**<br>(Exposiciones y Talleres) | **Tabla:** `asistencias_actividad`<br>`pin_ingresado` (Varchar, 5)<br>`latitud_alumno` (Float8)<br>`longitud_alumno` (Float8)<br>**Constraint:** `UNIQUE(usuario_id, actividad_id)` | **Doble Candado + Unique Constraint:** Valida proximidad GPS y PIN. Supabase rechaza duplicados automáticamente por el Unique Constraint evitando doble check-in. Otorga XP al finalizar el evento. | **POST**<br>`/api/asistencias/check-in/` |

---

## 2. Paneles de Administración ("Mago de Oz" y Maestros)

| Pantalla / Componente (Flutter) | Campos y DB (Supabase / PostgreSQL) | Lógica de Negocio (Django) | Acción / Endpoint |
| :--- | :--- | :--- | :--- |
| **Gestor de Macro Eventos y Actividades** (Super Admins) | **Tablas:** `macro_eventos` (Padre), `actividades` (Hijo)<br>`tipo` (Enum: Curso, Exposicion, Taller)<br>`estado` (Enum: reclutando, borrador, publicado)<br>`cupo_maximo` (Int)<br>`coordenadas` (Point / Float8) | El Super Admin crea el Macro Evento y sus sub-actividades. Las coordenadas de la Actividad definen el epicentro físico para validar la asistencia en Exposiciones/Talleres. | **POST / PUT** `/api/admin/macro_eventos/`<br>`/api/admin/actividades/` |
| **Bandeja de Solicitudes**<br>(Super Admins) | **Tabla:** `solicitudes_expositor` | El admin entra proactivamente al detalle de la actividad para leer la cola de solicitudes. Al aprobar:<br>1. Cambia estado a `borrador`.<br>2. Asigna etiqueta `Expositor` al alumno. | **GET** `/api/admin/solicitudes/?actividad={id}`<br>**PUT** `/api/admin/solicitudes/{id}/aprobar` |
| **Panel Exclusivo de Maestro**<br>(Filtro "Mis Alumnos") | **Tabla:** `inscripciones_macro`<br>Filtro por `profesor_referencia_id` | Django consulta la DB filtrando las inscripciones donde el profesor logueado coincida con el Dropdown que llenó el alumno. Muestra el progreso de *solo* sus alumnos para firmar créditos físicos. | **GET**<br>`/api/maestros/mis-alumnos/` |
| **Consola de Asistencia**<br>(Modo Geocerca + PIN) | **No persistente en DB (Redis o Cache local en Django)**<br>`pin_actual` (Varchar, 5) | Genera código efímero (TTL: 10 mins). Monitor en vivo hace polling cada 3s mostrando inscritos vs asistieron. | **GET**<br>`/api/admin/actividades/{id}/generar-pin` |
| **Consola de Asistencia**<br>(Override Manual) | **Tabla:** `asistencias_actividad` | Checkboxes. Si el hardware del alumno falla, el Expositor/Maestro marca la asistencia forzando la inserción en Supabase (ignorando GPS/PIN). | **POST**<br>`/api/admin/asistencia/manual` |

---

## 3. Desarrollo Lógico de la Geocerca y Prevención de Fraudes

Para asegurar al 100% que los alumnos están físicamente en el salón sin depender de la red Wi-Fi escolar, implementamos el sistema de **Doble Candado: Geocerca (GPS) + Prueba de Vida (PIN Efímero)**, reforzado por la base de datos.

### Fase 1: Preparación (El Epicentro)
Cuando el Super Admin crea la *Actividad* (Exposición/Taller) dentro del Macro Evento, registra las coordenadas exactas (`latitud_actividad`, `longitud_actividad`) y un `radio_geocerca` (ej. 50 metros).

### Fase 2: Ejecución del Check-In (Frontend - Flutter)
1. El expositor proyecta el **PIN efímero** de 5 dígitos (válido por 10 minutos).
2. El alumno, en Flutter, presiona "Registrar Asistencia".
3. Flutter usa `geolocator` con precisión alta (solicitando permisos si es necesario) para capturar `latitud_alumno` y `longitud_alumno`.
4. Envía un JSON con token JWT, `pin_ingresado` y coordenadas a Django.

### Fase 3: El Candado (Backend - Django + Supabase)
1. **Validación de Tiempo y PIN:** ¿El PIN coincide y el TTL es válido? *(Si falla: "PIN incorrecto/expirado").*
2. **Cálculo Haversine:** Django calcula la distancia esférica en metros entre las coordenadas del evento y del alumno.
3. **Veredicto Geocerca:** ¿Distancia <= 50m?
   * *Mayor a 50m:* Se rechaza. *"Estás demasiado lejos."*
   * *Menor a 50m:* Pasa a la capa de Base de Datos.
4. **Restricción de Base de Datos (Supabase):** Se intenta insertar en `asistencias_actividad`. Gracias al **Unique Constraint** `UNIQUE(usuario_id, actividad_id)`, si el alumno ya se había registrado (o intenta interceptar la petición y mandarla dos veces), Supabase bota la transacción, previniendo la duplicación de XP de manera inmutable.

---

## 4. Sistema de Verificación de Folios (Criptográficos)

Para garantizar la validez de los créditos escolares (ej. liberar materia o servicio social tras 5 exposiciones impartidas/asistidas), el sistema digital no imprime un PDF hackeable, sino que opera con un validador de base de datos.

| Componente | Flujo y Lógica | Endpoint asociado |
| :--- | :--- | :--- |
| **Generación de Folio** (Django) | Al cumplir condiciones (ej. terminar curso asíncrono o sumar 5 expos impartidas), Django genera un hash criptográfico amigable: `UNIX-{num_control}-{5_letras_random}` y lo guarda en el historial/asistencia. | Se genera internamente en el Check-in o completado de curso. |
| **Visualización** (Alumno) | Flutter muestra un banner/modal brillante con el Folio generado para que el alumno se lo presente físicamente al Jefe de Departamento. | **GET** `/api/historial_xp/folios` |
| **Verificador de Folios** (Jefes / Maestros) | Interfaz minimalista en Flutter con un simple `InputText`. El Jefe de Depto ingresa el folio que le muestra el alumno. | **GET** `/api/verificar-folio/{folio}` |
| **Respuesta del Verificador** (Supabase → Django) | Django busca el folio exacto en la base de datos. Si existe, retorna un Modal de Éxito con los campos inmutables: **Nombre, Número de Control, Actividad y Fecha**. Si no existe o fue alterado, retorna un Error crítico (Fraude). | Retorna JSON con `is_valid: true`, y datos del alumno. |