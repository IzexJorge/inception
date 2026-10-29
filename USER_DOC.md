
# User documentation

This document explains how to use the Inception stack as an end user or administrator.
For an overview of the project, see `README.md`.  
For an explanation about how to set up, build, launch and maintain the Inception stack, see `DEV_DOC.md`.

To do most of what is explained in this document, the developer must have first built the project.

## 1. Services provided

The stack runs three services, each one in its own Docker container:

| Service                      | What it does for you                                                                                                                      |
|------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| **NGINX**                    | The web server. It is the only entry point of the stack: it receives HTTPS requests (port 443) and forwards the dynamic ones to WordPress |
| **WordPress** (with PHP-FPM) | The website itself and its administration panel                                                                                           |
| **MariaDB**                  | The database where WordPress stores its content (users, comments, etc)                                                                    |

Website files and database are stored on the host, in `/home/<login>/data/`, so they survive stopping or removing the containers.

## 2. Start and stop the project

Commands must be run from the root of the repository.

To start the project, use `make start`.

```bash
make start
```

To stop the project, use `make stop`.

```bash
make stop
```

Turning off the host machine while the containers are running only stops them, and they will restart when the host machine starts.

## 3. Access the website and the administration panel

1. Open a web browser.
2. Go to <https://login.42.fr/wp-login.php>. Replace "login" to write your domain correctly.
3. The first time, the browser shows a security warning. This is expected: the HTTPS certificate is self-signed. Accept the risk to continue.
4. Log in with your user and password. The next section of this document explains where to locate and manage credentials.
5. To open the administration panel, go to <https://login.42.fr/wp-admin>.

## 4. Locate and manage credentials

The usernames are the values of the variables `WP_ADMIN_USER` and `WP_USER` in the file `srcs/.env`.  
Passwords are stored as separate files in `secrets/`.  
None of these files are included are included in the repository.  
Changing usernames or passwords in these files will only have an effect if the persistent data is deleted and the project is rebuilt.  

To change a WordPress password, use the administration panel (*Users → Profile*). Note that `secrets/` will not be updated.

## 5. Check that the services are running correctly

Run this command. The three containers (`nginx`, `wordpress`, `mariadb`) must appear with the status `Up`. The time must be almost the same.

```bash
make ps
```

If you can access the website as explained in section 3 and the page loads correctly, all services are working, since they are all required for that to happen.

You can easily check it from the shell with this command.

```bash
curl -ksf https://login.42.fr | grep -qE "wp-content|wp-includes" && echo "OK" || echo "FAILED"
```

You can also see just the SSL/TLS certificate line, to confirm the version.

```bash
curl -vkI https://login.42.fr 2>&1 | grep -E "SSL connection"
```
