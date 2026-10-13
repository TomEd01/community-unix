# Auditoría de seguridad — Comunidad UNIX

**Fecha de elaboración:** 12 de octubre de 2026  
**Sistema revisado:** Comunidad UNIX  
**Alcance:** revisión estática parcial del backend Django y configuración de Supabase/PostgreSQL, basada en los comandos y resultados compartidos durante la revisión.  
**Estado:** preliminar; no equivale a una prueba de penetración ni a una auditoría integral.

## 1. Resumen ejecutivo

La revisión identificó un hallazgo prioritario en el endpoint de finalización de perfil: `CompletarPerfilView` busca una cuenta a partir del correo recibido en la petición y permite modificar datos del usuario y su rol, sin que el código revisado muestre una comprobación de identidad o de propiedad de la cuenta. En la configuración examinada no se encontraron permisos globales personalizados de Django REST Framework, por lo que, si no existe una protección externa, la vista podría aceptar solicitudes no autenticadas.

También se detectó que la vista de finalización de perfil acepta el rol desde el cliente y lo utiliza para decidir qué perfil crear o actualizar. La autorización de roles debe hacerse del lado del servidor y no debe confiar en valores enviados por el cliente.

En Supabase, las ocho tablas públicas examinadas tenían Row Level Security (RLS) habilitado, pero la consulta a `pg_policies` no devolvió políticas para el esquema `public`. Esto requiere verificación funcional y revisión de la arquitectura antes de concluir el impacto: con RLS habilitado y sin políticas, los accesos de roles sujetos a RLS normalmente se deniegan; una credencial privilegiada como `service_role` puede omitir RLS y debe permanecer exclusivamente en el servidor.

La configuración Django observada contiene `DEBUG = True`, `ALLOWED_HOSTS = []` y `CORS_ALLOW_ALL_ORIGINS = True`. El usuario indicó que el backend funciona solo localmente, por lo que estos ajustes deben evaluarse en contexto de desarrollo y revisarse antes de desplegar. No se confirmó una filtración de credenciales reales en el historial de Git; las asignaciones históricas revisadas parecen corresponder a claves de ejemplo, pero el filtro automatizado no lo garantiza por completo.

## 2. Alcance y limitaciones

### Revisado
- `backend/backend/settings.py`
- `backend/accounts/views.py`
- `backend/accounts/serializers.py`
- `backend/accounts/models.py`
- `backend/accounts/urls.py`
- `backend/backend/urls.py`
- Consultas de metadatos y políticas en Supabase/PostgreSQL compartidas por el usuario.
- Búsquedas estáticas en archivos Python del backend.
- Revisión heurística de asignaciones históricas de `SECRET_KEY` en algunos commits.

### No revisado o no verificado
- Ejecución de pruebas de penetración o explotación controlada.
- Comportamiento real de todos los endpoints en ejecución.
- Código completo de las vistas de la aplicación `events` y posibles protecciones fuera de los archivos buscados.
- Permisos heredados, privilegios por defecto y configuración completa de roles en PostgreSQL.
- Pruebas de RLS con los roles reales usados por la aplicación.
- Configuración de despliegue, proxy inverso, TLS, firewall y variables de entorno en producción.
- Flujo completo de Flutter, Google OAuth y almacenamiento/expiración de JWT.
- Análisis exhaustivo de todo el historial de Git o de todos los archivos y secretos.
- Pruebas automatizadas, restauración de copias de seguridad o revisión de dependencias.

Los resultados se deben considerar un diagnóstico preliminar, no una certificación de seguridad.

## 3. Hallazgos

### H-01 — Finalización de perfil sin verificación visible de identidad

**Prioridad:** Alta  
**Estado:** Confirmado en revisión estática; explotabilidad pendiente de prueba.

**Evidencia observada:** En `backend/accounts/views.py`, `CompletarPerfilView.post()` obtiene el correo desde `request.data`, busca el usuario por correo y modifica su nombre y rol. No declara `permission_classes` ni se observa en esa vista una comprobación de que el usuario autenticado sea el propietario de la cuenta. La ruta es `api/auth/completar_perfil/`.

**Impacto potencial:** Si no existe una protección global o externa, un solicitante podría intentar modificar el perfil de otro usuario proporcionando su correo. También podría intentar cambiar el rol y crear o actualizar el perfil correspondiente.

