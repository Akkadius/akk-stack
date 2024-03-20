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
ifeq ("$(ENV)", "development")
	DOCKER_COMPOSE_CONTEXT = -f docker-compose.yml -f docker-compose.dev.yml
endif

DOCKER=docker-compose $(DOCKER_COMPOSE_CONTEXT)

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
# services
#----------------------

RUN_SERVICES=
ifeq ($(ENABLE_FTP_QUESTS),true)
	RUN_SERVICES+= ftp-quests
endif

ifeq ($(ENABLE_PHPMYADMIN),true)
	RUN_SERVICES+= phpmyadmin
endif

ifeq ($(ENABLE_PEQ_EDITOR),true)
	RUN_SERVICES+= peq-editor
endif

ifeq ($(ENABLE_BACKUP_CRON),true)
	RUN_SERVICES+= backup-cron
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
	$(DOCKER) pull
	@assets/scripts/env-set-var.pl IP_ADDRESS $(IN_IP_ADDRESS)
	@assets/scripts/env-set-var.pl PORT_RANGE_HIGH $(IN_PORT_RANGE_HIGH)
	$(DOCKER) build mariadb
	make up detached
	@assets/scripts/env-set-var.pl
	$(DOCKER) exec mariadb bash -c 'while ! mysqladmin status -uroot -p${MARIADB_ROOT_PASSWORD} -h "localhost" --silent; do sleep .5; done; sleep 5'
	make init-strip-mysql-remote-root
	$(DOCKER) exec eqemu-server bash -c "make install"
	make init-peq-editor
	make down
	make up
	make up-info

init-strip-mysql-remote-root: ##@init Strips MySQL remote root user
	$(DOCKER) exec mariadb bash -c "mysql -uroot -p${MARIADB_ROOT_PASSWORD} -h localhost -e \"delete from mysql.user where User = 'root' and Host = '%'; FLUSH PRIVILEGES\""

init-reset-env: ##@init Resets .env
	make env-transplant
	make env-scramble-secrets

init-peq-editor: ##@init Initializes PEQ editor
	$(DOCKER) build peq-editor && $(DOCKER) up -d peq-editor
	$(DOCKER) exec peq-editor bash -c "git config --global --add safe.directory '*'; chown www-data:www-data -R /var/www/html && git -C /var/www/html pull 2> /dev/null || git clone https://github.com/ProjectEQ/peqphpeditor.git /var/www/html && cd /var/www/html/ && cp config.php.dist config.php"
	$(DOCKER) exec eqemu-server bash -c "make init-peq-editor"

#----------------------
# Image Management
#----------------------

image-build-all: ##@image-build Build all images
	make image-eqemu-server-build
	make image-eqemu-server-build-dev
	make image-peq-editor-build
	make image-backup-cron-build

image-push-all: ##@image-build Push all images
	make image-eqemu-server-push
	make image-eqemu-server-push-dev
	make image-peq-editor-push
	make image-backup-cron-push

image-build-push-all: ##@image-build Build and push all images
	make image-build-all
	make image-push-all

# eqemu-server

image-eqemu-server-build: ##@image-build Builds image
	docker build containers/eqemu-server -t akkadius/eqemu-server:latest
	docker build containers/eqemu-server -t akkadius/eqemu-server:v14

image-eqemu-server-build-dev: ##@image-build Builds image (development)
	make image-eqemu-server-build
	docker build -f ./containers/eqemu-server/dev.dockerfile ./containers/eqemu-server -t akkadius/eqemu-server:v14-dev

image-eqemu-server-push: ##@image-build Publishes image
	docker push akkadius/eqemu-server:latest
	docker push akkadius/eqemu-server:v14

image-eqemu-server-push-dev: ##@image-build Publishes image
	docker push akkadius/eqemu-server:v14-dev

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
	$(DOCKER) exec eqemu-server bash

mc: ##@workflow Jump into the MySQL container console
	$(DOCKER) exec mariadb bash -c "mysql -uroot -p${MARIADB_ROOT_PASSWORD} -h localhost ${MARIADB_DATABASE}"

MYSQL_BACKUP_NAME=${MARIADB_DATABASE}-$(shell date +"%m-%d-%Y")

mysql-backup: ##@workflow Jump into the MySQL container console
	$(DOCKER) exec -T mariadb bash -c "mysqldump --lock-tables=false -uroot -p${MARIADB_ROOT_PASSWORD} -h localhost ${MARIADB_DATABASE} > /var/lib/mysql/$(MYSQL_BACKUP_NAME).sql"
	mkdir -p backup/database/
	mv ./data/mariadb/$(MYSQL_BACKUP_NAME).sql .
	tar -zcvf backup/database/$(MYSQL_BACKUP_NAME).tar.gz $(MYSQL_BACKUP_NAME).sql
	rm $(MYSQL_BACKUP_NAME).sql

mysql-list-users: ##@workflow Lists MySQL users
	$(DOCKER) exec mariadb bash -c "mysql -uroot -p${MARIADB_ROOT_PASSWORD} -h localhost -e 'select user, password, host from mysql.user;'"

