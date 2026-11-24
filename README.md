# Community Unix

Event management application for Comunidad Unix ITC.

## Stack and architecture

- **Frontend:** Flutter/Dart, targeting web as well as mobile and desktop. The
  web build uses Google Sign-In, HTTP and shared preferences.
- **Backend:** Django 5.2 and Django REST Framework, served by Gunicorn. The
  `accounts` app manages users, profiles, roles, Google authentication and JWTs;
  `events` exposes event, activity and catalog APIs.
- **Database:** PostgreSQL 16 runs in Compose with a persistent volume.
  Django's account tables are managed by its migrations; event models use
  existing, unmanaged tables.
- **Web deployment:** an edge Nginx container terminates HTTPS with a
  Let's Encrypt certificate managed by Certbot. A separate Nginx container
  serves Flutter and proxies `/api/`, `/admin/` and `/superadmin/` to Django.
  The application and database containers are reachable only on the Compose
  network.

The portal is partially implemented: many screens still use in-memory example
data, while the event catalog calls the backend. The older
[architecture document](docs/ARCHITECTURE.md) includes planned functionality,
not necessarily features implemented today.

## Deployment

### Remote host prerequisites

The following example assumes a supported **Ubuntu** server and an SSH
deployment account with `sudo` access. For other distributions, follow Docker's
[Engine installation guide](https://docs.docker.com/engine/install/) and
[Compose plugin guide](https://docs.docker.com/compose/install/linux/).
Use an amd64 host, or configure Docker to run amd64 containers on an arm64
host: the Flutter web build uses the Linux x64 SDK.

1. Install Git, tar and the tools needed to configure Docker's official
   package repository:

   ```sh
   sudo apt-get update
   sudo apt-get install -y ca-certificates curl git tar
   sudo install -m 0755 -d /etc/apt/keyrings
   sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
   sudo chmod a+r /etc/apt/keyrings/docker.asc
   ```

2. Add Docker's repository and install Docker Engine and its Compose plugin:

   ```sh
   . /etc/os-release
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME:-$VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   sudo apt-get update
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   sudo systemctl enable --now docker
   ```

   See the [official Ubuntu instructions](https://docs.docker.com/engine/install/ubuntu/)
   for supported releases and resolving conflicts with existing Docker packages.

3. Allow the SSH deployment account to run Docker without an interactive
   password prompt:

   ```sh
   sudo usermod -aG docker "$USER"
   ```

   Disconnect and reconnect over SSH for the group membership to take effect,
   then verify the installation as the deployment account:

   ```sh
   docker version
   docker compose version
   docker compose up --help | grep -- --wait
   git --version
   tar --version
   ```

   `docker version` should show both client and server information. Membership
   in the `docker` group grants root-equivalent privileges; use a trusted
   deployment account.

4. Prepare the existing event schema for PostgreSQL. Compose starts an empty
   PostgreSQL database on first use, but Django migrations do not create the
   unmanaged event tables. Import a compatible schema or database backup
   before using those features; see the deployment guide. Back up any existing
   database before migrating it.

5. From a local checkout, copy the example configuration to the deployment
   account's home directory (replace `deploy@example.com` with the SSH user and
   host):

   ```sh
   ssh deploy@example.com 'mkdir -p ~/community-unix && chmod 700 ~/community-unix'
   scp .env.example deploy@example.com:~/community-unix/.env
   ssh deploy@example.com 'chmod 600 ~/community-unix/.env'
   ```

   Edit `~/community-unix/.env` on the host with the Django secret, database
   credentials, `DOMAIN`, `CERTBOT_EMAIL`, public hostname and HTTPS origin,
   and Google OAuth client ID. Never commit the populated file.

6. Point `DOMAIN` at the host with public DNS. Open SSH and inbound TCP ports
   80 and 443, and ensure no existing host service occupies those ports.
   Certbot obtains and renews the certificate automatically; the edge proxy
   redirects HTTP to HTTPS. Configure the Google OAuth client's authorized
   JavaScript origin to match the public HTTPS origin.

See the [deployment instructions](docs/DEPLOYMENT.md) for proxy configuration,
GitHub Actions secrets, deployment commands, and operational limitations.
