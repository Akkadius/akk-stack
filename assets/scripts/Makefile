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

install: ##@init Install full application
	@make init-directories
	@make init-eqemu-config
	@make pull-eqemu-code
	@make pull-peq-quests
	@make pull-maps
	@make init-build
	@~/assets/scripts/create-symlinks.pl
	@make init-eqemu-admin
	@make init-server-binaries
	@make init-peq-database
	@make init-loginserver
	@make init-peq-editor
	@make init-set-perms
	@make init-shared-memory
ifeq ("$(SPIRE_DEV)", "true")
	@make init-spire-dev
endif

init-spire-dev: ##@init Initialize Spire for development
	cd ~/server && git clone https://github.com/akkadius/spire || cd ~/server/spire && git pull
	cd ~/server/spire && cp .env.dev .env
	cd ~/server/spire && go get
	cd ~/server/spire/frontend && npm install
	echo "VUE_APP_BACKEND_BASE_URL=http://${IP_ADDRESS}:3010" > ~/server/spire/frontend/.env

init-shared-memory: ##@init Run shared memory once on initial install
	cd ~/server/ && ./bin/shared_memory

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
	curl http://db.projecteq.net/api/v1/dump/latest -o /tmp/db.zip
	unzip -o /tmp/db.zip -d /tmp/db/
	cd /tmp/db/peq-dump/ && mysql -u$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.username') \
		-p$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.password') \
		-h $(shell ~/assets/scripts/init/get-config-var.sh '.server.database.host') \
		$(shell ~/assets/scripts/init/get-config-var.sh '.server.database.db') \
		< ./create_all_tables.sql
	rm -rf /tmp/db/
	cd ~/server && ./bin/world database:updates

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

BIN_FILE_NAME=spire-admin-bin-$(shell date +"%m-%d-%Y-%H-%M-%S")

ADMIN_PASSWORD=${SPIRE_ADMIN_PASSWORD}
ifeq ("${ADMIN_PASSWORD}", "")
	ADMIN_PASSWORD=$(shell cat ~/server/eqemu_config.json 2>/dev/null | jq '.["web-admin"].application.admin.password' | tr -d '"' || echo "")
endif

