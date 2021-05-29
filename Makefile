#----------------------
# Parse makefile arguments
#----------------------
RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(RUN_ARGS):;@:)

#----------------------
# Silence GNU Make
#----------------------
ifndef VERBOSE
MAKEFLAGS += --no-print-directory
endif

#----------------------
# Load .env file
#----------------------
ifneq ("$(wildcard .env)","")
include .env
export
else  
endif

#----------------------
# docker-sync context
#----------------------
DOCKER_COMPOSE_CONTEXT=
ifeq ("$(DOCKER_FS_SYNC_MODE)", "sync")
	DOCKER_COMPOSE_CONTEXT = -f docker-compose.yml -f docker-compose-dev.yml
endif

#----------------------
# Terminal
#----------------------

GREEN  := $(shell tput -Txterm setaf 2)
WHITE  := $(shell tput -Txterm setaf 7)
YELLOW := $(shell tput -Txterm setaf 3)
RESET  := $(shell tput -Txterm sgr0)

#------------------------------------------------------------------
# - Add the following 'help' target to your Makefile
# - Add help text after each target name starting with '\#\#'
# - A category can be added with @category
#------------------------------------------------------------------

HELP_FUN = \
	%help; \
	while(<>) { \
		push @{$$help{$$2 // 'options'}}, [$$1, $$3] if /^([a-zA-Z\-]+)\s*:.*\#\#(?:@([a-zA-Z\-]+))?\s(.*)$$/ }; \
		print "-----------------------------------------\n"; \
		print "| Welcome to EQEmu Docker!\n"; \
		print "-----------------------------------------\n"; \
		print "| usage: make [command]\n"; \
		print "-----------------------------------------\n\n"; \
		for (sort keys %help) { \
			print "${WHITE}$$_:${RESET \
		}\n"; \
		for (@{$$help{$$_}}) { \
			$$sep = " " x (32 - length $$_->[0]); \
			print "  ${YELLOW}$$_->[0]${RESET}$$sep${GREEN}$$_->[1]${RESET}\n"; \
		}; \
		print "\n"; \
	}

help: ##@other Show this help.
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST)

IN_PORT_RANGE_HIGH=${PORT_RANGE_HIGH}
ifneq ($(port-range-high),)
	 IN_PORT_RANGE_HIGH=$(port-range-high)
endif

IN_IP_ADDRESS=${IP_ADDRESS}
ifneq ($(ip-address),)
	 IN_IP_ADDRESS=$(ip-address)
endif


#----------------------
# env
#----------------------

set-vars: ##@env Sets var port-range-high=[] ip-address=[]
	@assets/scripts/env-set-var.pl IP_ADDRESS $(IN_IP_ADDRESS)
	@assets/scripts/env-set-var.pl PORT_RANGE_HIGH $(IN_PORT_RANGE_HIGH)

#----------------------
# Init / Install
#----------------------

install: ##@init Install full application port-range-high=[] ip-address=[]
	docker-compose pull
	@assets/scripts/env-set-var.pl IP_ADDRESS $(IN_IP_ADDRESS)
	@assets/scripts/env-set-var.pl PORT_RANGE_HIGH $(IN_PORT_RANGE_HIGH)
	docker-compose build mariadb
	make up detached
	@assets/scripts/env-set-var.pl
	docker-compose exec mariadb bash -c 'while ! mysqladmin status -uroot -p${MARIADB_ROOT_PASSWORD} -h "localhost" --silent; do sleep .5; done;'
	make init-strip-mysql-remote-root
	docker-compose exec eqemu-server bash -c "make install"
	docker-compose exec -T eqemu-server bash -c "make update-admin-panel"
	docker-compose down
	docker-compose up -d

init-strip-mysql-remote-root: ##@init Strips MySQL remote root user
	docker-compose exec mariadb bash -c "mysql -uroot -p${MARIADB_ROOT_PASSWORD} -h localhost -e \"delete from mysql.user where User = 'root' and Host = '%'; FLUSH PRIVILEGES\""

init-reset-env: ##@init Resets .env
	make env-transplant
	make env-scramble-secrets

init-peq-editor: ##@init Initializes PEQ editor
	docker-compose build peq-editor && docker-compose up -d peq-editor
	docker-compose exec peq-editor bash -c "git clone https://github.com/ProjectEQ/peqphpeditor.git /var/www/html && \
    	cd /var/www/html/ && cp config.php.dist config.php && \
    	chown www-data:www-data /var/www/html -R"
	docker-compose exec eqemu-server bash -c "make init-peq-editor"

#----------------------
# Image Management
#----------------------

image-build-all: ##@image-build Build all images
	make image-eqemu-server-build
	make image-peq-editor-build
	make image-backup-cron-build

image-push-all: ##@image-build Push all images
	make image-eqemu-server-push
	make image-peq-editor-push
	make image-backup-cron-push

image-build-push-all: ##@image-build Build and push all images
	make image-build-all
	make image-push-all

# eqemu-server

image-eqemu-server-build: ##@image-build Builds image
	docker build containers/eqemu-server -t akkadius/eqemu-server:latest

image-eqemu-server-push: ##@image-build Publishes image
	docker push akkadius/eqemu-server:latest

# peq-editor

image-peq-editor-build: ##@image-build Builds image
	docker build containers/peq-editor -t akkadius/peq-editor:latest

image-peq-editor-push: ##@image-build Publishes image
	docker push akkadius/peq-editor:latest

# backup-cron

image-backup-cron-build: ##@image-build Builds image
	docker build containers/backup-cron -t akkadius/eqemu-backup-cron:latest

image-backup-cron-push: ##@image-build Publishes image
	docker push akkadius/eqemu-backup-cron:latest

#----------------------
# Workflow
#----------------------

bash: ##@workflow Bash into eqemu-server
	docker-compose exec eqemu-server bash

mc: ##@workflow Jump into the MySQL container console
	docker-compose exec mariadb bash -c "mysql -uroot -p${MARIADB_ROOT_PASSWORD} -h localhost ${MARIADB_DATABASE}"

MYSQL_BACKUP_NAME=${MARIADB_DATABASE}-$(shell date +"%m-%d-%Y")

mysql-backup: ##@workflow Jump into the MySQL container console
	docker-compose exec -T mariadb bash -c "mysqldump --lock-tables=false -uroot -p${MARIADB_ROOT_PASSWORD} -h localhost ${MARIADB_DATABASE} > /var/lib/mysql/$(MYSQL_BACKUP_NAME).sql"
	mkdir -p backup/database/
	mv ./data/mariadb/$(MYSQL_BACKUP_NAME).sql .
	tar -zcvf backup/database/$(MYSQL_BACKUP_NAME).tar.gz $(MYSQL_BACKUP_NAME).sql
	rm $(MYSQL_BACKUP_NAME).sql

mysql-list-users: ##@workflow Lists MySQL users
	docker-compose exec mariadb bash -c "mysql -uroot -p${MARIADB_ROOT_PASSWORD} -h localhost -e 'select user, password, host from mysql.user;'"

watch-processes: ##@workflow Watch processes
	docker-compose exec eqemu-server bash -c "watch -n 1 'ps auxf'"

#----------------------
# Docker
#----------------------

up: ##@docker Bring up eqemu-server and database
	docker-compose up -d eqemu-server mariadb

up-all: ##@docker Bring up the whole environment
ifeq ("$(DOCKER_FS_SYNC_MODE)", "sync")
	docker-sync start
endif
	docker-compose $(DOCKER_COMPOSE_CONTEXT) up -d
ifeq (,$(findstring detached,$(RUN_ARGS)))
	docker-compose logs --tail 100 -f
endif

down: ##@docker Down all containers
	docker-compose down
ifeq ("$(DOCKER_FS_SYNC_MODE)", "sync")
	docker-sync stop
endif

restart: ##@docker Restart containers
	make down
	make up detached

#----------------------
# env
#----------------------

env-transplant: ##@env Merges values from .env.example into .env (.env is delegate)
	@assets/scripts/env-transplant.pl

env-scramble-secrets: ##@env Scrambles secrets
	@assets/scripts/env-scramble-secrets.pl $(RUN_ARGS)

env-set-zone-port-range-high: ##@env Set zone port range high value
	docker-compose $(DOCKER_COMPOSE_CONTEXT) up -d eqemu-server
	@assets/scripts/env-set-var.pl PORT_RANGE_HIGH $(RUN_ARGS)
	docker-compose exec eqemu-server bash -c "cat ~/server/eqemu_config.json | jq '.server.zones.ports.high = "${PORT_RANGE_HIGH}"' | tee ~/server/eqemu_config.json"
	docker-compose $(DOCKER_COMPOSE_CONTEXT) up -d --force-recreate eqemu-server

#----------------------
# Install
#----------------------

info: ##@info Print install info
	@echo "##################################"
	@echo "# Server Info"
	@echo "##################################"
	@echo '# $(shell docker-compose exec eqemu-server bash -c "cat ~/server/eqemu_config.json | jq '.server.world.longname' | tr -d '\"'")'
	@echo "##################################"
	@echo "# Passwords"
	@echo "##################################"
	@cat .env | grep PASSWORD
	@echo "##################################"
	@echo "# IP"
	@echo "##################################"
	@cat .env | grep IP
	@echo "##################################"
	@echo "# Quests FTP  | ${IP_ADDRESS}:21 | quests / ${FTP_QUESTS_PASSWORD}"
	@echo "##################################"
	@echo "# Web Interfaces"
	@echo "##################################"
	@echo "# PEQ Editor  | http://${IP_ADDRESS}:8081 | admin / ${PEQ_EDITOR_PASSWORD}"
	@echo "# PhpMyAdmin  | http://${IP_ADDRESS}:8082 | admin / ${PHPMYADMIN_PASSWORD}"
	@echo "# EQEmu Admin | http://${IP_ADDRESS}:3000 | admin / $(shell docker-compose exec eqemu-server bash -c "cat ~/server/eqemu_config.json | jq '.[\"web-admin\"].application.admin.password' | tr -d '\"'")"
	@echo "##################################"

#----------------------
# dev
#----------------------

fw: ##@dev Runs web-admin frontend dev server (alias)
	docker-compose exec eqemu-server bash -c "cd ~/server/eqemu-web-admin/frontend && npm run serve"

bw: ##@dev Runs web-admin backend dev server (alias)
	docker-compose exec eqemu-server bash -c "cd ~/server/eqemu-web-admin && npm run watch"

