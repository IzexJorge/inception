
ifeq ($(wildcard srcs/.env),)
	$(error srcs/.env doesn't exist. You can copy and fill srcs/.env.example)
endif

include srcs/.env

ifndef LOGIN
	$(error LOGIN is not defined in srcs/.env)
endif
DATA_DIR = /home/$(LOGIN)/data

COMPOSE = srcs/docker-compose.yml
SECRETS_DIR = secrets
SECRET_FILES = $(addprefix $(SECRETS_DIR)/, db_password.txt db_root_password.txt \
				wp_admin_password.txt wp_user_password.txt)
SHELL = /bin/bash

.DELETE_ON_ERROR:

all: up

up: $(SECRET_FILES) | $(DATA_DIR)
	docker compose -f $(COMPOSE) up --detach --build

down:
	docker compose -f $(COMPOSE) down

stop:
	docker compose -f $(COMPOSE) stop

start:
	docker compose -f $(COMPOSE) start

restart:
	docker compose -f $(COMPOSE) restart

ps:
	docker compose -f $(COMPOSE) ps

logs:
	docker compose -f $(COMPOSE) logs --follow

clean:
	docker compose -f $(COMPOSE) down --rmi all --remove-orphans

fclean:
	docker compose -f $(COMPOSE) down --rmi all --remove-orphans --volumes
	sudo rm -rf $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb

re: fclean all

.PHONY: all up down stop start restart ps logs clean fclean re

$(DATA_DIR):
	mkdir -p $@/wordpress
	mkdir -p $@/mariadb

$(SECRETS_DIR):
	mkdir -p $@

$(SECRETS_DIR)/db_password.txt: | $(SECRETS_DIR)
	@openssl rand -hex 20 | tr -d '\n' > $@
	@chmod 644 $@

$(SECRETS_DIR)/db_root_password.txt: | $(SECRETS_DIR)
	@openssl rand -hex 20 | tr -d '\n' > $@
	@chmod 644 $@

$(SECRETS_DIR)/wp_admin_password.txt: | $(SECRETS_DIR)
	@read -rsp "Create a password for WordPress admin: " password; echo; \
	if [ -z "$$password" ]; then \
		echo "Error: the password cannot be empty" >&2; \
		exit 1; \
	fi; \
	printf '%s' "$$password" > $@
	@chmod 644 $@

$(SECRETS_DIR)/wp_user_password.txt: | $(SECRETS_DIR)
	@read -rsp "Create a password for WordPress user: " password; echo; \
	if [ -z "$$password" ]; then \
		echo "Error: the password cannot be empty" >&2; \
		exit 1; \
	fi; \
	printf '%s' "$$password" > $@;
	@chmod 644 $@
