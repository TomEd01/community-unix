-- Comunidad UNIX
-- Esquema inicial Supabase / PostgreSQL. Revisar en desarrollo antes de produccion.
-- No contiene datos de ejemplo ni credenciales.

begin;
create extension if not exists pgcrypto;

create type public.rol_usuario as enum ('Alumno', 'Maestro', 'Externo', 'Super_admin');
create type public.tipo_actividad as enum ('Curso', 'Exposicion', 'Taller');
create type public.estado_macro_evento as enum ('borrador', 'publicado', 'archivado');
create type public.estado_actividad as enum ('borrador', 'reclutando', 'publicada', 'en_curso', 'finalizada', 'cancelada');
create type public.estado_solicitud as enum ('pendiente', 'aprobada', 'rechazada');
create type public.tipo_movimiento_xp as enum ('inscripcion_macro', 'asistencia', 'curso_completado', 'exposicion_impartida', 'ajuste_admin', 'reversion');

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = ''
as $$ begin new.updated_at = now(); return new; end; $$;

create table public.perfiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique,
  nombre_completo varchar(160) not null,
  num_control varchar(40) unique,
  institucion varchar(180) not null,
  rol public.rol_usuario not null default 'Externo',
  nivel_actual varchar(40) not null default 'Principiante',
  onboarding_completado boolean not null default false,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint perfiles_nombre_no_vacio check (length(trim(nombre_completo)) > 0),
  constraint perfiles_institucion_no_vacia check (length(trim(institucion)) > 0),
  constraint perfiles_num_control_no_vacio check (num_control is null or length(trim(num_control)) > 0)
);
create index idx_perfiles_rol_activo on public.perfiles (rol, activo);
create index idx_perfiles_nombre on public.perfiles (nombre_completo);
create trigger trg_perfiles_updated_at before update on public.perfiles for each row execute function public.set_updated_at();

create table public.macro_eventos (
  id uuid primary key default gen_random_uuid(),
  titulo varchar(180) not null,
  descripcion text not null default '',
  estado public.estado_macro_evento not null default 'borrador',
  fecha_inicio timestamptz,
  fecha_fin timestamptz,
  creado_por uuid not null references public.perfiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint macro_eventos_titulo_no_vacio check (length(trim(titulo)) > 0),
  constraint macro_eventos_fechas_validas check (fecha_fin is null or fecha_inicio is null or fecha_fin >= fecha_inicio)
);
create index idx_macro_eventos_estado_fecha on public.macro_eventos (estado, fecha_inicio);
create trigger trg_macro_eventos_updated_at before update on public.macro_eventos for each row execute function public.set_updated_at();

create table public.actividades (
  id uuid primary key default gen_random_uuid(),
  macro_evento_id uuid not null references public.macro_eventos(id) on delete restrict,
  titulo varchar(180) not null,
  descripcion text not null default '',
  tipo public.tipo_actividad not null,
  estado public.estado_actividad not null default 'borrador',
  cupo_maximo integer,
  fecha_inicio timestamptz,
  fecha_fin timestamptz,
  lugar varchar(180),
  latitud_actividad double precision,
  longitud_actividad double precision,
  radio_geocerca_m integer not null default 50,
  creado_por uuid not null references public.perfiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint actividades_titulo_no_vacio check (length(trim(titulo)) > 0),
  constraint actividades_cupo_valido check (cupo_maximo is null or cupo_maximo > 0),
  constraint actividades_radio_valido check (radio_geocerca_m between 10 and 1000),
  constraint actividades_latitud_valida check (latitud_actividad is null or latitud_actividad between -90 and 90),
  constraint actividades_longitud_valida check (longitud_actividad is null or longitud_actividad between -180 and 180),
  constraint actividades_coordenadas_pareadas check ((latitud_actividad is null and longitud_actividad is null) or (latitud_actividad is not null and longitud_actividad is not null)),
  constraint actividades_fechas_validas check (fecha_fin is null or fecha_inicio is null or fecha_fin >= fecha_inicio)
);
create index idx_actividades_macro_evento on public.actividades (macro_evento_id);
create index idx_actividades_estado_fecha on public.actividades (estado, fecha_inicio);
create trigger trg_actividades_updated_at before update on public.actividades for each row execute function public.set_updated_at();

create table public.inscripciones_macro (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.perfiles(id) on delete restrict,
  macro_evento_id uuid not null references public.macro_eventos(id) on delete restrict,
  profesor_referencia_id uuid references public.perfiles(id) on delete restrict,
  inscrito_at timestamptz not null default now(),
  constraint inscripciones_macro_unicas unique (usuario_id, macro_evento_id),
  constraint inscripciones_profesor_distinto check (profesor_referencia_id is null or profesor_referencia_id <> usuario_id)
);
create index idx_inscripciones_macro_profesor on public.inscripciones_macro (profesor_referencia_id, usuario_id);
create index idx_inscripciones_macro_evento on public.inscripciones_macro (macro_evento_id);

