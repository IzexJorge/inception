
# Developer documentation

This document explains how to set up, build, launch and maintain the Inception stack.  
For an overview of the project, see `README.md`.  
For the day-to-day use of the website, see `USER_DOC.md`.  

Commands are run from the root of the repository unless stated otherwise. `<login>` is the 42 login set in `LOGIN` in `srcs/.env`.

## Set up the environment from scratch

This project must run inside a Linux virtual machine.

### Prerequisites

The following programs and permissions are required for this project.

| Requirement                              | Why                                                                                 | Check                                |
|------------------------------------------|-------------------------------------------------------------------------------------|--------------------------------------|
| Git                                      | To clone the repository                                                             | `git --version`                      |
| Docker Engine, with its daemon running   | Builds the images and runs the containers                                           | `docker --version` and `docker info` |
| Docker Compose v2 plugin                 | Orchestrates the stack (`docker compose`, not the old `docker-compose`)             | `docker compose version`             |
| `make`                                   | Entry point of the project                                                          | `make --version`                     |
| `openssl`                                | Generates the random database passwords                                             | `openssl version`                    |
| `sudo` rights                            | Creates and deletes the data folders in `/home/<login>/data`, owned by containers   | `sudo -v`                            |
| A web browser                            | To access and use the website                                                       | Launch the browser                   |

The Makefile calls `docker` directly, so your user must be allowed to use it without `sudo`:

```bash
sudo usermod -aG docker $USER    # then log out and log in again
```

Members of the `docker` group have, in practice, root privileges on the machine.  
To install Docker Engine and the Compose plugin, follow the official instructions for your distribution: <https://docs.docker.com/engine/install/>.

### Clone the repository

If you are reading this in the repository page, first you must clone this repository into your machine. Its URL is typically in the "Code" button in its main page.

```bash
git clone <repository-url> inception && cd inception
```

### Register the domain locally

`<login>.42.fr` is not a registered domain, so it has to be resolved locally. Register it in the /etc/hosts file as the localhost (127.0.0.1).

```bash
echo "127.0.0.1  <login>.42.fr" | sudo tee -a /etc/hosts
```

### Configuration files

### Secrets

---------------

### 1.3 Repository files that are not versioned

Two items are required by the stack but are ignored by Git on purpose, because they are specific to each machine or secret:

- `srcs/.env`: local configuration. `srcs/.env.example` is the versioned template and contains no secret.
- `secrets/`: the password files.

On a fresh clone neither exists, so the next two sections create them.

### 1.4 Configuration file: `srcs/.env`

```bash
cp srcs/.env.example srcs/.env
```

Edit the copy. `srcs/.env.example` lists every variable with a placeholder value. They are grouped as follows:

| Group                    | What it defines                                                                                                  |
|--------------------------|------------------------------------------------------------------------------------------------------------------|
| Identity                 | `LOGIN` (your 42 login; it determines the data folder `/home/<login>/data`) and `DOMAIN_NAME` (`<login>.42.fr`)   |
| Database                 | Name of the WordPress database and of the user that WordPress uses to connect to it                              |
| WordPress                | Site title, the administrator (name and email) and the second user (name and email)                              |
| Internal ports           | The port each service listens on inside its container (for example `NGINX_PORT`)                                 |

Rules:

- Write one `NAME=value` per line, **without quotes**: the value is read both by Docker Compose and by the Makefile, and the quotes would become part of the value.
- The administrator's name must not contain `admin` in any capitalisation (a rule of the subject). The Makefile refuses to run otherwise.
- The port published on the host is always 443 and is fixed in `srcs/docker-compose.yml`; only the port that NGINX uses inside its container is configurable.
- The Makefile reads this file on every invocation, including `make down`, and stops with an error if the file is missing or a required variable is empty.

### 1.6 Secrets

Passwords are Docker secrets, stored as files in `secrets/`:

