# RULES.md

## Comunidad UNIX - Reglas de Backend y Base de Datos

**Stack oficial:** Flutter -\> Django -\> Supabase/PostgreSQL.

Estas reglas son obligatorias para mantener consistencia, evitar cambios
incompatibles y reducir riesgos de acceso indebido, fuga o perdida de
datos. Leer antes de modificar modelos, migraciones, endpoints,
politicas RLS o consultas.

## 1. Arquitectura

1.  Flutter presenta datos y consume la API. Nunca contiene secretos de
    base de datos.
2.  Django valida autenticacion, autorizacion y logica de negocio.
3.  PostgreSQL/Supabase es la fuente persistente de verdad y aplica
    restricciones, claves foraneas, unicidad y RLS.
4.  Ninguna regla critica depende solo de Flutter.
5.  No conectar Flutter directamente a tablas privadas para operaciones
    de negocio.
6.  Tablas, campos y endpoints deben respetar `ARCHITECTURE.md`. Todo
    cambio actualiza la documentacion y se comunica al equipo.
7.  No cambiar proveedor, identidad o modelo de permisos sin acuerdo del
    equipo.

## 2. Convenciones de datos

1.  Usar `snake_case` para tablas, columnas, indices y funciones.
2.  Usar UUID para identificadores y relaciones.
3.  Guardar fechas con zona horaria mediante `timestamptz`.
4.  Declarar claves foraneas y restricciones explicitas.
5.  Usar `NOT NULL`, `CHECK` y `UNIQUE` cuando la regla pueda
    garantizarse en SQL.
6.  `macro_eventos` es la entidad padre y `actividades` la entidad hija.
7.  No duplicar datos derivados como `total_xp` salvo que exista una
    cache documentada y reconciliable.
8.  No borrar historiales de asistencia, XP, folios o decisiones
    administrativas. Preferir estados, revocacion o baja logica.
9.  Cambios incompatibles de API deben coordinarse y versionarse.

## 3. Perfiles y roles

1.  El perfil se completa mediante `POST /api/usuarios/perfil/`.
2.  Verificar en el servidor el token de Google; no aceptar una cadena
    enviada por Flutter como prueba de identidad.
3.  Un usuario no puede asignarse `Super_admin`, cambiar su rol, su
    estado o su identidad.
4.  Asignar roles administrativos solo mediante proceso autorizado,
    auditado y aprobado por el equipo.
5.  Usar el rol de menor privilegio compatible con el onboarding.
6.  No confiar en un UUID enviado por el cliente; compararlo con el
    sujeto autenticado.
7.  Definir pruebas para cambios de nombre oficial, numero de control y
    rol.

## 4. Macroeventos y actividades

1.  `macro_eventos` es padre; `actividades` son hijas y deben tener
    `macro_evento_id`.
2.  Solo `Super_admin` autorizado puede crear, editar, publicar,
    cancelar o archivar eventos.
3.  Validar las transiciones de estado en Django.
4.  Antes de publicar, validar fechas, cupos y campos obligatorios.
5.  Latitud y longitud deben ser validas y aparecer como pareja. Limitar
    y documentar el radio de geocerca.
6.  No borrar eventos con historial; cancelar o archivar.
7.  Comprobar cupos dentro de una transaccion para evitar
    sobreinscripciones simultaneas.

## 5. Inscripciones y solicitudes

1.  Una persona solo puede inscribirse una vez al mismo macroevento:
    `UNIQUE(usuario_id, macro_evento_id)`.
2.  `profesor_referencia_id` puede ser `NULL` para la opcion Ninguno.
3.  Validar que el profesor de referencia sea un perfil autorizado.
4.  Aceptar solicitudes de expositor solo si la actividad esta en estado
    `reclutando`.
5.  Permitir una sola solicitud por usuario y actividad.
6.  Aprobar o rechazar solo con permiso administrativo y guardar revisor
    y fecha.
7.  No enviar correos ni notificaciones push desde solicitudes mientras
    `ARCHITECTURE.md` defina el modelo Pull.

## 6. Asistencia, PIN y geocerca

1.  Django genera el PIN de cinco digitos y lo guarda en Redis/cache del
    servidor con TTL de 600 segundos.
2.  No guardar el PIN efimero en tablas permanentes.
3.  Django calcula la distancia con las coordenadas del evento y del
    dispositivo. Nunca confiar en una distancia calculada por Flutter.
4.  Validar PIN, vigencia, coordenadas y distancia contra
    `radio_geocerca_m`.
5.  Rechazar coordenadas fuera de rango o faltantes cuando sean
    obligatorias.
6.  La base impone `UNIQUE(usuario_id, actividad_id)`.
7.  Insertar asistencia y recompensa XP en una transaccion o mecanismo
    idempotente equivalente.
8.  El override manual requiere permiso especial, motivo y
    `registrada_por`; nunca debe ser publico.
9.  Limitar intentos por usuario, actividad e IP y registrar fallos sin
    guardar secretos.
10. GPS no es prueba criptografica de ubicacion; documentar el riesgo de
    ubicacion falsificada.

## 7. XP y folios

1.  `historial_xp` es un ledger: se agregan movimientos y la API
    ordinaria no los edita ni elimina.
2.  Calcular XP desde movimientos validos. Flutter nunca decide la
    cantidad de XP.
3.  Cada recompensa debe tener idempotencia para impedir duplicados.
4.  Solo Django puede registrar XP tras validar una accion.
5.  Ajustes manuales requieren rol administrativo, motivo y auditoria.
6.  Generar folios unicos con aleatoriedad criptografica; no hacerlos
    predecibles.