create table public.solicitudes_expositor (
  id uuid primary key default gen_random_uuid(),
  actividad_id uuid not null references public.actividades(id) on delete restrict,
  usuario_id uuid not null references public.perfiles(id) on delete restrict,
  tema_propuesto varchar(100) not null,
  objetivo_platica text not null,
  estado public.estado_solicitud not null default 'pendiente',
  revisado_por uuid references public.perfiles(id) on delete restrict,
  revisado_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint solicitudes_tema_no_vacio check (length(trim(tema_propuesto)) > 0),
  constraint solicitudes_objetivo_no_vacio check (length(trim(objetivo_platica)) > 0),
  constraint solicitudes_unicas unique (actividad_id, usuario_id),
  constraint solicitudes_revision_consistente check ((estado = 'pendiente' and revisado_por is null and revisado_at is null) or (estado <> 'pendiente' and revisado_por is not null and revisado_at is not null))
);
create index idx_solicitudes_estado_actividad on public.solicitudes_expositor (actividad_id, estado);
create trigger trg_solicitudes_updated_at before update on public.solicitudes_expositor for each row execute function public.set_updated_at();

create table public.asistencias_actividad (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.perfiles(id) on delete restrict,
  actividad_id uuid not null references public.actividades(id) on delete restrict,
  metodo varchar(20) not null default 'check_in',
  latitud_alumno double precision,
  longitud_alumno double precision,
  distancia_metros double precision,
  registrada_por uuid references public.perfiles(id) on delete restrict,
  asistio_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint asistencias_unicas unique (usuario_id, actividad_id),
  constraint asistencias_metodo_valido check (metodo in ('check_in', 'manual')),
  constraint asistencias_latitud_valida check (latitud_alumno is null or latitud_alumno between -90 and 90),
  constraint asistencias_longitud_valida check (longitud_alumno is null or longitud_alumno between -180 and 180),
  constraint asistencias_coordenadas_pareadas check ((latitud_alumno is null and longitud_alumno is null) or (latitud_alumno is not null and longitud_alumno is not null)),
  constraint asistencias_distancia_valida check (distancia_metros is null or distancia_metros >= 0),
  constraint asistencias_override_auditable check (metodo <> 'manual' or registrada_por is not null)
);
create index idx_asistencias_actividad_fecha on public.asistencias_actividad (actividad_id, asistio_at);
create index idx_asistencias_usuario_fecha on public.asistencias_actividad (usuario_id, asistio_at);

create table public.historial_xp (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.perfiles(id) on delete restrict,
  cantidad integer not null,
  tipo public.tipo_movimiento_xp not null,
  referencia_tipo varchar(40),
  referencia_id uuid,
  clave_idempotencia varchar(120) unique,
  descripcion varchar(240) not null default '',
  creado_por uuid references public.perfiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint historial_xp_no_cero check (cantidad <> 0),
  constraint historial_xp_ajuste_con_autor check (tipo <> 'ajuste_admin' or creado_por is not null)
);
create index idx_historial_xp_usuario_fecha on public.historial_xp (usuario_id, created_at desc);
create index idx_historial_xp_referencia on public.historial_xp (referencia_tipo, referencia_id);

create table public.folios (
  id uuid primary key default gen_random_uuid(),
  codigo varchar(80) not null unique,
  usuario_id uuid not null references public.perfiles(id) on delete restrict,
  actividad_id uuid references public.actividades(id) on delete restrict,
  tipo_logro varchar(60) not null,
  emitido_at timestamptz not null default now(),
  emitido_por uuid references public.perfiles(id) on delete restrict,
  revocado_at timestamptz,
  motivo_revocacion varchar(240),
  constraint folios_codigo_no_vacio check (length(trim(codigo)) > 0),
  constraint folios_revocacion_consistente check ((revocado_at is null and motivo_revocacion is null) or (revocado_at is not null and motivo_revocacion is not null))
);
create index idx_folios_usuario_fecha on public.folios (usuario_id, emitido_at desc);
create index idx_folios_actividad on public.folios (actividad_id);

-- RLS habilitado: denegacion por defecto hasta definir politicas segun el modelo
-- de identidad definitivo. No otorgar acceso directo al cliente sin politicas.
alter table public.perfiles enable row level security;
alter table public.macro_eventos enable row level security;
alter table public.actividades enable row level security;
alter table public.inscripciones_macro enable row level security;
alter table public.solicitudes_expositor enable row level security;
alter table public.asistencias_actividad enable row level security;
alter table public.historial_xp enable row level security;
alter table public.folios enable row level security;

revoke all on table public.perfiles, public.macro_eventos, public.actividades,
  public.inscripciones_macro, public.solicitudes_expositor, public.asistencias_actividad,
  public.historial_xp, public.folios from anon, authenticated;

commit;

-- Requisitos operativos:
-- * PIN efimero en Redis/cache Django con TTL de 600 segundos; no persistirlo.
-- * Validar PIN y geocerca en servidor; no confiar en distancia enviada por Flutter.
-- * Insertar asistencia y XP en una transaccion y usar idempotencia.
-- * SUPABASE_SERVICE_ROLE_KEY solo en Django, nunca en Flutter.
-- * Definir y probar politicas RLS segun el proveedor de identidad final.
-- * Configurar backups, pruebas de restauracion, alertas, rate limits y rotacion de secretos.