| File                              | Used by                  | Content                                     | Created by `make`                            |
|-----------------------------------|--------------------------|---------------------------------------------|----------------------------------------------|
| `secrets/db_password.txt`         | `mariadb`, `wordpress`   | Password of the WordPress database user     | Generated randomly (`openssl rand -hex 20`)  |
| `secrets/db_root_password.txt`    | `mariadb`                | Password of the MariaDB `root` account      | Generated randomly (`openssl rand -hex 20`)  |
| `secrets/wp_admin_password.txt`   | `wordpress`              | Password of the WordPress administrator     | Typed by you (hidden prompt)                 |
| `secrets/wp_user_password.txt`    | `wordpress`              | Password of the second WordPress user       | Typed by you (hidden prompt)                 |

The two database passwords are only used by the containers, so they are random. The two WordPress passwords are used by people to log in, so they are chosen by you. An empty password is rejected.

`make` creates only the files that are missing and never overwrites existing ones. The files are created with mode 644, so any local user of the machine can read them. To create one by hand, write the password **without a trailing newline**:

```bash
mkdir -p secrets
printf '%s' 'the-password' > secrets/wp_admin_password.txt
```

At runtime Docker mounts each secret read-only at `/run/secrets/<name>` inside the containers that declare it, and the entry-point scripts read it from there. Never commit these files.

Passwords are applied **only the first time** the data is initialised (see section 4.4). Editing a secret afterwards does not change the password stored in the database. After changing one, reset the data with `make reset-data`.

## 2. Build and launch

### 2.1 With the Makefile

```bash
make
```

`make` (or `make up`) does the following, in order:

1. Checks that `srcs/.env` exists, that the required variables are set and that the administrator's name does not contain `admin`.
2. Creates the missing secrets in `secrets/` (section 1.6).
3. Creates `/home/<login>/data/wordpress` and `/home/<login>/data/mariadb` if they do not exist (with `sudo`).
4. Runs `docker compose -f srcs/docker-compose.yml up --detach --build`, which builds the three images, creates the network and the volumes, and starts the containers in the background.

Running `make` again is safe: Docker reuses cached image layers, and only recreates the containers whose image or configuration changed.

Available targets:

| Command           | Effect                                                                                                                                       |
|-------------------|----------------------------------------------------------------------------------------------------------------------------------------------|
| `make` / `make up` | Builds and starts the whole stack (steps above)                                                                                              |
| `make stop`       | Stops the containers without removing them                                                                                                   |
| `make start`      | Starts containers that were stopped                                                                                                          |
| `make restart`    | Restarts the containers. It does not rebuild images or apply configuration changes (use `make up` for that)                                  |
| `make down`       | Removes the containers and the network. Images, volumes and data are kept                                                                    |
| `make ps`         | Shows the state of the containers                                                                                                            |
| `make logs`       | Follows the logs of all the services (press Ctrl+C to stop following)                                                                        |
| `make clean`      | Like `down`, and also removes the images built for the project. Volumes and data are kept                                                    |
| `make reset-data` | Like `down`, and then deletes the contents of the WordPress and MariaDB data folders (with `sudo`). Images and secrets are kept              |
| `make fclean`     | Like `clean`, and also removes the volumes and deletes the data folders (with `sudo`)                                                        |
| `make re`         | `make fclean` followed by `make`                                                                                                             |

**`make fclean`, `make reset-data` and `make re` permanently delete the WordPress site and the database.** None of the targets deletes `secrets/` or `srcs/.env`.

### 2.2 Start-up sequence

Compose creates `mariadb`, then `wordpress`, then `nginx`. `depends_on` only orders the creation of the containers, so each entry-point script waits for what it needs, with a limit:

| Container   | Waits for                              | Limit        | If exceeded                                   |
|-------------|----------------------------------------|--------------|-----------------------------------------------|
| `mariadb`   | Its own temporary instance (first run) | about 30 s   | Exits with an error                           |
| `wordpress` | MariaDB to accept connections          | about 90 s   | Exits with an error                           |
| `nginx`     | php-fpm in the `wordpress` container   | about 150 s  | Exits with an error                           |

A container that exits is restarted by Docker (`restart: unless-stopped`). The first start takes longer than the following ones because of the database bootstrap and the WordPress installation. You can follow it with `make logs`.

### 2.3 With Docker Compose directly

The Makefile is a thin wrapper. The equivalent direct commands are:

