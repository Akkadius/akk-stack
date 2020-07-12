# AkkStack | Containerized EverQuest Emulator Server Environment

<p align="center"><img width="600" src="https://user-images.githubusercontent.com/3319450/87238998-55010c00-c3cf-11ea-8db5-3be25a868ac8.png" alt="AkkStack"></p>

# What is AkkStack ?

AkkStack is a simple Docker Compose environment that is augmented with developer and operator focused tooling for running EverQuest Emulator servers

This is what I've used in production, battle-tested, for almost 2 years. I've worked through a lot of issues to give you the final stable product. It's what I've also used for development for around the same time frame and you will see why shortly

# Requirements

Linux Host or VM with Docker Installed along with Docker Compose

# What's Included

## Containerized Services

| **Service** | **Description**  |
|---|---|
| eqemu-server |  Runs the Emulator server and all services  |
| mariadb | MySQL service |
| phpmyadmin | (Optional) PhpMyAdmin which is automatically configured behind a password proxy |
| peq-editor | (Optional) PEQ Editor which is automatically configured  |
| ftp-quests | (Optional) An FTP instance fully ready to be used to remotely edit quests |
| backup-cron | (Optional) A container built to automatically backup (Dropbox API) the entire deployment and perform database and quest snapshots for with different retention schedules defined in `.env` |

# Features

## Very Easy to Use CLI menus

Embedded server management CLI (What is used a majority of the time)

<p align="center"><img src="https://user-images.githubusercontent.com/3319450/87240603-7c140980-c3e0-11ea-9e92-ce18edcfad29.gif"></p>

A `make` menu to manage the in-container environment

<p align="center"><img src="https://user-images.githubusercontent.com/3319450/87240694-779c2080-c3e1-11ea-8330-26d8add10e5f.gif"></p>

A `make` menu to manage the host-level container environment

<p align="center"><img src="https://user-images.githubusercontent.com/3319450/87240726-bfbb4300-c3e1-11ea-80ac-e53bfa3386f4.gif"></p>

## SSH

Automatically configured SSH to the `eqemu-server` with automatically generated 30+ character password, persistent keys through reboot
  
## MariaDB

Configurable INNODB_BUFFER_POOL_MEMORY (Default: 256MB) (Must set before make install or rebuild mariadb)

If you are running a production server with a decent amount of players, consider setting this to 512MB or 1GB to avoid page thrashing

If you already ran `make install` simply adjust this value in your `.env` (Uncomment) and rebuild the mariadb container via `docker-compose build mariadb` and restarting the container `docker-compose restart mariadb`

You can validate your buffer pool value reflects what you set in the console

## PEQ Editor

Automatically configured with pre-set admin password; listens on port 8081 by default

<p align="center"><img src="https://user-images.githubusercontent.com/3319450/87240902-3dcc1980-c3e3-11ea-9d1e-746e217b4459.png"></p>

## PhpMyAdmin

Automatically configured PhpMyAdmin instance with pre-set admin password (Behind a password protected proxy); listens on port 8082 by default

<p align="center"><img src="https://user-images.githubusercontent.com/3319450/87240916-63f1b980-c3e3-11ea-8dd8-93bca87f54ec.png"></p>

<p align="center"><img src="https://user-images.githubusercontent.com/3319450/87240919-6f44e500-c3e3-11ea-8c56-6fe0e5ecef89.png"></p>

## Occulus

