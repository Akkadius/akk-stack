
# AkkStack | Containerized EverQuest Emulator Server Environment

<p align="center"><img width="600" src="https://user-images.githubusercontent.com/3319450/87238998-55010c00-c3cf-11ea-8db5-3be25a868ac8.png" alt="AkkStack"></p>

<hr>

<p align="center">
 <img height="70" src="https://user-images.githubusercontent.com/3319450/87256107-950ad200-c455-11ea-9cdf-17cc277b874e.png" alt="Docker">
</p>

<hr>

AkkStack is a simple Docker Compose environment that is augmented with developer and operator focused tooling for running EverQuest Emulator servers

You can have an entire server running within minutes, configured and ready to go for development or production use

This is what I've used in production, battle-tested, for almost 2 years. I've worked through a lot of issues to give you the final stable product. It's what I've also used for development for around the same time frame and you will see why shortly

- [AkkStack | Containerized EverQuest Emulator Server Environment](#akkstack--containerized-everquest-emulator-server-environment)
- [Requirements](#requirements)
- [What's Included](#whats-included)
  * [Containerized Services](#containerized-services)
- [Features](#features)
  * [Very Easy to Use CLI menus](#very-easy-to-use-cli-menus)
  * [SSH](#ssh)
  * [Cron Jobs](#cron-jobs)
  * [Startup Scripts](#startup-scripts)
  * [MariaDB](#mariadb)
    + [Users](#users)
  * [PEQ Editor](#peq-editor)
  * [PhpMyAdmin](#phpmyadmin)
  * [Occulus](#occulus)
  * [Symlinked resources](#symlinked-resources)
  * [File Structure](#file-structure)
  * [Automated Backups](#automated-backups)
  * [High CPU Process Watchdog](#high-cpu-process-watchdog)
  * [CPU Share Throttling](#cpu-share-throttling)
- [Installation](#installation)
  * [Initialize the Environment](#initialize-the-environment)
  * [Initialize Network Parameters](#initialize-network-parameters)
- [Install](#install)
- [Post-Install](#post-install)
  * [Direct Bash](#direct-bash)
  * [SSH](#ssh-1)
  * [MySQL Console](#mysql-console)
  * [Deployment Info](#deployment-info)
  * [Service Lifetime](#service-lifetime)
  * [Services to Boot](#services-to-boot)
  * [Accessing the Admin Panel](#accessing-the-admin-panel)
  * [Updating Server Binaries](#updating-server-binaries)
  * [Running Server Processes While Developing](#running-server-processes-while-developing)
  * [Compiling and Developing](#compiling-and-developing)
     + [Ninja Support](#ninja-support)
- [Feature Requests](#feature-requests)
- [Contributing](#contributing)
- [Pay it Forward](#pay-it-forward)
# Requirements

Linux Host or VM with [Docker Installed](https://docs.docker.com/engine/install/) along with [Docker Compose](https://docs.docker.com/compose/install/)

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

Automatically configured SSH to the `eqemu-server` with automatically generated 30+ character password, persistent keys through reboot; default port is 2222

## Cron Jobs

Cronjob support has been added into the `eqemu-server` service; you can add / edit crons and they persist through reboots. Simply start by editing the crontab.cron file

```
eqemu@12a1e5add2b9:~$ cat ~/assets/cron/crontab.cron
# * * * * *  echo "example" >> /home/eqemu/server/example.txt

# This extra line makes it a valid cron - Don't remove
```

## Startup Scripts

If you want your `eqemu-server` service to fire any particular scripts on container bootup; such as a Discord relay server or any other type of service, you can put the script in the `~/server/startup/*` folder and they will all be ran. Do not try to run EQEmu services here as they are managed by Occulus

## MariaDB

Configurable INNODB_BUFFER_POOL_MEMORY (Default: 256MB) (Must set before make install or rebuild mariadb)

If you are running a production server with a decent amount of players, consider setting this to 512MB or 1GB to avoid page thrashing

If you already ran `make install` simply adjust this value in your `.env` (Uncomment) and rebuild the mariadb container via `docker-compose build mariadb` and restarting the container `docker-compose restart mariadb`

You can validate your buffer pool value  what you set in the 

### Users

An `eqemu` user is created for the `eqemu-server` server service and only has permissions over the `peq` default database, the root user is also not able to be accessed externally. If you want to restrict the `eqemu` user from external access then you will need to lock that down

```
root@host:/opt/eqemu-servers/peq-test-server# make mysql-list-users
docker-compose exec mariadb bash -c "mysql -uroot -pxxx -h localhost -e 'select user, password, host from mysql.user;'"
WARNING: The DROPBOX_OAUTH_ACCESS_TOKEN variable is not set. Defaulting to a blank string.
+-------------+-------------------------------------------+-----------+
| User        | Password                                  | Host      |
+-------------+-------------------------------------------+-----------+
| mariadb.sys |                                           | localhost |
| root        | *F6CFC46CF35E6BCE3E85D621B308A7940CF8F242 | localhost |
| eqemu       | *A1824B8E01E5C97385C3D93754C444DC23DB3583 | %         |
+-------------+-------------------------------------------+-----------+
```

To create new users; simply log in via the root user using the host-level `make mc` which will give you a direct root shell to create new full or limited users to your hearts content

## PEQ Editor

Automatically configured with pre-set admin password; listens on port 8081 by default

<p align="center"><img src="https://user-images.githubusercontent.com/3319450/87240902-3dcc1980-c3e3-11ea-9d1e-746e217b4459.png"></p>

## PhpMyAdmin

Automatically configured PhpMyAdmin instance with pre-set admin password (Behind a password protected proxy); listens on port 8082 by default

<p align="center"><img src="https://user-images.githubusercontent.com/3319450/87240916-63f1b980-c3e3-11ea-8dd8-93bca87f54ec.png"></p>

<p align="center"><img src="https://user-images.githubusercontent.com/3319450/87240919-6f44e500-c3e3-11ea-8c56-6fe0e5ecef89.png"></p>

## Occulus

Automatically installed server admin panel [Occulus repository](https://github.com/Akkadius/Occulus); listens on port 3000 by default

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

### Initialize Backups

To get started, you need to run the uploader script in the backup-cron container for the first time to initialize your application

As of July 2021 this guide has changed to Dropbox's new auth mechanisms to include more configuration in the OAuth flow.

```
docker-compose exec backup-cron dropbox_uploader.sh
```

Follow the instructions prompted from running the command

```

 This is the first time you run this script, please follow the instructions:

(note: Dropbox will change their API on 2021-09-30.
When using dropbox_uploader.sh configured in the past with the old API, have a look at README.md, before continue.)

 1) Open the following URL in your Browser, and log in using your account: https://www.dropbox.com/developers/apps
 2) Click on "Create App", then select "Choose an API: Scoped Access"
 3) "Choose the type of access you need: App folder"
 4) Enter the "App Name" that you prefer (e.g. MyUploader1167208717053), must be unique

 Now, click on the "Create App" button.

 5) Now the new configuration is opened, switch to tab "permissions" and check "files.metadata.read/write" and "files.content.read/write"
 Now, click on the "Submit" button.

 6) Now to tab "settings" and provide the following information:
 App key: dmz4wbjsnghfkwj
 App secret: iq26gmwnlsnwj48
  Open the following URL in your Browser and allow suggested permissions: https://www.dropbox.com/oauth2/authorize?client_id=dmz4wbjsnghfkwj&token_access_type=offline&response_type=code
 Please provide the access code: Bun8T-9NG2kAAAAAAABF0by79e-VuivtOXRtHkS10KA                                                                                               

 > App key: xxx
 > App secret: 'xxx
 > Access code: 'Bun8T-9NG2kAAAAAAABF0by79e-xxx'. Looks ok? [y/N]: y
   The configuration has been saved.
```

Once you go through the steps of creating your application. Do not forget to set scopes on your app to be able to write and read files. You MUST follow the prompts above in order otherwise you will run into issues.

![image](https://user-images.githubusercontent.com/3319450/174466660-b9db68db-5a3e-4877-b55d-1ceaa249bb6c.png)

![image](https://user-images.githubusercontent.com/3319450/174466869-b06d9170-3fd6-4057-85a6-238b905fc7d8.png)

Your configuration gets written to `.dropbox_uploader` which resides at the root of your deployment. This is a sensitive file and is not to be checked into any sort of version control and is used by the `backup-cron` container

### Validate it Works!

Run `make backup-dropbox-list`

```
make backup-dropbox-list
docker-compose up -d backup-cron
docker-compose exec backup-cron dropbox_uploader.sh list
 > Listing "/"... DONE
```

If it shows `> Listing "/"... DONE` then it is initialized successfully

You can test by running a backup

```
make backup-dropbox-database
docker-compose exec backup-cron ./backup/backup-database.sh
# Dumping database and compressing
peq-06-19-2022.sql
# Uploading database snapshot
 > Uploading "/tmp/peq-06-19-2022.tar.gz" to "/backups/database-snapshots/peq-06-19-2022.tar.gz"... DONE
# Truncating backups/database-snapshots days back 7
# Cleaning up...
```

### Backup Configuration

Backup retention configurable in `.env`

Your deployment name is what your backups will be prepended to when they get uploaded to Dropbox

```
# DEPLOYMENT_NAME=peq-production
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

### Running Backups Manually

Bash into the `backup-cron` service; assuming your OAUTH token is valid and everything works

```
root@host:/opt/eqemu-servers/peq-production# docker-compose exec backup-cron bash
```

```
backup-cron@backup-cron:~$ dropbox_uploader.sh list peq-production
 > Listing "/peq-production"... DONE
 [D]  database-snapshots
 [D]  deployment-backups
 [D]  quest-snapshots
```

**Database Snapshots**

```
backup-cron@backup-cron:~$ dropbox_uploader.sh list peq-production/database-snapshots
 > Listing "/peq-production/database-snapshots"... DONE
 [F] 182189205 peq-07-02-2020.tar.gz
 [F] 182222834 peq-07-03-2020.tar.gz
 [F] 182263995 peq-07-04-2020.tar.gz
 [F] 182300144 peq-07-05-2020.tar.gz
 [F] 182394017 peq-07-06-2020.tar.gz
 [F] 182464528 peq-07-07-2020.tar.gz
 [F] 182465093 peq-07-08-2020.tar.gz
 [F] 182527952 peq-07-09-2020.tar.gz
 [F] 182574977 peq-07-10-2020.tar.gz
 [F] 182566469 peq-07-11-2020.tar.gz
 [F] 182661537 peq-07-12-2020.tar.gz
 ...
```

**Deployment Snapshots**

(Includes entire deployment folder)

```
 backup-cron@backup-cron:~$ dropbox_uploader.sh list peq-production/deployment-backups
 > Listing "/peq-production/deployment-backups"... DONE
 [F] 3309179293 deployment-07-02-2020.tar.gz
 [F] 2357754207 deployment-07-05-2020.tar.gz
 [F] 2364156848 deployment-07-12-2020.tar.gz
 ...
```

***Quest Snapshots***

```
backup-cron@backup-cron:~$ dropbox_uploader.sh list peq-production/quest-snapshots
 > Listing "/peq-production/quest-snapshots"... DONE
 [F] 29464443 quests-07-07-2020.tar.gz
 [F] 29464443 quests-07-08-2020.tar.gz
 [F] 29464443 quests-07-09-2020.tar.gz
 [F] 29464443 quests-07-10-2020.tar.gz
 [F] 29464443 quests-07-11-2020.tar.gz
 [F] 29464443 quests-07-12-2020.tar.gz
 ...
```

## High CPU Process Watchdog

If a zone process goes into an infinite loop; the watchdog will kill the process and log it in the home directory

```
eqemu@f8905f80723c:~$ cat process-kill.log
Sat Jul 11 20:52:47 CDT 2020 [process-watcher] Killed process [21143] [./bin/zone] for taking too much CPU time [43.50]
```

## CPU Share Throttling

To protect the host and the rest of the services running on the box, in the event that someone may be compiling source or trying to maximize all CPU resources, the container is limited

```
root@host:/opt/eqemu-servers/peq-test-server# cat docker-compose.yml | grep shares
    cpu_shares: 900
```

https://docs.docker.com/compose/compose-file/compose-file-v2/#cpu-and-other-resources

https://docs.docker.com/config/containers/resource_constraints/#configure-the-default-cfs-scheduler

# Installation

First clone the repository somewhere on your server, in this case I'm going to clone it to an `/opt/eqemu-servers` folder in a Debian Linux host with Docker installed

```
git clone https://github.com/Akkadius/akk-stack.git peq-test-server
```

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

### Ninja Support

If you want to compile using Ninja instead of traditional make for development; there is support in the container ready to go to compile with Ninja, you just need to configure your build repository to use it

```
eqemu@e5311a8e9505:~$ b
eqemu@e5311a8e9505:~/code/build$ cmake -GNinja -DEQEMU_BUILD_LOGIN=OFF -DEQEMU_BUILD_LUA=ON -DEQEMU_BUILD_PERL=ON -DEQEMU_BUILD_LOGGING=ON ..
-- Boost version: 1.67.0
-- **************************************************
-- * Library Detection                              *
-- **************************************************
-- * MySQL:                                   FOUND *
-- * MariaDB:                                 FOUND *
-- * ZLIB:                                    FOUND *
-- * Lua:                                     FOUND *
...truncated
```

To compile, simply use the `n` keyword anywhere

```
eqemu@e5311a8e9505:~/code/build$ n
ninja: no work to do
```

# Feature Requests

Want a feature that isn't already available? Open an issue with the title "[Feature Request]" and we will see about getting it added

# Contributing

If you want to contribute to the repo, please submit **Pull Requests**

# Pay it Forward

If you use this repository; you're taking advantage of a ton of work that I've done to make the experience incredibly simple for you to use for free - please pay it forward to the community by contributing back