```bash
docker compose -f srcs/docker-compose.yml up --detach --build   # build and start
docker compose -f srcs/docker-compose.yml down                  # remove containers and network
docker compose -f srcs/docker-compose.yml config                # validate the file and show it with variables resolved
docker compose -f srcs/docker-compose.yml build --no-cache      # rebuild the images ignoring the cache
```

Calling Compose directly skips the Makefile's checks. The secret files and the data folders must already exist, otherwise Compose fails; run `make` at least once to create them.

## 3. Managing containers and volumes

The services are `nginx`, `wordpress` and `mariadb`, and the containers and images carry the same names. In the commands below `<service>` is one of them.

### 3.1 Containers

| Goal                                  | Command                                                                              |
|---------------------------------------|--------------------------------------------------------------------------------------|
| State of the containers               | `make ps` or `docker compose -f srcs/docker-compose.yml ps`                          |
| Logs of one service                   | `docker compose -f srcs/docker-compose.yml logs --follow <service>`                  |
| Open a shell inside a container       | `docker compose -f srcs/docker-compose.yml exec <service> bash`                      |
| Restart a single service              | `docker compose -f srcs/docker-compose.yml restart <service>`                        |
| Rebuild and recreate a single service | `docker compose -f srcs/docker-compose.yml up --detach --build <service>`            |
| List the images                       | `docker images`                                                                      |

NGINX and php-fpm write their logs to the standard output and error, so `logs` shows them together with those of the entry-point scripts.

### 3.2 Network

```bash
docker network ls                          # the project network is inception_inception
docker network inspect inception_inception # shows the three containers and their addresses
```

### 3.3 Volumes

```bash
docker volume ls                              # inception_wordpress_data and inception_mariadb_data
docker volume inspect inception_wordpress_data
docker volume inspect inception_mariadb_data
```

In the output of `inspect`, the `Options` section shows `"device": "/home/<login>/data/..."`, which is where the data lives on the host (see section 4).

### 3.4 Database

Log in as the MariaDB administrator from inside its container. The password is in `secrets/db_root_password.txt`:

```bash
docker compose -f srcs/docker-compose.yml exec mariadb mariadb -u root -p
```

Then, for example:

```sql
SHOW DATABASES;
USE <database name>;
SHOW TABLES;                                  -- the wp_* tables created by WordPress
SELECT user_login, user_email FROM wp_users;  -- the two WordPress users
```

Exit with `exit;`.

### 3.5 WordPress (WP-CLI)

WP-CLI is installed in the `wordpress` container:

```bash
docker compose -f srcs/docker-compose.yml exec wordpress wp user list --path=/var/www/html --allow-root
```

### 3.6 Checking from the command line

```bash
curl -vk https://<login>.42.fr          # TLS handshake and HTML of the site (-k accepts the self-signed certificate)
curl -v http://<login>.42.fr            # must fail: port 80 is not published
```

## 4. Where the data is stored and how it persists

### 4.1 Location

| Data                      | Docker volume               | Path on the host                 | Path in the containers | Mounted by           |
|---------------------------|-----------------------------|----------------------------------|------------------------|----------------------|
| WordPress files           | `inception_wordpress_data`  | `/home/<login>/data/wordpress`   | `/var/www/html`        | `wordpress`, `nginx` |
| Database                  | `inception_mariadb_data`    | `/home/<login>/data/mariadb`     | `/var/lib/mysql`       | `mariadb`            |

The volumes are Docker named volumes that use the `local` driver with the options `type: none`, `o: bind` and `device: /home/<login>/data/...`. They are managed by Docker like any other volume, but their content sits at the host path required by the subject. The data folders must exist before the containers start, which is why the Makefile creates them.

Other data is stored elsewhere:

- `srcs/.env` and `secrets/` stay in the working tree of the repository (ignored by Git).
- The TLS certificate and its private key are generated by the `nginx` container and live in its own filesystem, not in a volume. They are kept when the container is restarted and regenerated if it is recreated.
- `wp-config.php`, inside the WordPress volume, contains the database password in clear text (WordPress requires it). Treat that folder as sensitive.

The files are created by processes inside the containers, so on the host they belong to the container users (`mysql`, `www-data`, `root`). Deleting them by hand requires `sudo`.

