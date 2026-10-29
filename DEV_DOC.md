
# Developer documentation

This document explains how to set up, build, launch and maintain the Inception stack.  
For an overview of the project, see `README.md`.  
For an explanation about how to use the Inception stack as an end user or administrator, see `USER_DOC.md`.  

Commands are run from the root of the repository unless stated otherwise. `<login>` is the 42 login set in `LOGIN` in `srcs/.env`.

## 1. Set up the environment from scratch

This project must run in a Linux machine.  
Commands must be run from the root of the repository.

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

The Makefile calls `docker` directly, so you must allow the end user or administrator to use it without `sudo`.  

```bash
sudo usermod -aG docker <username>
```

This won't have an effect until the user logs out and logs in again.

To install Docker Engine and the Compose plugin, follow the official instructions for your distribution: <https://docs.docker.com/engine/install/>.

### 1.2 Clone the repository

If you are reading this from the repository page, first you must clone this repository into your machine. Its URL is typically in the "Code" dropdown in its main page.

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

This table categorizes the different environment variables in functional groups.

| Function                 | What it defines                                                                                                  |
|--------------------------|------------------------------------------------------------------------------------------------------------------|
| Identity                 | `LOGIN` (your 42 login). It determines the host data folder `/home/<login>/data`                                 |
| Database                 | Name of the WordPress database and of the user that WordPress uses to connect to it                              |
| WordPress                | Site title, the administrator (name and email) and the second user (name and email)                              |
| Internal ports           | The port each service listens on inside its container                                                            |

Most of these values are used only the first time the data is initialized. Only the internal ports can be reapplied (with `make`) without deleting the persistent data.

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

## 3. Where the data is stored and how it persists

There is data that must persist for the website to work consistently, after reseting (and even removing) the containers or other cleanups or manipulations.  
This persistent data is stored in `/home/<login>/data/wordpress` and `/home/<login>/data/mariadb`, in the host machine.  
This is why removing images or containers doesn't affect the persistent data. The Docker named volumes control what container can access what persistent data folder.  

By default, Docker stores volumes data in `/var/lib/docker/volumes/`. However, the Docker named volumes in this project use the `driver: local` configuration with `type: none`, `o: bind` and `device: /home/<login>/data/...` options, which allows them to be mapped to a host path.

| Data                      | Docker volume               | Path on the host                 | Path in the containers | Mounted by           |
|---------------------------|-----------------------------|----------------------------------|------------------------|----------------------|
| WordPress files           | `inception_wordpress_data`  | `/home/<login>/data/wordpress`   | `/var/www/html`        | `wordpress`, `nginx` |
| Database                  | `inception_mariadb_data`    | `/home/<login>/data/mariadb`     | `/var/lib/mysql`       | `mariadb`            |

## 4. Managing containers and volumes

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
| `make stop`        | Stops the containers without removing them                                                                                          |
| `make start`       | Starts containers that were stopped                                                                                                 |
| `make restart`     | Stops and starts the containers                                                                                                     |
| `make ps`          | Shows the state of the containers                                                                                                   |
| `make volumes`     | Lists the volumes                                                                                                                   |
| `make logs`        | Follows the logs of all the services (press Ctrl+C to stop following)                                                               |
| `make down`        | Removes the containers and the network. Images, volumes and the persistent data are kept                                            |
| `make clean`       | Removes the containers, the network and the images. Volumes and the persistent data are kept                                        |
| `make reset-data`  | Removes the containers, the network and the persistent data. Images and volumes are kept                                            |
| `make fclean`      | Removes the containers, the network, the images, the volumes and the persistent data                                                |
| `make re`          | `make fclean` followed by `make up`                                                                                                 |

None of the targets deletes `secrets/` or `srcs/.env`.  
Turning off the host machine while the containers are running only stops them, and they will restart when the host machine starts.  

### 4.1 Database

You can log in to the database as the MariaDB administrator from inside its container. The password is in `secrets/db_root_password.txt`.

```bash
docker compose -f srcs/docker-compose.yml exec mariadb mariadb -u root -p
```

These are some basic things you can do there:

- See the databases and use one for following commands.
	```sql
	SHOW DATABASES;
	USE <database name>;
	```
- See the data tables and retrieve some columns from a table. We use the wordpress database in this example.

	```sql
	USE wordpress
	SHOW TABLES;
	SELECT user_login, user_email FROM wp_users;
	```
- Exit.
	```sql
	exit;
	```

### 4.2 WordPress (WP-CLI)

WP-CLI is installed in the `wordpress` container. This example executes the WP-CLI `wp user list` command.

```bash
docker compose -f srcs/docker-compose.yml exec wordpress wp user list --path=/var/www/html --allow-root
```
