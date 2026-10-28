
# Developer documentation

This document explains how to set up, build, launch and maintain the Inception stack.  
For an overview of the project, see `README.md`.  
For the day-to-day use of the website, see `USER_DOC.md`.  

Commands are run from the root of the repository unless stated otherwise. `<login>` is the 42 login set in `LOGIN` in `srcs/.env`.

## 1. Set up the environment from scratch

This project must run in a Linux machine.

### 1.1 Prerequisites

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

### 1.2 Clone the repository

If you are reading this in the repository page, first you must clone this repository into your machine. Its URL is typically in the "Code" button in its main page.

```bash
git clone <repository-url> inception && cd inception
```

### 1.3 Register the domain locally

`<login>.42.fr` is not a registered domain, so it has to be resolved locally. Register it in the /etc/hosts file as the localhost (127.0.0.1).

```bash
echo "127.0.0.1  <login>.42.fr" | sudo tee -a /etc/hosts
```

### 1.4 Configuration file

First, copy and rename `srcs/.env.example`, which contains the environment variables used for the user configuration, with generic placeholder values.

```bash
cp srcs/.env.example srcs/.env
```

Edit `srcs/.env`, changing only the variable values, with your user data and preferences, respecting the following rules:
- Don't change the variable names.
- One variable per line.
- Don't add spaces nor quotes, since they would become part of the value.
- The administrator's name must not contain `admin` in any capitalisation.

This table categorizes the different environment variables in functional groups:

| Function                 | What it defines                                                                                                  |
|--------------------------|------------------------------------------------------------------------------------------------------------------|
| Identity                 | `LOGIN` (your 42 login). It determines the data folder `/home/<login>/data`.                                     |
| Database                 | Name of the WordPress database and of the user that WordPress uses to connect to it                              |
| WordPress                | Site title, the administrator (name and email) and the second user (name and email)                              |
| Internal ports           | The port each service listens on inside its container (for example `NGINX_PORT`)                                 |

### 1.5 Secrets

The `secrets/` folder is not included in the repository, since it must store sensitive information, which is described in this table.  

| File                              | Used by                  | Content                                     | Created by `make`                            |
|-----------------------------------|--------------------------|---------------------------------------------|----------------------------------------------|
| `secrets/db_password.txt`         | `mariadb`, `wordpress`   | Password of the WordPress database user     | Generated randomly (`openssl rand -hex 20`)  |
| `secrets/db_root_password.txt`    | `mariadb`                | Password of the MariaDB `root` account      | Generated randomly (`openssl rand -hex 20`)  |
| `secrets/wp_admin_password.txt`   | `wordpress`              | Password of the WordPress administrator     | Typed by you (hidden prompt)                 |
| `secrets/wp_user_password.txt`    | `wordpress`              | Password of the second WordPress user       | Typed by you (hidden prompt)                 |

You don't need to create this folder or files, since later when you build the project with `make` it will create them if they are missing, allowing you to input the content.  

Passwords are applied only the first time the data is initialized. Editing a secret afterwards does not change the password stored in the database.

## 2. Build and launch

To build and launch the project you need to execute `make`.  

```bash
make
```

It does the following, in order:

1. Checks that `srcs/.env` exists, that the required variables are set and that the administrator's name does not contain `admin`.
2. Creates `secrets/` and its missing files if they are missing, allowing you to input the content (see section 1.5).
3. Creates `/home/<login>/data/wordpress` and `/home/<login>/data/mariadb` if they are missing (with `sudo`).
4. Runs `docker compose -f srcs/docker-compose.yml up --detach --build`, which builds the three images, creates the network and the volumes, and starts the containers in the background.

## 3. Managing containers and volumes

`make` also has many other targets that allow you to manage the containers and the volumes.  
Executing `make up` does the same thing as `make`, since `up` is the default target.

```bash
make up
```

This table describes the `make` targets, which allow to manage containers and volumes.  
The services are `nginx`, `wordpress` and `mariadb`, and the containers and images carry the same names.  

| Command            | Effect                                                                                                                              |
|--------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| `make` / `make up` | Builds and starts the whole stack (see section 2)                                                                                   |
| `make down`        | Removes the containers and the network. Images, volumes and data are kept                                                           |
| `make stop`        | Stops the containers without removing them                                                                                          |
| `make start`       | Starts containers that were stopped                                                                                                 |
| `make restart`     | Restarts the containers, just like doing stop and then start                                                                        |
| `make ps`          | Shows the state of the containers                                                                                                   |
| `make volumes`     | Lists the volumes                                                                                                                   |
| `make logs`        | Follows the logs of all the services (press Ctrl+C to stop following)                                                               |
| `make clean`       | Like `down`, and also removes the images built for the project. Volumes and data are kept                                           |
| `make reset-data`  | Like `down`, and then deletes the contents of the WordPress and MariaDB data folders (with `sudo`). Images and secrets are kept     |
| `make fclean`      | Like `clean`, and also removes the volumes and deletes the data folders (with `sudo`)                                               |
| `make re`          | `make fclean` followed by `make`                                                                                                    |

**`make fclean`, `make reset-data` and `make re` permanently delete the WordPress site and the database.** None of the targets deletes `secrets/` or `srcs/.env`.

### 3.1 Database



-------------

### 3.1 Containers




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
