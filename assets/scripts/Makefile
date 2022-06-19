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

#----------------------
# Init / Install
#----------------------

test:
	@echo ${EQEMU_DB_PASSWORD}
	@echo ${SERVER_PASSWORD}
	@echo ${RANDOM_ID}
	cat ~/server/eqemu_config.json \
		| jq '.server.database.password = "${EQEMU_DB_PASSWORD}"' \
		| jq '.server.world.key = "$(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $${1:-32} | head -n 1)"' \
		| tee ~/server/eqemu_config.json

install: ##@init Install full application
	@make init-directories
	@make init-eqemu-config
	@make pull-eqemu-code
	@make pull-peq-quests
	@make pull-eqemu-server-script
	@make pull-maps
	@make init-build
	@make build-with-cores 4
	@~/assets/scripts/create-symlinks.pl
	@make init-peq-database
	@make init-loginserver
	@make init-peq-editor
	@make pull-utility-scripts
	@make init-eqemu-admin
	@make init-set-perms

init-eqemu-config: ##@init Bootstraps eqemu config
	@./assets/scripts/banner.pl "Initializing EQEmu Config"
	@make pull-docker-config
	@cat ~/server/eqemu_config.json \
    		| jq '.server.database.password = "${EQEMU_DB_PASSWORD}"' \
    		| jq '.server.world.key = "$(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $${1:-32} | head -n 1)"' \
    		| jq '.server.zones.ports.high = "${PORT_RANGE_HIGH}"' \
    		| jq '.server.world.address = "${IP_ADDRESS}"' \
    		| tee ~/server/eqemu_config.json

init-directories: ##@init Bootstrap directories
	@./assets/scripts/banner.pl "Bootstrapping directories"
	sudo chown eqemu:eqemu ~/server -R
	sudo chown eqemu:eqemu ~/code -R
	mkdir -p ~/server/assets
	mkdir -p ~/server/assets/patches
	mkdir -p ~/server/assets/opcodes
	mkdir -p ~/server/bin
	mkdir -p ~/server/logs
	mkdir -p ~/server/shared
	mkdir -p ~/server/assets

init-peq-database: ##@init Sources fresh PEQ database (Warning: Will over-write existing)
	@./assets/scripts/banner.pl "Bootstrapping PEQ Database"
	~/assets/scripts/source-database.sh
	cd ~/server && perl eqemu_server.pl source_peq_db
	cd ~/server && perl eqemu_server.pl check_db_updates

init-loginserver: ##@init Initializes Loginserver
	@./assets/scripts/banner.pl "Initializing Loginserver"
	wget --quiet https://raw.githubusercontent.com/EQEmu/Server/master/loginserver/login_util/login.json -O /tmp/login.json
	wget --quiet https://raw.githubusercontent.com/EQEmu/Server/master/loginserver/login_util/login_opcodes.conf -O ~/server/assets/opcodes/login_opcodes.conf
	wget --quiet https://raw.githubusercontent.com/EQEmu/Server/master/loginserver/login_util/login_opcodes_sod.conf -O ~/server/assets/opcodes/login_opcodes_sod.conf
	cat /tmp/login.json | grep -o '^[^/]*' | jq '' \
		| jq '.database.host = "$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.host')"' \
		| jq '.database.db = "$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.db')"' \
		| jq '.database.user = "$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.username')"' \
		| jq '.database.password = "$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.password')"' \
		| jq '.client_configuration.titanium_opcodes = "assets/opcodes/login_opcodes.conf"' \
		| jq '.client_configuration.sod_opcodes = "assets/opcodes/login_opcodes_sod.conf"' \
		> ~/server/login.json
	wget --quiet https://raw.githubusercontent.com/EQEmu/Server/master/loginserver/login_util/login_schema.sql -O /tmp/login_schema.sql
	mysql -u$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.username') \
		-p$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.password') \
		-h $(shell ~/assets/scripts/init/get-config-var.sh '.server.database.host') \
		$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.db') < /tmp/login_schema.sql
	@./assets/scripts/banner.pl "Loginserver initialized!"

BIN_FILE_NAME=eqemu-admin-bin-$(shell date +"%m-%d-%Y-%H-%M-%S")