### 4.2 What survives each operation

| Operation                                                                          | Site and database                                                                                                                                  |
|------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| `make stop` / `make start` / `make restart`                                        | Kept                                                                                                                                               |
| `make down`, then `make`                                                           | Kept                                                                                                                                               |
| `make clean`                                                                       | Kept (only containers, network and images are removed)                                                                                             |
| Editing a Dockerfile or a configuration file and running `make`                    | Kept                                                                                                                                               |
| Rebooting the virtual machine                                                      | Kept. Docker restarts the containers when its daemon starts, unless they had been stopped with `make stop`; in that case run `make`                |
| Removing every Docker object by hand (`docker rm`, `docker rmi`, `docker volume rm`, `docker network rm`) | Kept: the files remain in `/home/<login>/data`. The next `make` recreates the volumes on top of them and skips the first-start initialisation |
| `make reset-data`, `make fclean`, `make re`, or deleting `/home/<login>/data`      | **Erased**                                                                                                                                         |

### 4.3 Backup

With the stack stopped (`make stop`), the two folders can be copied as they are:

```bash
sudo tar czf inception-data.tar.gz -C /home/<login>/data .
```

### 4.4 First-start initialisation

The entry-point scripts decide what to do by looking at a marker file inside each volume, `.initialized`:

- **`mariadb`** (`/var/lib/mysql/.initialized`). If it is absent, the script creates the system tables if they are missing, starts a temporary instance without network, creates the WordPress database and its user, sets the root password, stops the instance and writes the marker. In every start it then launches `mariadbd` as the main process of the container.
- **`wordpress`** (`/var/www/html/.initialized`). If it is absent, the script copies the WordPress files from the image into the volume, generates `wp-config.php`, installs the site, creates the second user, fixes the ownership of the files and writes the marker. In every start it then launches php-fpm as the main process of the container.

To replay the first start (for example after changing a password or the content of the `.env` variables that WordPress and the database store at installation), run:

```bash
make reset-data
make
```

## 5. Changing the configuration

| What                                             | Where                                                             | How to apply it                                                                                         |
|--------------------------------------------------|-------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| Internal port of a service                       | `srcs/.env`                                                       | `make` (the images are rebuilt where needed and the containers are recreated)                            |
| NGINX server block (TLS versions, redirects...)  | `srcs/requirements/nginx/conf/wordpress.conf.template`            | `make`                                                                                                  |
| php-fpm pool                                     | `srcs/requirements/wordpress/conf/www.conf`                       | `make`                                                                                                  |
| MariaDB server options                           | `srcs/requirements/mariadb/conf/my.cnf`                           | `make`                                                                                                  |
| Start-up logic of a service                      | `srcs/requirements/<service>/tools/*.sh`                          | `make`; add `make reset-data` first if the change affects the first-start initialisation                |
| Image contents                                   | `srcs/requirements/<service>/Dockerfile`                          | `make`; use `build --no-cache` (section 2.3) to ignore the cache                                         |
| Domain, site title, users                        | `srcs/.env`                                                       | These values are stored in the database at installation: `make reset-data`, then `make`                 |
| Host port                                        | `ports` of the `nginx` service in `srcs/docker-compose.yml`       | `make`. Fixed at 443 by the subject                                                                     |

## 6. Troubleshooting

| Symptom                                                          | Likely cause and solution                                                                                                                                          |
|------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `make` stops with an error about `srcs/.env` or a variable       | The file is missing, a variable is empty, or the administrator's name contains `admin`. Fix `srcs/.env` (section 1.4)                                               |
| A container shows `Restarting` in `make ps`                      | Read its logs with `docker compose -f srcs/docker-compose.yml logs <service>`. A typical cause is a script with stray whitespace or Windows line endings before the `#!/bin/bash` line |
| WordPress cannot connect to the database after changing a secret | The database keeps the passwords from its first initialisation. Run `make reset-data`, then `make`                                                                  |
| The browser cannot find `<login>.42.fr`                          | The entry in `/etc/hosts` is missing or the browser is not running inside the virtual machine (section 1.5)                                                         |
| The browser warns about the certificate                          | Expected: the certificate is self-signed. Accept it
