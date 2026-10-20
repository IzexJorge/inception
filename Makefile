
ifeq ($(wildcard srcs/.env),)
	$(error srcs/.env doesn't exist. You can copy and rename srcs/.env.example and then fill it out)
endif

include srcs/.env

REQUIRED_VARS = LOGIN DOMAIN_NAME MYSQL_DATABASE MYSQL_USER MYSQL_PORT \
				WP_TITLE WP_ADMIN_USER WP_ADMIN_EMAIL WP_USER WP_USER_EMAIL

$(foreach var,$(REQUIRED_VARS),$(if $($(var)),,$(error $(var) is not defined in srcs/.env)))
DATA_DIR := /home/$(LOGIN)/data

WP_ADMIN_USER_LOWER := $(shell echo $(WP_ADMIN_USER) | tr '[:upper:]' '[:lower:]')

ifneq ($(findstring admin,$(WP_ADMIN_USER_LOWER)),)
	$(error WP_ADMIN_USER ("$(WP_ADMIN_USER)") cannot contain "admin" in its name in srcs/.env)
endif

SECRETS_DIR = secrets
SECRET_FILES := $(addprefix $(SECRETS_DIR)/, db_password.txt db_root_password.txt \
				wp_admin_password.txt wp_user_password.txt)
SHELL = /bin/bash

COMPOSE = srcs/docker-compose.yml

.DELETE_ON_ERROR:

all: up

up: $(SECRET_FILES) | $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb
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

reset-data:
	docker compose -f $(COMPOSE) down
	sudo rm -rf $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb

clean:
	docker compose -f $(COMPOSE) down --rmi all --remove-orphans

fclean:
	docker compose -f $(COMPOSE) down --rmi all --remove-orphans --volumes
	sudo rm -rf $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb

re: fclean all

.PHONY: all up down stop start restart ps logs reset-data clean fclean re

$(DATA_DIR)/wordpress:
	sudo mkdir -p $@

$(DATA_DIR)/mariadb:
	sudo mkdir -p $@

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