init-eqemu-admin: ##@init Initializes EQEmu Admin
	rm -f ~/server/bin/eqemu-admin-*
	rm -f ~/server/bin/spire-*
	wget --quiet $(shell curl -s https://api.github.com/repos/Akkadius/spire/releases/latest | jq -r '.assets[].browser_download_url' | grep spire-linux) -O /tmp/spire.zip
	unzip -o /tmp/spire.zip -d ~/server/bin
	mv ~/server/bin/spire-linux-amd64 ~/server/bin/spire
	chmod +x ~/server/bin/spire
	cd ~/server && SKIP_ASSET_CHECK=1 ./bin/spire spire:init admin ${ADMIN_PASSWORD} || echo "Already initialized"
	cat ~/server/eqemu_config.json | jq '' \
		| jq '.["web-admin"].application.admin.password = "${ADMIN_PASSWORD}"' \
		| jq '.["web-admin"].application.key = "$(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $${1:-32} | head -n 1)"' \
		| jq '.["web-admin"].launcher.runSharedMemory = true' \
		| jq '.["web-admin"].launcher.minZoneProcesses = 10' \
		| jq '.["web-admin"].launcher.staticZones = "butcher,erudnext,freporte,qeynos,freeporte,oot,iceclad,nro,oasis,nedaria,abysmal,natimbi,timorous,abysmal,firiona,overthere"' \
		| tee ~/server/eqemu_config.json
	cd ~/server && ./bin/spire spire:init admin ${ADMIN_PASSWORD} || echo "Already initialized"
	cd ~/server && ./bin/spire spire:occulus-update

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

init-server-binaries: ##@init Initializes server binaries
	cd ~/server && ./bin/spire eqemu-server:update --release-binaries=true --auto=true

init-perl: ##@init Initializes perl - compiles perl from source to /opt/eqemu-perl
	@./assets/scripts/banner.pl "Initializing Perl"
	sudo mkdir -p /opt/eqemu-perl
	mkdir -p /tmp/eqemu-perl
	sudo chown eqemu:eqemu /opt/eqemu-perl -R
	cd /tmp && wget https://github.com/Perl/perl5/archive/refs/tags/v5.32.1.tar.gz -O perl.tar.gz
	cd /tmp && tar -xzf perl.tar.gz --strip-components=1 -C /tmp/eqemu-perl
	cd /tmp/eqemu-perl && ./Configure -des -Dprefix=/opt/eqemu-perl -Dusethreads -Dusemultiplicity -Duse64bitall -Dnoextensions -Duseshrplib
	cd /tmp/eqemu-perl && make -j$(shell nproc)
	# cd /opt/eqemu-perl && make -j$(shell nproc) test_harness
	cd /tmp/eqemu-perl && make install
	rm -rf /tmp/perl.tar.gz
	rm -rf /tmp/eqemu-perl
	# install DBI and DBD::mysql
	yes | sudo /opt/eqemu-perl/bin/perl -MCPAN -e 'install App::cpanminus'
	sudo /opt/eqemu-perl/bin/cpanm DBI
	sudo /opt/eqemu-perl/bin/cpanm DBD::mysql@4.046_01
	sudo /opt/eqemu-perl/bin/cpanm JSON
	sudo /opt/eqemu-perl/bin/cpanm Data::Dumper
	sudo /opt/eqemu-perl/bin/cpanm File::Find
	sudo /opt/eqemu-perl/bin/cpanm File::Path
	sudo /opt/eqemu-perl/bin/cpanm List::Util
	sudo /opt/eqemu-perl/bin/cpanm -n Module::Refresh
	sudo chown eqemu:eqemu -R /opt/eqemu-perl/

#----------------------
# Assets
#----------------------

pull-maps: ##@assets Pulls maps
	@./assets/scripts/banner.pl "Pulling latest EQEmu Maps"
	@if [ $(shell find ~/server/maps | wc -l) -gt 10 ] ; then \
		echo "maps is initialized"; \
	else \
		echo "maps is not initialized"; \
		cd server && wget https://github.com/Akkadius/eqemu-maps/releases/latest/download/maps.zip -O /tmp/maps.zip && unzip -o /tmp/maps.zip -d ~/server/maps && rm /tmp/maps.zip; \
	fi

pull-eqemu-code: ##@assets Pulls eqemu code
	@./assets/scripts/banner.pl "Pulling EQEmu Source Code into [./code]"
	git -C ./code pull 2> /dev/null || git clone https://github.com/EQEmu/Server.git code

pull-peq-quests: ##@assets Pulls ProjectEQ quests
	@./assets/scripts/banner.pl "Pulling Latest ProjectEQ Quests"
	cd ~/server && git -C ./quests pull 2> /dev/null || git clone https://github.com/ProjectEQ/projecteqquests.git quests

pull-docker-config: ##@assets Pulls default eqemu_config.json
	@./assets/scripts/banner.pl "Bootstrapping default [eqemu_config.json]"
	cd ~/server && wget --no-cache --no-check-certificate --no-cookies https://raw.githubusercontent.com/Akkadius/eqemu-install-v2/master/eqemu_config_docker.json -O eqemu_config.json

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
	cd ~/code && \
		git submodule init && \
		git submodule update && \
		rm -rf build && \
		mkdir -p build && \
		cd build && \
		cmake \
			-DEQEMU_BUILD_LOGIN=ON \
			-DEQEMU_BUILD_LUA=ON \
			-DPERL_LIBRARY=/opt/eqemu-perl/lib/5.32.1/x86_64-linux-thread-multi/CORE/libperl.so \
			-DPERL_EXECUTABLE=/opt/eqemu-perl/bin/perl \
			-DPERL_INCLUDE_PATH=/opt/eqemu-perl/lib/5.32.1/x86_64-linux-thread-multi/CORE/ \
			-DCMAKE_CXX_FLAGS_RELWITHDEBINFO:STRING="-O1 -g -DNDEBUG -Wno-everything" \
			-DCMAKE_CXX_COMPILER_LAUNCHER=ccache -G 'Unix Makefiles' ..

init-dev-build: ##@build Initialize build for development (faster compiles, uses ninja)
	@./assets/scripts/banner.pl "Initializing EQEmu Server Build"
	cd ~/code && \
		git submodule init && \
		git submodule update && \
		rm -rf build && \
		mkdir -p build && \
		cd build && \
		cmake -DEQEMU_BUILD_LOGIN=ON \
			-DEQEMU_BUILD_TESTS=ON \
			-DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
			-DPERL_LIBRARY=/opt/eqemu-perl/lib/5.32.1/x86_64-linux-thread-multi/CORE/libperl.so \
			-DPERL_EXECUTABLE=/opt/eqemu-perl/bin/perl \
			-DPERL_INCLUDE_PATH=/opt/eqemu-perl/lib/5.32.1/x86_64-linux-thread-multi/CORE/ \
			-DCMAKE_EXE_LINKER_FLAGS=-fuse-ld=gold \
			-DCMAKE_CXX_FLAGS_RELWITHDEBINFO:STRING="-O0 -g -DNDEBUG -Os -Wno-everything" -G "Ninja" ..

build: ##@build Build EQEmu server
	@./assets/scripts/banner.pl "Building EQEmu Server"
	cd ~/code/build && make

build-clean: ##@build Cleans build directory
	cd ~/code/build && make clean

#----------------------
# update
#----------------------

L_SPIRE_PORT=${SPIRE_PORT}
ifeq ("${L_SPIRE_PORT}", "")
	L_SPIRE_PORT=3000
endif

update-admin-panel: ##@update Update admin panel
	kill $(shell ps aux | grep "eqemu-admin" | grep "web" | grep -v "grep" | awk '{print $$2}' | tr '\n' ' ') &>/dev/null || echo "Nothing to kill"
	kill $(shell ps aux | grep "spire" | grep "http:serve" | grep -v "grep" | awk '{print $$2}' | tr '\n' ' ') &>/dev/null || echo "Nothing to kill"
	wget --quiet $(shell curl -s https://api.github.com/repos/Akkadius/spire/releases/latest | jq -r '.assets[].browser_download_url' | grep spire-linux) -O /tmp/spire.zip
	unzip -o /tmp/spire.zip -d ~/server/bin
	mv ~/server/bin/spire-linux-amd64 ~/server/bin/spire
	chmod +x ~/server/bin/spire
	while true; do cd ~/server/ && nohup ./bin/spire http:serve --port=${L_SPIRE_PORT} >/dev/null 2>&1; sleep 1; done &
