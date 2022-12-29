######################################
# Admin Panel
######################################
alias admin='cd ~/server/eqemu-web-admin'
alias adminrun='admin && nodemon ./app/bin/admin web'
alias admindebug='admin && DEBUG=eqemu-admin:* && nodemon ./app/bin/admin web'

######################################
# Directories
######################################
alias source='cd ~/code/build'
alias build='cd ~/code/build'
alias b='build'
alias server='cd ~/server'
alias s='server'
alias quests='cd ~/server/quests/'
alias q='quests'
alias plugins='cd ~/server/plugins/'
alias maps='cd ~/server/maps/'
alias assets='cd ~/server/assets/'
alias bin='cd ~/server/bin/'

######################################
# Server MGMT
######################################
# ./bin/eqemu-admin server-launcher && sleep 1
alias start='server && bash -c "while true; do nohup ./bin/eqemu-admin server-launcher >/dev/null 2>&1; sleep 1; done &" && echo Server started'
alias stop='server && ~/assets/scripts/stop-server.sh'
alias restart='server && stop && start'
alias update='source && git pull && make -j4'
alias logs='tail -f ~/server/logs/**/*.log'
alias m='source && make -j$(expr $(nproc) - 2) && server'
alias perm='sudo chown eqemu /home/eqemu/ -R'
alias c='cd ~/ && make last-crash'
alias config='cat ~/server/eqemu_config.json | jq .'
alias crash='c'
alias crashes='ls -lsh ~/server/logs/crashes/'
alias cm='source && cmake -DEQEMU_BUILD_LOGIN=ON -DEQEMU_BUILD_LUA=ON -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -G "Unix Makefiles" ..'
alias k='pkill zone'
alias r='m && z &'
# gdb --batch --quiet -ex "thread apply all bt full" -ex "quit" /home/eqemu/server/$(file core | grep -Po "(?<=execfn: '.\/)(.*)(?=', platform)") ./core | grep "#"
# alias core='gdb --batch --quiet -ex "thread apply all bt full" -ex "quit" /home/eqemu/server/$(file core | grep -Po "(?<=execfn: '\''.\/)(.*)(?='\'', platform)") ./core | grep "#"'

alias n='cd ~/code/build && ninja -j$(expr $(nproc) - 2)'
alias nz='cd ~/code/build && ninja-j$(expr $(nproc) - 2) && pkill -9 zone && z'

######################################
# Help
######################################
alias ?='~/assets/scripts/terminal-help.sh'
alias help='~/assets/scripts/terminal-help.sh'

######################################
# Quick Launch
######################################
alias zone='server && ./bin/zone &'
alias z='zone'
alias loginserver='server && ./bin/loginserver &'
alias ucs='server && ./bin/ucs &'
alias world='server && ./bin/world &'
alias shared='server && ./bin/shared_memory &'

######################################
# Quick Kill
######################################
alias kzone='pkill zone'
alias kloginserver='pkill loginserver'
alias kucs='pkill ucs'
alias kworld='pkill world'

######################################
# Spire development aliases
######################################
if [[ "${SPIRE_DEV}" == *"true"* ]]; then
    alias spire='cd ~/server/spire'
    alias spire-be='cd ~/server/spire && air'
    alias spire-fe='cd ~/server/spire/frontend && npm run dev'
fi

######################################
# mgmt
######################################
alias mc='cd ~/ && make mgmt-mc'

~/assets/scripts/terminal-help.sh

# export LC_CTYPE=en_US.UTF-8
export LC_ALL=C
