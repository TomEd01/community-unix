# Web deployment

Compose runs an HTTPS edge Nginx, Certbot, Flutter Web behind a separate
Nginx, Django behind Gunicorn, and PostgreSQL 16 with a persistent volume. It
does not deploy mobile/desktop applications. The frontend is compiled with a
same-origin API URL; local non-container builds
retain `http://127.0.0.1:8000` and may override it with
`--dart-define=BACKEND_URL=https://backend.example.com` (no trailing slash).
`PORTAL_BACKEND_URL`, if explicitly supplied, still overrides the portal API
origin. The Compose build intentionally does not set `PORTAL_EJEMPLOS=false`:
most portal features currently rely on example data.

## Prepare the host

1. Install Docker Engine, the Compose plugin, Git, and `tar`. Ensure the SSH
   deployment account can run Docker without an interactive prompt. Docker
   access grants root-equivalent privileges. The frontend build uses the
   official Linux x64 Flutter SDK; use an amd64 host, or configure working
   amd64 emulation in Docker on an arm64 host.
2. Plan database provisioning. Compose creates a new, empty PostgreSQL
   database on first start; it does not migrate data from an external
   PostgreSQL or Supabase instance. The models in `backend/events/models.py`
   are unmanaged: `migrate` does **not** create their tables, and this
   repository does not contain their SQL schema. Restore a compatible database
   backup or separately provision the existing event schema. Review migrations
   and back up existing data before switching databases.
3. Copy `.env.example` to `~/community-unix/.env` on the host, restrict it to
   the deploy account (`chmod 600`), and fill in real values. Use a long random
   Django secret, database credentials, `DOMAIN`, `CERTBOT_EMAIL`, allowed
   hostname(s), HTTPS origin(s), and a Google OAuth web client ID. Set `DOMAIN`
   to a single public hostname without a scheme, port or wildcard; include it
   in `ALLOWED_HOSTS` and its `https://` origin in `CSRF_TRUSTED_ORIGINS`.
   Use the same client ID as the
   `google-signin-client_id` meta tag in `frontend/web/index.html`; if using a
   different client, update that tag before building. Add the public HTTPS
   origin to the Google client's authorized JavaScript origins.
4. Point `DOMAIN` to the server's public IP with DNS and open inbound ports 80
   and 443. Any published AAAA record must also reach this host on port 80.
   Free both ports from host web servers or other containers before deployment.
   Let's Encrypt's HTTP-01 challenge requires public access on port 80; the
   first certificate is issued after the stack starts. The edge Nginx redirects
   HTTP to HTTPS and overwrites `X-Forwarded-Proto`. Django and the frontend
   are not published directly. Secure cookies require HTTPS.

Certbot retries failed issuance hourly and checks for renewal every 12 hours.
The edge Nginx loads new or renewed certificates within one minute. During
initial issuance, HTTP requests redirect to HTTPS, which is not available until
the certificate has been issued. Keep the `letsencrypt` and `certbot_webroot`
volumes across deployments; `docker compose down -v` deletes them, including
private keys. Check `docker compose ... logs certbot nginx` and monitor renewal
failures and expiry. The workflow waits up to five minutes for HTTPS to start,
and fails with logs if it does not. It checks that the saved certificate is
unexpired, the served certificate matches `DOMAIN`, and HTTPS responds locally; it does not
verify public DNS or certificate trust. Verify the public HTTPS URL from
another machine.

For changes to `DOMAIN`, update DNS, `ALLOWED_HOSTS`, `CSRF_TRUSTED_ORIGINS`,
and Google OAuth origins, then redeploy. Certbot requests a certificate for
the new domain; until it succeeds the previous certificate may still be
served. Avoid repeated unsuccessful requests to respect Let's Encrypt rate
limits.

The database is not published to the host network. Django connects to `db:5432`
over the private Compose network without TLS; protect the Docker host and
network accordingly. `DB_NAME`, `DB_USER`, and `DB_PASSWORD` initialize the
database only when the volume is empty. Changing these values later does not
change existing PostgreSQL users, passwords, or databases; update PostgreSQL
explicitly and coordinate credential changes with the application.