**Recomendaciones:**
1. Exigir autenticación para completar el perfil, usando el mecanismo JWT que corresponda a la aplicación.
2. Derivar la identidad de `request.user` autenticado, no de un correo arbitrario enviado por el cliente.
3. Si el flujo necesita una fase previa al inicio de sesión, usar un token de onboarding de corta duración, firmado y vinculado a una cuenta, con audiencia, expiración y uso limitado; no usar únicamente el correo como prueba de identidad.
4. No permitir que el cliente cambie libremente el rol de un usuario existente.
5. Validar autorización y transición de estados del onboarding en el servidor.
6. Agregar pruebas que demuestren que un usuario no puede modificar el perfil de otro, cambiar su rol o completar perfiles con datos de otra cuenta.

### H-02 — Rol aceptado desde el cliente y almacenado sin opciones restringidas

**Prioridad:** Alta  
**Estado:** Confirmado en revisión estática; impacto depende de las autorizaciones en el resto del sistema.

**Evidencia observada:** `GoogleAuthSerializer` define `rol` como un `CharField` opcional con longitud máxima, sin opciones enumeradas. `Usuario.rol` es un `CharField(max_length=50)`. La vista de Google usa el rol recibido al crear un usuario; la vista de completar perfil acepta otro rol y lo guarda.

**Impacto potencial:** Valores arbitrarios o roles no autorizados podrían almacenarse. Si el rol habilita funciones o permisos, podría producirse una elevación de privilegios lógica.

**Recomendaciones:**
1. Definir roles válidos explícitos en el servidor, con elecciones de modelo/serializer o validación equivalente.
2. Determinar el rol permitido por el flujo de negocio; nunca confiar en que el cliente es honesto.
3. Separar roles funcionales (`Alumno`, `Instructor`, `Externo`) de privilegios administrativos de Django (`is_staff`, `is_superuser`).
4. Prohibir la asignación de roles privilegiados mediante el endpoint público de Google.
5. Añadir pruebas para roles desconocidos, valores con diferencias de mayúsculas, cambios de rol y cuentas existentes.

### H-03 — Supabase: RLS habilitado, pero no se encontraron políticas públicas

**Prioridad:** Alta para revisión funcional  
**Estado:** La consulta de políticas no devolvió filas; impacto de acceso real pendiente de confirmar.

**Evidencia observada:** RLS estaba habilitado y no forzado en ocho tablas: `actividades`, `asistencias_actividad`, `folios`, `historial_xp`, `inscripciones_macro`, `macro_eventos`, `perfiles` y `solicitudes_expositor`. La consulta a `pg_policies` para `public` devolvió “Success. No rows returned”. La consulta de concesiones mostró privilegios de tabla para `service_role`, pero no filas explícitas para `anon` o `authenticated` en el resultado compartido. Esto no descarta privilegios heredados o por defecto.

**Impacto potencial:** Para roles sujetos a RLS, no tener políticas normalmente deniega acceso a filas. Esto puede romper funciones legítimas de la aplicación. Si el backend usa una clave `service_role`, esa clave puede omitir RLS; un uso inseguro o exposición de dicha credencial sería un riesgo significativo.

**Recomendaciones:**
1. Confirmar qué cliente y credencial utiliza cada flujo (Flutter, Django, tareas de servidor).
2. Mantener cualquier clave `service_role` exclusivamente en el servidor; nunca incluirla en Flutter, JavaScript cliente, repositorio ni artefactos públicos.
3. Diseñar políticas mínimas por tabla y operación (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) basadas en identidad y propiedad de datos.
4. No crear políticas permisivas genéricas solo para hacer funcionar la aplicación.
5. Probar con los roles reales `anon`, `authenticated` y el rol de servidor; verificar acceso permitido y denegado.
6. Revisar privilegios heredados, `ALTER DEFAULT PRIVILEGES`, funciones `SECURITY DEFINER` y exposición por vistas/RPC.
7. Revisar si alguna tabla requiere `FORCE ROW LEVEL SECURITY`; que `relforcerowsecurity` sea falso no constituye por sí solo una vulnerabilidad.

### H-04 — `DEBUG = True`

**Prioridad:** Baja en desarrollo local; alta si llega a producción.  
**Estado:** Confirmado en configuración local.

**Evidencia observada:** `DEBUG = True` en `backend/backend/settings.py`. El usuario confirmó que el backend solo funciona localmente para desarrollo.

**Impacto potencial:** Las páginas de error detalladas pueden revelar rutas, variables y detalles internos si se expone un entorno con depuración habilitada.