Automatically installed server admin panel [Occulus repository](https://github.com/Akkadius/eqemu-web-admin); listens on port 3000 by default

<p align="center"><img src="https://user-images.githubusercontent.com/3319450/87236540-8c13f500-c3b0-11ea-87f6-756e60fa61ed.png"></p>

## Symlinked resources
  * Server binaries - Never need to copy binaries after a compile
  * Patch files
  * Quests
  * Plugins 
  * LUA Modules

## File Structure

<p align="center"><img src="https://user-images.githubusercontent.com/3319450/87240837-ba122d00-c3e2-11ea-811f-5ed92f2c79f0.gif"></p>

## Automated Backups

Automated cron-based backups that upload to Dropbox using Dropbox API

Follow instructions below to get an API key to enter into the `.env`

```
This is the first time you run this script, please follow the instructions:

1) Open the following URL in your Browser, and log in using your account: https://www.dropbox.com/developers/apps
2) Click on "Create App", then select "Dropbox API app"
3) Now go on with the configuration, choosing the app permissions and access restrictions to your DropBox folder
4) Enter the "App Name" that you prefer (e.g. MyUploader984915521299)

Now, click on the "Create App" button.
```

Backup retention configurable in `.env`

```
# DEPLOYMENT_NAME=peq-production (used in backup names)
# DROPBOX_OAUTH_ACCESS_TOKEN=
# BACKUP_RETENTION_DAYS_DB_SNAPSHOTS=10
# BACKUP_RETENTION_DAYS_DEPLOYMENT=35
# BACKUP_RETENTION_DAYS_QUEST_SNAPSHOTS=7
```

Crons defined in `backup/crontab.cron`

Crons are configured to run on a variance so that not all deployments fire backups at the same time

| **Backup Type** | **Description** | **Schedule** |
|---|---|---|
| Deployment | Deployment consists of the entire akk-stack folder (server, database etc.). If you ever experienced catastrophic failure or needed to restore the entire setup, simply restoring the deployment folder will get you back up and running | Once a week at 1AM on a random variance of 1800 seconds |
| Quests | A simple snapshot of the quests folder | Once a day at 1M on a random variance of 1800 seconds |
| Database | A simple snapshot of the database | Once a day at 1M on a random variance of 1800 seconds |

## High CPU Process Watchdog

If a zone process goes into an infinite loop; the watchdog will kill the process and log it in the home directory

```
eqemu@f8905f80723c:~$ cat process-kill.log
Sat Jul 11 20:52:47 CDT 2020 [process-watcher] Killed process [21143] [./bin/zone] for taking too much CPU time [43.50]
```

# Installation

First clone the repository somewhere on your server, in this case I'm going to clone it to an `/opt/eqemu-servers` folder in a Debian Linux host with Docker installed

```
root@host:/opt/eqemu-servers# git clone https://github.com/Akkadius/akk-stack.git peq-test-server
Cloning into 'peq-test-server'...
remote: Enumerating objects: 57, done.
remote: Counting objects: 100% (57/57), done.
remote: Compressing objects: 100% (42/42), done.
remote: Total 782 (delta 14), reused 52 (delta 11), pack-reused 725
Receiving objects: 100% (782/782), 101.94 KiB | 7.28 MiB/s, done.
Resolving deltas: 100% (437/437), done.
```

Change into the new directory that represents your server

```
root@host:/opt/eqemu-servers# cd peq-test-server/
```

## Initialize the Environment

There are a ton of configuration variables available in the `.env` file that is produced from running the next command, we will get into that later. The key thing here is that it creates the base `.env` and scrambles all of the password fields in the environment

```
root@host:/opt/eqemu-servers# make init-reset-env
make env-transplant
Wrote updated config to [.env]
make env-scramble-secrets
Wrote updated config to [.env]
```

## Initialize Network Parameters

The next command is going to initialize two large key things in our setup

1) The ip address we're going to use
2) The zone port range we're going to use

Make sure that you only open as many ports as you need on the zone end, because `docker-proxy` will NAT all ports individually in its own docker userland which does take some time when starting and shutting off containers. The more ports you nail up, the longer it takes to start / stop. Since this is a test server, I'm only going to use 30 ports. This `make` command also drives the `eqemu_config.json` port and address parameters as well automatically for you

```
root@host:/opt/eqemu-servers# make set-vars port-range-high=7030 ip-address=66.70.153.122
Wrote [IP_ADDRESS] = [66.70.153.122] to [.env]
Wrote [PORT_RANGE_HIGH] = [7030] to [.env]
```

# Install

From this point you're ready to run the fully automated install with a simple `make install`

An example of what this output looks like below (Sped up)

<p align="center"><img src="https://user-images.githubusercontent.com/3319450/87240353-7289a200-c3de-11ea-8afe-1b0a5ad8400e.gif"></p>
  
# Post-Install

Now that you're installed we need to look at how we interact with the environment

To gain a bash into the emulator server we have two options, we can come through a docker exec entry or we can SSH into the container

## Direct Bash

