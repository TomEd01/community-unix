# Comunidad UNIX — Base de datos

Este directorio contiene la documentación y el esquema inicial de la base de datos de Comunidad UNIX.

## Archivos

- `community_unix_schema.sql`: esquema PostgreSQL con tablas, relaciones, restricciones, índices y configuración inicial de seguridad para Supabase.
- `RULES.md`: lineamientos para el desarrollo, la seguridad y el mantenimiento de la base de datos.

## Configuración

1. Revisa el archivo `community_unix_schema.sql` antes de utilizarlo.
2. Ejecuta el esquema únicamente en una base de datos que aún no tenga estas tablas.
3. Define y verifica las políticas de Row Level Security (RLS) antes de habilitar el acceso de la aplicación.
4. Mantén las credenciales y claves privadas fuera del repositorio.

## Seguridad

- No publiques secretos, contraseñas ni claves privadas.
- Utiliza migraciones versionadas para cambios posteriores.
- Verifica los permisos y las políticas RLS antes de conectar la aplicación.
