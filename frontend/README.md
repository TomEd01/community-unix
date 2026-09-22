# Comunidad Unix ITC — Flutter Web v3.1 corregida

Conversión de los bocetos de Figma a una aplicación Flutter Web responsive.

## Pantallas

- Inicio de sesión
- Registro con selección de Alumno, Instructor o Externo
- Dashboard del Alumno (también reutilizable para Externo)
- Mis cursos con progreso semanal
- Catálogo con búsqueda y filtros
- Agenda de eventos
- Constancias y descarga visual
- Perfil editable
- Mascota Lexus animada: flotación, parpadeo, alas y reacción al cursor

## Ejecutar en Windows

1. Instala Flutter y activa el soporte web:

   ```powershell
   flutter config --enable-web
   ```

2. Abre PowerShell en esta carpeta y completa los archivos de plataforma:

   ```powershell
   flutter create . --platforms=web
   flutter pub get
   flutter run -d chrome
   ```

3. Para generar la versión publicable:

   ```powershell
   flutter build web
   ```

El resultado estará en `build\web`.

## Uso de la demostración

- En `Iniciar sesión con Google`, la aplicación abre el dashboard simulado.
- En registro, selecciona el rol y completa los campos.
- Todas las opciones del menú abren su propia sección funcional.
- `Cerrar sesión` regresa a la pantalla inicial.

La autenticación es visual y está lista para conectarse posteriormente con Supabase.