![make-bash](https://user-images.githubusercontent.com/3319450/87241544-e8473b00-c3e9-11ea-8232-33fa3da9d40b.gif)

## SSH

![make-ssh](https://user-images.githubusercontent.com/3319450/87241545-ea10fe80-c3e9-11ea-9a7f-c97ba54e93fa.gif)

## MySQL Console 

You can hop into MySQL shell from either docker exec `make mc` or from the `eqemu-server` embeded shell alias `mc`

![mysql-shell](https://user-images.githubusercontent.com/3319450/87241546-ec735880-c3e9-11ea-9a8e-412ca4d99736.gif)

## Deployment Info

To print a handy list of passwords and access URL's, simply use `make info` at the host level of the deployment

```
root@host:/opt/eqemu-servers/peq-test-server# make info
##################################
# Server Info
##################################
# Akkas Docker PEQ Installer
##################################
# Passwords
##################################
MARIADB_PASSWORD=1jo5XUzpY7lYOf5FmJKRBhUfGmnVzBN
MARIADB_ROOT_PASSWORD=mDI8gefiVEGjeiMCUMrZhMmKMWI101B
SERVER_PASSWORD=uVNjjlucE5H9UzUlziZfP16GQvsWJhe
PHPMYADMIN_PASSWORD=tD02XcNGoaIaV82wnnEnenp0V7p58V9
PEQ_EDITOR_PASSWORD=5X5o1E84SXQzjmxN86fLzuBFJyGEjN9
FTP_QUESTS_PASSWORD=Jqx3KxCZFkRA1aPqBJqMTSA1vA8uK4Y
##################################
# IP
##################################
IP_ADDRESS=66.70.153.122
##################################
# Quests FTP  | 66.70.153.122:21 | quests / Jqx3KxCZFkRA1aPqBJqMTSA1vA8uK4Y
##################################
# Web Interfaces
##################################
# PEQ Editor  | http://66.70.153.122:8081 | admin / 5X5o1E84SXQzjmxN86fLzuBFJyGEjN9
# PhpMyAdmin  | http://66.70.153.122:8082 | admin / tD02XcNGoaIaV82wnnEnenp0V7p58V9
# EQEmu Admin | http://66.70.153.122:3000 | admin / 82a71144a51c521283834f99daff5a
##################################
```

## Service Lifetime

By default each container / service in the `docker-compose.yml` is configured to restart unless stopped, meaning if the server restarts the Docker daemon will boot the services you had started initially which is the default behavior of this stack

Occulus and the eqemu-server entrypoint bootup script is designed to start the emulator server services when the server first comes up, so if you need to bring the whole host down, everything will come back up on reboot automatically

## Services to Boot

By default the whole deployment is booted post install, but for production setups maybe you only want the emulator server and the database server only. Simply bring everything down with either `make down` or `docker-compose down`

`make up` will by default only bring up eqemu-server and mariadb

```
root@host:/opt/eqemu-servers/peq-test-server# make up --dry-run
docker-compose up -d eqemu-server mariadb
```

If you want to single boot another service, such as the `peq-editor` simply `docker-compose up -d peq-editor` and you'll have the 2 main services as well as the editor booted

![dc-ps](https://user-images.githubusercontent.com/3319450/87241769-eb432b00-c3eb-11ea-9cbf-f48307981303.gif)

## Accessing the Admin Panel

By default, Occulus runs within the `eqemu-server` service container and is available on port 3000

To access your admin panel bash or ssh into your server and run config to see your web admin password (Or view it in make info mentioned before)

```
eqemu@97b8129b90b4:~$ config | jq '.["web-admin"]'
{
  "application": {
    "key": "dadbeb31-3073-43dc-a359-569737bb2746",
    "admin": {
      "password": "82a71144a51c521283834f99daff5a"
    }
  },
  "launcher": {
    "runLoginserver": false,
    "runQueryServ": false,
    "isRunning": true,
    "minZoneProcesses": 3
  }
}
```

## Updating Server Binaries

Updating server binaries is as simple as running `update` in the server shell, it will change directory to the source directory, git pull and run a build which will be immediately available the next time you boot a process

## Running Server Processes While Developing

While developing its easy to jump back and forth between compiling changes and running single processes

If you have camped to character select, you can run `kzone` which will kill all zones and simply typing `z` will boot a zone process in the background but will still display in the foreground of the shell

`world` `ucs` `shared` are all shorthands that also work anywhere in any folder in the shell (See below in compiling and developing)

## Compiling and Developing

Compiling is as simple as typing `m` anywhere in the embedded shell

![update](https://user-images.githubusercontent.com/3319450/87242061-e5027e00-c3ee-11ea-9711-c5ce4ae716cb.gif)

# Feature Requests

Want a feature that isn't already available? Open an issue with the title "[Feature Request]" and we will see about getting it added

# Contributing

If you want to contribute to the repo, please submit **Pull Requests**

# Pay it Forward

If you use this repository; you're taking advantage of a ton of work that I've done to make the experience incredibly simple for you to use for free - please pay it forward to the community by contributing
