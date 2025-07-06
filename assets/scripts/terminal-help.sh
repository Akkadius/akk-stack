#!/usr/bin/env bash

red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

directory_spacing=$'%-25s'
quick_command_spacing=$'%-28s'

printf "\n> ${yel}EQEmulator Server Console${end}\n"
printf "\n"
printf "${cyn}# Navigation${end}\n"
printf "\n"
printf "${directory_spacing} | %-10s\n" "[${grn}assets${end}]" "Changes directory to assets"
printf "${directory_spacing} | %-10s\n" "[${grn}b|build${end}]" "Changes directory to build"
printf "${directory_spacing} | %-10s\n" "[${grn}bin${end}]" "Changes directory to bin"
printf "${directory_spacing} | %-10s\n" "[${grn}maps${end}]" "Changes directory to maps"
printf "${directory_spacing} | %-10s\n" "[${grn}plugins${end}]" "Changes directory to plugins"
printf "${directory_spacing} | %-10s\n" "[${grn}q|quests${end}]" "Changes directory to quests"
printf "${directory_spacing} | %-10s\n" "[${grn}s|server${end}]" "Changes directory to server"
printf "${directory_spacing} | %-10s\n" "[${grn}source${end}]" "Changes directory to source (alias)"
printf "\n"

printf "${cyn}# Development Commands${end}\n\n"
printf "${quick_command_spacing} | %-10s\n" "[${grn}m${end}]" "Runs [make] and compiles server"
#printf "${quick_command_spacing} | %-10s\n" "[${grn}core${end}]" "Analyzes last core dump created in server directory at ./core"
printf "${quick_command_spacing} | %-10s\n" "[${grn}update${end}]" "Runs [git pull] against source directory and immediately compiles"
printf "${quick_command_spacing} | %-10s\n" "[${grn}update-source${end}]" "Runs [git pull] against source directory and immediately compiles"
printf "${quick_command_spacing} | %-10s\n" "[${grn}update-release${end}]" "Updates server with latest release binaries"
printf "${quick_command_spacing} | %-10s\n" "[${grn}start${end}]" "Starts server"
printf "${quick_command_spacing} | %-10s\n" "[${grn}stop${end}]" "Stops server"
printf "${quick_command_spacing} | %-10s\n" "[${grn}restart${end}]" "Restarts server"
printf "\n"
printf "${quick_command_spacing} | %-10s\n" "[${grn}z|zone${end}]" "Starts a background [zone] process in the foreground"
printf "${quick_command_spacing} | %-10s\n" "[${grn}world${end}]" "Starts a background [world] process in the foreground"
printf "${quick_command_spacing} | %-10s\n" "[${grn}loginserver${end}]" "Starts a background [loginserver] process in the foreground"
printf "${quick_command_spacing} | %-10s\n" "[${grn}ucs${end}]" "Starts a background [ucs] process in the foreground"
printf "${quick_command_spacing} | %-10s\n" "[${grn}shared${end}]" "Starts a background [shared_memory] process in the foreground"
printf "\n"
printf "${quick_command_spacing} | %-10s\n" "[${grn}(k)process${end}]" "Kills all processes by name, example [kzone] [kworld]..."
printf "${quick_command_spacing} | %-10s\n" "[${grn}(c)crash${end}]" "Displays last occurred crash"
printf "${quick_command_spacing} | %-10s\n" "[${grn}crashes${end}]" "Displays all crashes"
printf "${quick_command_spacing} | %-10s\n" "[${grn}config${end}]" "Displays server config"
printf "\n"
printf "${quick_command_spacing} | %-10s\n" "[${grn}mc${end}]" "Create direct MySQL console"
printf "${quick_command_spacing} | %-10s\n" "[${grn}repogen${end}]" "[table|all] [base|extended|all] Shortcut to repository generator"
printf "\n"

# Spire
if [[ "${SPIRE_DEV}" == *"true"* ]]; then
  printf "${cyn}# Spire Development Commands${end}\n\n"
  printf "${directory_spacing} | %-10s\n" "[${grn}spire${end}]" "Changes directory to spire (alias)"
  printf "${directory_spacing} | %-10s\n" "[${grn}spire-be${end}]" "Starts Spire backend development server"
  printf "${directory_spacing} | %-10s\n" "[${grn}spire-fe${end}]" "Starts Spire frontend development server"
  printf "${directory_spacing} | %-10s\n" "[${grn}spirewatch${end}]" "Starts both with split-screen monitor (tmux)"
  printf "\n"
fi

##############################
# Get server name
##############################

if [[ -f "$(ls ~/server/eqemu_config.json)" ]]; then
	printf "${yel}> Server${end} [$(cat ~/server/eqemu_config.json | jq '.server.world.longname' | tr -d '\"')]\n\n"
fi