init-eqemu-admin: ##@init Initializes EQEmu Admin
	rm -f ~/server/bin/eqemu-admin-*
	wget $(shell curl -s https://api.github.com/repos/Akkadius/Occulus/releases/latest | jq -r '.assets[].browser_download_url' | grep linux) -O ~/server/bin/$(BIN_FILE_NAME)
	chmod +x ~/server/bin/$(BIN_FILE_NAME)
	ln -sf ~/server/bin/$(BIN_FILE_NAME) ~/server/bin/eqemu-admin

init-eqemu-admin-dev: ##@init Initializes EQEmu Admin (Development)
	cd ~/server && if cd eqemu-web-admin 2> /dev/null; then git pull; else git clone https://github.com/Akkadius/eqemu-web-admin; fi
	cd ~/server/eqemu-web-admin && git checkout release
	cd ~/server/eqemu-web-admin && npm install
	cd ~/server/eqemu-web-admin/frontend && npm install

init-peq-editor: ##@init Initializes PEQ Editor DB tables
	wget --quiet https://raw.githubusercontent.com/ProjectEQ/peqphpeditor/master/sql/schema.sql -O /tmp/schema.sql
	mysql -u$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.username') \
    		-p$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.password') \
    		-h $(shell ~/assets/scripts/init/get-config-var.sh '.server.database.host') \
    		$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.db') < /tmp/schema.sql
	mysql -u$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.username') \
    		-p$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.password') \
    		-h $(shell ~/assets/scripts/init/get-config-var.sh '.server.database.host') \
    		$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.db') -e 'update peq_admin SET password = MD5("${PEQ_EDITOR_PASSWORD}") where id = 1'

init-set-perms: ##@init Sets permissions recursively
	find ~/ -not -user eqemu -execdir sudo chown eqemu:eqemu {} \+

#----------------------
# Assets
#----------------------

pull-maps: ##@assets Pulls maps
	@./assets/scripts/banner.pl "Pulling latest EQEmu Maps"
	@if [ $(shell find ~/server/maps | wc -l) -gt 10 ] ; then \
		echo "maps is initialized"; \
	else \
		echo "maps is not initialized"; \
		cd server && wget https://codeload.github.com/Akkadius/EQEmuMaps/zip/master -O maps.zip && unzip -o maps.zip && rm ./maps -rf && mv EQEmuMaps-master maps && rm maps.zip; \
	fi

pull-eqemu-code: ##@assets Pulls eqemu code
	@./assets/scripts/banner.pl "Pulling EQEmu Source Code into [./code]"
	git -C ./code pull 2> /dev/null || git clone https://github.com/EQEmu/Server.git code

pull-eqemu-server-script: ##@assets Pulls eqemu_server.pl
	@./assets/scripts/banner.pl "Pulling EQEmu Server Management Script [eqemu_server.pl]"
	cd ~/server && wget --no-check-certificate https://raw.githubusercontent.com/EQEmu/Server/master/utils/scripts/eqemu_server.pl -O eqemu_server.pl && chmod 755 eqemu_server.pl

pull-peq-quests: ##@assets Pulls ProjectEQ quests
	@./assets/scripts/banner.pl "Pulling Latest ProjectEQ Quests"
	cd ~/server && git -C ./quests pull 2> /dev/null || git clone https://github.com/ProjectEQ/projecteqquests.git quests

pull-docker-config: ##@assets Pulls default eqemu_config.json
	@./assets/scripts/banner.pl "Bootstrapping default [eqemu_config.json]"
	cd ~/server && wget --no-cache --no-check-certificate --no-cookies https://raw.githubusercontent.com/Akkadius/EQEmuInstall/master/eqemu_config_docker.json -O eqemu_config.json

pull-utility-scripts: ##@assets Pulls utility scripts (start/stop server)
	@./assets/scripts/banner.pl "Bootstrapping server utility scripts"
	cd ~/server && perl eqemu_server.pl utility_scripts
	cd ~/server && chmod 755 *.sh

#----------------------
# mgmt
#----------------------

mgmt-mc: ##@mgmt Connect to MySQL Server
	mysql -u$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.username') -p$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.password') -h $(shell ~/assets/scripts/init/get-config-var.sh '.server.database.host') $(shell ~/assets/scripts/init/get-config-var.sh '.server.database.db')

last-crash: ##@mgmt Shows last crash that happened
	cat ~/server/logs/crashes/$$(ls -Art ~/server/logs/crashes | tail -n 1)

#----------------------
# build
#----------------------

init-build: ##@build Initialize build
	@./assets/scripts/banner.pl "Initializing EQEmu Server Build"
	cd ~/code && git submodule init && git submodule update && mkdir -p build && cd build && cmake -DEQEMU_BUILD_LOGIN=ON -DEQEMU_BUILD_LUA=ON -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -G 'Unix Makefiles' ..

build: ##@build Build EQEmu server
	@./assets/scripts/banner.pl "Building EQEmu Server"
	cd ~/code/build && make

build-clean: ##@build Cleans build directory
	cd ~/code/build && make clean

build-with-cores: ##@build Build EQEmu server (make build-with-cores <number>)
	cd ~/code/build && make -j$(RUN_ARGS)

#----------------------
# update
#----------------------

update-admin-panel: ##@update Update admin panel
	kill $(shell ps aux | grep "eqemu-admin" | grep "web" | grep -v "grep" | awk '{print $$2}' | tr '\n' ' ') &>/dev/null || echo "Nothing to kill"
	make init-eqemu-admin
	while true; do cd ~/server/bin/ && nohup ./eqemu-admin web >/dev/null 2>&1; sleep 1; done &