The two `accounts` 0002 migration branches both introduce
`accounts_instructor.procedencia`. They share the column when it is a
non-null `varchar(100)`, and report incompatible or missing columns rather
than silently repairing schema drift. Back up the database before migrations.
If a migration reports schema drift, inspect the migration history and column
definition before deciding how to reconcile it; do not blindly fake migrations.

To start only the database and restore a **trusted plain SQL backup** into a
new database, from a checkout or release on the host:

```sh
docker compose --env-file "$HOME/community-unix/.env" -p community-unix up -d --wait db
docker compose --env-file "$HOME/community-unix/.env" -p community-unix exec -T db \
  sh -c 'exec psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < backup.sql
```

Only restore a backup prepared for the target database; inspect it first and
follow the backup's restoration instructions if it uses another format or
includes database creation commands. Run the normal deployment afterwards to
apply outstanding Django migrations. Do not run `docker compose down -v` on a
database whose data must be retained. The volume survives container replacement,
but is not a backup: arrange independent PostgreSQL backups and test restores.

## GitHub Actions

Create a GitHub **production** environment and configure these secrets:

| Secret | Value |
| --- | --- |
| `SSH_HOST` | Remote hostname or IP |
| `SSH_USER` | Deployment account |
| `SSH_PRIVATE_KEY` | Private key authorized on the host |
| `SSH_KNOWN_HOSTS` | Verified RSA OpenSSH known-hosts entry for the host and port |

Optionally set the environment variable `SSH_PORT` (default `22`). Retrieve a
candidate RSA host-key entry using the exact hostname or IP in `SSH_HOST` and
the configured port:

```sh
ssh-keyscan -p 22 -t rsa YOUR_SSH_HOST > server-known-hosts
ssh-keygen -lf server-known-hosts
```

Replace `22` if using a different port. Compare the fingerprint with the
server's RSA host-key fingerprint obtained through a trusted channel, for
example by running `ssh-keygen -lf /etc/ssh/ssh_host_rsa_key.pub` on the server
via a trusted console. `ssh-keyscan` does not verify the key. Once verified,
copy the complete entry from `server-known-hosts` into `SSH_KNOWN_HOSTS`.
The server must support RSA host-key signatures using SHA-2; the workflow does
not enable legacy SHA-1 signatures. The host key is separate from the client
private key in `SSH_PRIVATE_KEY`, which must be authorized on the host.
Database and Django secrets stay in the host's `.env`, not in the repository
or the SSH command.

On pushes to `main`, or manual workflow dispatch, the workflow transfers the
selected commit into `~/community-unix/releases/<commit>`, builds both images
on the host, runs migrations and `collectstatic`, and starts the services with
health checks. It serializes deployments; configure environment protection if
approval is required. Builds need enough disk, memory and network access for
Flutter and Python dependencies.

For a manual deployment from a checkout on the host:

```sh
docker compose --env-file "$HOME/community-unix/.env" -p community-unix build
docker compose --env-file "$HOME/community-unix/.env" -p community-unix run --rm backend python manage.py migrate --noinput
docker compose --env-file "$HOME/community-unix/.env" -p community-unix run --rm backend python manage.py collectstatic --noinput
docker compose --env-file "$HOME/community-unix/.env" -p community-unix up -d --wait --wait-timeout 120
docker compose --env-file "$HOME/community-unix/.env" -p community-unix logs --tail=100 certbot nginx
```

The manual `up --wait` checks container health but does not wait for certificate
issuance. Wait for Certbot to succeed and then check, from another machine:

```sh
curl --fail --show-error https://example.com/healthz
```

Replace `example.com` with `DOMAIN`. Check `docker compose --env-file "$HOME/community-unix/.env" -p community-unix
ps` and `logs` from the deployed release, then verify HTTPS, Google login,
authenticated API requests, and Django admin static assets. Container health
checks establish process availability, not database or application correctness.
Deployment is not atomic: migrations and static collection occur before the
new containers are started. A failure may require manual recovery; database
rollback requires a compatible backup/migration plan. Releases and old images
are not automatically pruned. Back up the database independently.