7.  El folio no reemplaza autorizacion. Django busca el registro y
    devuelve solo los datos necesarios.
8.  La revocacion debe conservar historial y hacer que la verificacion
    devuelva no valido.

## 8. Autenticacion, autorizacion y RLS

1.  Verificar firma, emisor, audiencia, expiracion y sujeto de cada
    token.
2.  No autorizar por email, nombre, UUID recibido ni botones ocultos en
    Flutter.
3.  Aplicar denegacion por defecto: sin permiso explicito, se rechaza.
4.  Habilitar RLS en tablas expuestas a clientes y probar politicas por
    operacion.
5.  RLS puede no proteger conexiones privilegiadas: `service_role` puede
    omitir RLS.
6.  `SUPABASE_SERVICE_ROLE_KEY` solo existe en secretos de Django; nunca
    en Flutter, logs, builds ni repositorios.
7.  Definir una unica estrategia de identidad: Supabase Auth UID o UUID
    de Django con mapeo verificado. No mezclarlas implicitamente.
8.  Si Django usa un rol privilegiado, Django debe aplicar permisos por
    endpoint y objeto. Preferir credenciales de minimo privilegio y
    evaluar RLS con contexto de usuario.
9.  No conceder escritura general a `anon` ni permisos generales de
    update a usuarios sobre roles, XP, asistencias o folios.
10. Probar como anonimo, alumno, maestro, externo y administrador.

## 9. Endpoints y consultas

1.  Usar ORM o consultas parametrizadas. Prohibido concatenar entradas
    de usuario en SQL.
2.  Validar y limitar parametros, filtros, ordenamientos, archivos y
    JSON.
3.  Aplicar permisos por endpoint y objeto para evitar IDOR.
4.  GET no debe modificar datos; cada metodo HTTP debe respetar el
    contrato.
5.  No devolver trazas, SQL, secretos ni detalles internos al cliente.
6.  No registrar tokens, contrasenas, PIN activos, claves API ni datos
    personales innecesarios.
7.  Restringir CORS a origenes conocidos en produccion.
8.  Aplicar rate limiting a login, onboarding, check-in, solicitudes y
    verificacion de folios.
9.  Configurar limites, timeouts y paginacion para evitar abuso y
    consultas costosas.
10. No confiar en el cliente para roles, XP, cupos, aprobaciones o
    propiedad de registros.

## 10. Auditoria y recuperacion

Antes de cada entrega, revisar:

-   RLS habilitado y politicas verificadas por rol.
-   Grants de `anon`, `authenticated` y roles de servidor.
-   Claves foraneas, restricciones `UNIQUE`, `CHECK` e indices.
-   Consultas lentas e indices necesarios.
-   Fallos de autenticacion, errores de permisos y volumen anormal de
    peticiones.
-   Cambios de rol, acciones administrativas, overrides, ajustes de XP y
    revocaciones.
-   Secretos en Git, logs, archivos `.env` y builds.
-   Backups, retencion y una prueba real de restauracion.
-   Alertas de consumo, conexiones y almacenamiento.
-   Migraciones aplicadas en desarrollo, pruebas y produccion.

No ejecutar pruebas destructivas ni carga contra produccion sin
autorizacion, ventana acordada y plan de rollback.

## 11. Migraciones y Pull Requests

1.  Todo cambio de esquema debe ser una migracion versionada y
    revisable.
2.  No editar migraciones ya aplicadas en entornos compartidos; crear
    una migracion correctiva.
3.  Probar migraciones en desarrollo con datos de prueba.
4.  Evitar cambios manuales no documentados en Supabase.
5.  No ejecutar `DROP`, truncados o cambios masivos sin respaldo,
    aprobacion y rollback.
6.  Mantener `ARCHITECTURE.md`, `RULES.md`, modelos Django y contratos
    API sincronizados.
7.  Cada PR debe describir tablas/endpoints afectados, migracion,
    pruebas, riesgos y despliegue.
8.  No incluir `.venv`, claves, bases locales ni archivos generados en
    commits.
9.  Revisar diff, permisos, migraciones y secretos antes del merge.
10. No aplicar el SQL inicial sobre una base existente sin comparar
    primero tablas, tipos, datos y migraciones actuales.

## 12. Pruebas obligatorias

-   Un usuario no puede elevar su rol ni editar otro perfil.
-   Inscripciones simultaneas no duplican registros ni exceden cupos.
-   No se puede postular fuera de `reclutando`.
-   PIN vencido, PIN incorrecto, coordenadas invalidas y distancia
    excesiva se rechazan.
-   Dos check-ins simultaneos crean como maximo una asistencia y una
    recompensa.
-   Un alumno no puede ejecutar asistencia manual.
-   El cliente no puede crear ni editar movimientos de XP.
-   Folios inexistentes, alterados o revocados no se validan.
-   RLS impide consultar o modificar filas ajenas.
-   El build Flutter no contiene claves privilegiadas.

## 13. Decisiones por cerrar antes de produccion

1.  Confirmar si la identidad principal sera Supabase Auth o Django y
    definir el mapeo de usuarios.
2.  Escribir y probar politicas RLS finales y roles SQL para Django.
3.  Confirmar si `institucion` es obligatoria para todos los perfiles.
4.  Definir reglas de XP, reversiones e idempotencia.
5.  Definir auditoria y retencion de acciones administrativas.
6.  Definir el proceso controlado para asignar `Super_admin`.

**Regla final:** si un cambio debilita permisos, expone datos, elimina
restricciones o altera el contrato API, requiere revision de seguridad y
actualizacion de esta documentacion.
