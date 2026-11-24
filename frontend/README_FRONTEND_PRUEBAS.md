# Comunidad UNIX ITC — solo frontend para pruebas

## Qué conservarás real

El acceso de Google, los tokens, los datos de perfil (nombre, rol e ID), usuarios y las relaciones existentes con profesores/horarios conservan sus servicios originales. El backend que ya utiliza tu proyecto sigue siendo necesario para esas funciones. No se incluye ningún backend ni cambio de base de datos.

## Qué contiene esta entrega

Dashboard con nivel y XP; cursos y módulos; enlaces externos de video; exposiciones; eventos con cupo y botón Asistir/Agotado; solicitud de expositor solo en Reclutando; administración de cursos, eventos y solicitudes; selección de varios encargados con búsqueda. Las pantallas nuevas muestran un aviso de datos de ejemplo.

Los ejemplos NO sustituyen la identidad del usuario conectado. Los profesores del selector nuevo están identificados como profesores de ejemplo; el vínculo real del alumno con su profesor se conserva por separado.

## Cómo instalar

Haz una copia de tu frontend actual. El ZIP contiene la carpeta `frontend/` completa. Para integrar los cambios, copia `lib/` y `pubspec.yaml` sobre tu frontend; conserva tus configuraciones de Google y tus servicios existentes. Si ejecutas macOS, incorpora también las dos configuraciones de permisos de `macos/Runner/*.entitlements`.

Desde tu carpeta frontend ejecuta:

```sh
flutter pub get
flutter run -d chrome --web-port=50243
```

Entra con el login normal. No hay acceso simulado ni se crean cuentas de prueba. Para probar otro rol utiliza una cuenta existente de ese rol.

## Dónde están los ejemplos

**`lib/portal/demo_data.dart`** contiene los ejemplos de LAS PANTALLAS NUEVAS:

- `courses`: cursos, módulos y progreso.
- `instructors`: encargados ficticios del selector de eventos.
- `events`: eventos, talleres, exposiciones, cupos e inscritos.
- `applications`: solicitudes, experiencia y propuesta.
- `_xp`: puntos XP de prueba.

Los cambios realizados desde estas pantallas duran solo en memoria. Se reinician con Hot Restart o al recargar/cerrar la aplicación. No se envían al servidor, no modifican tu base de datos ni se guardan en SharedPreferences. Una recarga elimina los cambios de prueba de la sesión, pero el archivo de código sigue disponible para iniciar otra prueba.

La selección de documentos muestra únicamente el nombre como ejemplo: no conserva ni sube el archivo. La carga y visualización reales quedan pendientes. Puedes agregar enlaces HTTPS de YouTube o Vimeo para probar su visualización externa; no se descargan videos al proyecto. La disponibilidad del reproductor depende de la plataforma y de que el autor permita incrustarlo; también existe Abrir en plataforma.

Hay pantallas antiguas con sus propios datos de demostración que se conservan como estaban; este archivo centraliza únicamente los ejemplos nuevos.

## Dónde conectar después Backend/ABD

**`lib/portal/api.dart`**, métodos `request` y `upload`, es el punto pendiente de integración de estas funciones nuevas. Los identificadores internos como `cursos/` y `eventos/` se usan ahora solo para seleccionar acciones locales; no son llamadas HTTP ni una especificación de URLs obligatorias para Backend.

Cuando el equipo tenga los servicios reales:

1. Implementar ahí el acceso a sus endpoints y adaptar sus respuestas a los campos que usan las pantallas.
2. Retirar las llamadas a `PortalExamples` y la importación `demo_data.dart`.
3. Establecer `useExamples = false` y eliminar `lib/portal/demo_data.dart` cuando ya no tenga referencias.
4. Retirar o conservar el aviso según `useExamples` (desaparece automáticamente al quedar en false).

Para comprobar cómo se ven las secciones pendientes sin ejemplos, puedes ejecutar:

```sh
flutter run -d chrome --web-port=50243 --dart-define=PORTAL_EJEMPLOS=false
```

En esta entrega esa opción muestra “Conexión pendiente…” en las funciones nuevas; no las conecta por sí sola. Las conexiones originales de login y perfiles siguen por su cuenta.

No se eliminan archivos automáticamente al ejecutar la app: no hay forma fiable de detectar que la conexión ya es correcta. Los ejemplos se dejan de utilizar al desactivarlos y se retiran del código al terminar la integración.

Los cambios de ejemplo se comparten entre pantallas dentro de la misma ejecución; no representan separación real por usuario ni permisos de servidor. Esa validación corresponderá a los servicios reales.

## Validación de esta entrega

Análisis estático Dart sin incidencias en las pantallas modificadas. Se verificaron 17 comprobaciones de lógica de ejemplos (XP, cupo, cancelación, encargados, solicitudes, documentos y enlaces). No se ejecutó Flutter ni se verificó visualmente la aplicación en un navegador en este entorno.