watch-processes: ##@workflow Watch processes
	$(DOCKER) exec eqemu-server bash -c "watch -n 1 'ps auxf'"

#----------------------
# Docker
#----------------------

up: ##@docker Bring up eqemu-server and database
	COMPOSE_HTTP_TIMEOUT=1000 $(DOCKER) up -d eqemu-server mariadb $(RUN_SERVICES)
	make up-info

down: ##@docker Down all containers
	COMPOSE_HTTP_TIMEOUT=1000 $(DOCKER) down --timeout 3

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
	$(DOCKER) up -d eqemu-server
	@assets/scripts/env-set-var.pl PORT_RANGE_HIGH $(RUN_ARGS)
	$(DOCKER) exec eqemu-server bash -c "cat ~/server/eqemu_config.json | jq '.server.zones.ports.high = "${PORT_RANGE_HIGH}"' -M > /tmp/config.json && mv /tmp/config.json ~/server/eqemu_config.json && rm -f /tmp/config.json"
	$(DOCKER) up -d --force-recreate eqemu-server

#----------------------
# Install
#----------------------

info: ##@info Print install info
	@echo "----------------------------------"
	@echo "> Server Info"
	@echo "----------------------------------"
	@echo '> $(shell $(DOCKER) exec -T eqemu-server bash -c "cat ~/server/eqemu_config.json | jq '.server.world.longname' | tr -d '\"'")'
	@echo "----------------------------------"
	@echo "> Passwords"
	@echo "----------------------------------"
	@cat .env | grep PASSWORD
	@echo "----------------------------------"
	@echo "> IP"
	@echo "----------------------------------"
	@cat .env | grep IP
	@echo "----------------------------------"
	@echo "> Quests FTP  | ${IP_ADDRESS}:21 | quests / ${FTP_QUESTS_PASSWORD}"
	@echo "----------------------------------"
	@echo "> Web Interfaces"
	@echo "----------------------------------"
	@echo "> PEQ Editor  | http://${IP_ADDRESS}:8081 | admin / ${PEQ_EDITOR_PASSWORD}"
	@echo "> PhpMyAdmin  | http://${IP_ADDRESS}:8082 | admin / ${PHPMYADMIN_PASSWORD}"
	@echo "> EQEmu Admin | http://${IP_ADDRESS}:3000 | admin / $(shell $(DOCKER) exec -T eqemu-server bash -c "cat ~/server/eqemu_config.json | jq '.[\"web-admin\"].application.admin.password'")"
ifeq ("$(SPIRE_DEV)", "true")
	@echo "----------------------------------"
	@echo "> Spire Backend Development  | http://${IP_ADDRESS}:3010 | "
	@echo "> Spire Frontend Development | http://${IP_ADDRESS}:8080 | "
endif
	@echo "----------------------------------"

up-info: ##@info Shows web interfaces during make up
	@echo "----------------------------------"
	@echo "> Web Interfaces"
	@echo "----------------------------------"
	@echo "> PEQ Editor  | http://${IP_ADDRESS}:8081"
	@echo "> PhpMyAdmin  | http://${IP_ADDRESS}:8082"
	@echo "> EQEmu Admin | http://${IP_ADDRESS}:3000"
ifeq ("$(SPIRE_DEV)", "true")
	@echo "----------------------------------"
	@echo "> Spire Backend Development  | http://${IP_ADDRESS}:3010"
	@echo "> Spire Frontend Development | http://${IP_ADDRESS}:8080"
endif
	@echo "----------------------------------"
	@echo "Use 'make info' to see passwords"
	@echo "----------------------------------"

#----------------------
# dev
#----------------------

fw: ##@dev Runs web-admin frontend dev server (alias)
	$(DOCKER) exec eqemu-server bash -c "cd ~/server/eqemu-web-admin/frontend && npm run serve"

bw: ##@dev Runs web-admin backend dev server (alias)
	$(DOCKER) exec eqemu-server bash -c "cd ~/server/eqemu-web-admin && npm run watch"


#----------------------
# backup
#----------------------

backup-dropbox-init: ##@backup Initializes Dropbox backups
	$(DOCKER) up -d backup-cron
	$(DOCKER) exec backup-cron dropbox_uploader.sh

backup-dropbox-list: ##@backup Lists files from Dropbox backups
	$(DOCKER) up -d backup-cron
	$(DOCKER) exec backup-cron dropbox_uploader.sh list

backup-dropbox-database: ##@backup Database backup upload to Dropbox
	$(DOCKER) exec backup-cron ./backup/backup-database.sh

backup-dropbox-quests: ##@backup Quests backup upload to Dropbox
	$(DOCKER) exec backup-cron ./backup/backup-quests.sh

backup-dropbox-deployment: ##@backup Deployment backup upload to Dropbox
	$(DOCKER) exec backup-cron ./backup/backup-deployment.sh

backup-dropbox-all: ##@backup Backup all assets to Dropbox
	make backup-dropbox-database
	make backup-dropbox-quests
	make backup-dropbox-deployment