**Recomendaciones:**
1. Leer `DEBUG` desde configuración de entorno.
2. Usar `DEBUG=False` en producción y verificarlo en el proceso de despliegue.
3. Agregar una comprobación automatizada que impida desplegar con `DEBUG=True`.

### H-05 — `ALLOWED_HOSTS = []`

**Prioridad:** Informativa en el entorno actual; pendiente para despliegue.  
**Estado:** Confirmado en configuración local.

**Evidencia observada:** `ALLOWED_HOSTS = []`.

**Impacto potencial:** Una lista vacía no es una configuración adecuada para un despliegue normal; las solicitudes con nombres de host no permitidos pueden rechazarse. No se considera una vulnerabilidad explotable por sí sola en este contexto.

**Recomendaciones:**
1. Configurar explícitamente los hosts reales de producción.
2. No usar `'*'` como solución permanente sin una validación equivalente delante de Django.
3. Probar el despliegue con el dominio esperado.

### H-06 — CORS permite todos los orígenes

**Prioridad:** Baja en desarrollo local; alta si se conserva sin evaluar en producción.  
**Estado:** Confirmado en configuración local.

**Evidencia observada:** `CORS_ALLOW_ALL_ORIGINS = True`.

**Impacto potencial:** Permite solicitudes CORS desde cualquier origen, sujetas a otras condiciones del navegador y del servidor. CORS no reemplaza autenticación ni autorización; el riesgo depende de los datos, credenciales y mecanismos de autenticación utilizados.

**Recomendaciones:**
1. En producción, sustituirlo por una lista explícita de orígenes confiables.
2. No habilitar credenciales CORS para todos los orígenes.
3. Mantener separadas las configuraciones de desarrollo y producción.

### H-07 — Configuraciones de HTTPS, cookies seguras y HSTS no encontradas explícitamente

**Prioridad:** Pendiente de despliegue  
**Estado:** No se encontraron las asignaciones buscadas en `settings.py`; no se verificó si se gestionan en otra capa.

**Recomendaciones:**
1. En producción con HTTPS, evaluar `SECURE_SSL_REDIRECT`, `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE` y `SECURE_HSTS_SECONDS`.
2. Configurar estos ajustes según la topología real del proxy y confirmar que HTTPS está funcionando antes de habilitar HSTS.
3. No activar configuraciones de producción a ciegas en el entorno local.

### H-08 — JWT: revisar autorización y ciclo de vida

**Prioridad:** Media/alta; pendiente de pruebas  
**Estado:** Generación de JWT observada; configuración global de DRF/SimpleJWT no encontrada en la búsqueda inicial.

**Evidencia observada:** `GoogleLoginView` crea un `RefreshToken` y devuelve `refresh.access_token`. No se encontraron en `settings.py` asignaciones globales `REST_FRAMEWORK` o `SIMPLE_JWT`. Esto no prueba que no exista configuración adicional.

**Recomendaciones:**
1. Confirmar que el frontend almacena los tokens de forma segura y que el backend verifica la firma y expiración.
2. Configurar tiempos de vida adecuados y estrategia de revocación/rotación de refresh tokens, según el diseño.
3. Aplicar autenticación y permisos explícitos a endpoints privados.
4. No usar claims enviados por el cliente sin validación del token firmado.
5. Probar expiración, tokens inválidos y acceso a recursos de otro usuario.

### H-09 — Asignación directa histórica de `SECRET_KEY` parece de ejemplo

**Prioridad:** Informativa, con verificación pendiente  
**Estado:** No se confirmó una credencial real expuesta.

**Evidencia observada:** Un filtro heurístico clasificó las asignaciones en los commits `f755070`, `e08ce63` y `027cb7c` como valores que parecen claves de ejemplo. En commits más recientes, la clave se obtiene de una variable de entorno.

**Limitaciones:** Un filtro por palabras no demuestra que un valor sea inocuo. No se copió ni se expuso el valor de la clave durante esta revisión.

**Recomendaciones:**
1. Revisar el patrón de asignación de manera segura, sin imprimir la clave.
2. Si se confirma que alguna clave real llegó a un repositorio remoto, rotarla; la limpieza del historial no sustituye la rotación.
3. Usar una variable de entorno o un gestor de secretos para producción.
4. No compartir el valor real de `SECRET_KEY` en mensajes, informes ni capturas.

### H-10 — Modelo `Instructor` declara `procedencia` dos veces

**Prioridad:** Baja  
**Estado:** Confirmado en revisión estática.

**Evidencia observada:** En `backend/accounts/models.py`, `procedencia` se declara dos veces en `Instructor`; la segunda definición reemplaza la primera en el cuerpo de la clase.

**Impacto potencial:** Comportamiento y migraciones confusos, con posible discrepancia entre la intención del modelo y el esquema.

**Recomendaciones:**
1. Definir el campo una sola vez.
2. Revisar migraciones y estado de la base de datos antes de generar cambios.
3. Ejecutar pruebas de modelos y migraciones después de la corrección.

## 4. Aspectos positivos observados

- El inicio de sesión verifica el token de Google mediante `verify_oauth2_token` y usa `GOOGLE_CLIENT_ID`.
- El gestor de usuarios utiliza `set_password()` para establecer contraseñas.
- `AUTH_PASSWORD_VALIDATORS` contiene cuatro validadores estándar de Django.
- Está presente `SecurityMiddleware`, middleware CSRF, autenticación por sesión y `XFrameOptionsMiddleware`.
- Las tablas examinadas de Supabase tenían RLS habilitado.
- La búsqueda estática compartida no encontró cadenas explícitas como `service_role` o `SUPABASE_SERVICE_ROLE_KEY` en los archivos examinados; esto no descarta nombres indirectos, secretos en otros formatos o uso fuera del alcance de búsqueda.

## 5. Plan de remediación recomendado

### Prioridad 0 — Antes de cualquier despliegue
1. Corregir `CompletarPerfilView` para exigir una identidad verificable y autorizar la operación sobre la cuenta correspondiente.
2. Impedir que el cliente asigne libremente roles existentes o privilegiados.
3. Confirmar el diseño de acceso a Supabase y crear políticas RLS específicas por tabla/operación.
4. Verificar que ninguna credencial privilegiada esté incluida en Flutter ni en artefactos públicos.

### Prioridad 1 — Antes de integrar cambios de seguridad
1. Añadir pruebas automatizadas para usuario anónimo, usuario autenticado, usuario intentando modificar otra cuenta y valores de rol no permitidos.
2. Probar permisos de Supabase con los roles reales.
3. Confirmar autenticación, expiración y permisos de los JWT.
4. Definir configuraciones separadas para desarrollo y producción.

### Prioridad 2 — Higiene y despliegue
1. Definir hosts permitidos y CORS explícito en producción.
2. Configurar HTTPS, cookies seguras y HSTS según el despliegue.
3. Eliminar la declaración duplicada de `Instructor.procedencia` mediante una migración revisada.
4. Añadir análisis de dependencias y comprobaciones automáticas de seguridad.
5. Establecer un proceso para revisar logs, copias de seguridad y restauración.

## 6. Pruebas de aceptación

La remediación no se debe considerar completa hasta verificar al menos:

- Una petición anónima a completar perfil es rechazada.
- Un usuario autenticado no puede modificar el perfil de otra cuenta.
- Un usuario no puede cambiar su rol enviando un valor arbitrario.
- Un usuario no puede convertirse en `is_staff` o `is_superuser` mediante endpoints públicos.
- Un usuario solo accede a los registros que las políticas de negocio y RLS le permiten.
- Las solicitudes permitidas y denegadas se comprueban usando las credenciales reales de cada rol.
- El despliegue de producción tiene `DEBUG=False`, hosts permitidos y CORS restringido.
- No se publican secretos en el repositorio, en el frontend ni en el informe.
- Las migraciones y pruebas del flujo de onboarding se completan sin regresiones.

## 7. Conclusión

La revisión estática parcial detectó riesgos de autorización en la finalización de perfil y en la asignación de roles, además de una configuración de RLS que requiere definir o confirmar políticas. Las opciones de depuración y CORS observadas son coherentes con un entorno local de desarrollo, pero deben separarse y endurecerse para producción.

No se realizó una prueba de penetración y no se confirmó una filtración de secretos reales. Por ello, el sistema no debe describirse como “seguro” ni “vulnerable en todos los aspectos” hasta terminar las verificaciones pendientes. La recomendación es resolver primero los hallazgos de identidad, autorización y políticas RLS, y validar cada cambio con pruebas automatizadas antes del despliegue.

---

**Clasificación del documento:** Interno — contiene detalles técnicos de seguridad.  
**Recomendación de distribución:** Mantener el informe completo en un repositorio privado o en un espacio restringido. Si se necesita una versión pública, publicar un resumen sin detalles operativos que faciliten la explotación.
