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
| peq-editor | (Optional) PhpMyAdmin which is automatically configured behind a password proxy |
| ftp-quests | (Optional) An FTP instance fully ready to be used to remotely edit quests |
| backup-cron | (Optional) A container built to automatically backup (Dropbox API) the entire deployment and perform database and quest snapshots for with different retention schedules defined in `.env` |

# Features

## Very easy to use CLI menus

Embedded server management CLI (What is used a majority of the time)

<p align="center"><img src="https://user-images.githubusercontent.com/3319450/87240603-7c140980-c3e0-11ea-9e92-ce18edcfad29.gif"></p>

A `make` menu to manage the in-container environment

<p align="center"><img src="https://user-images.githubusercontent.com/3319450/87240694-779c2080-c3e1-11ea-8330-26d8add10e5f.gif"></p>

A `make` menu to manage the host-level container environment

<p align="center"><img src="https://user-images.githubusercontent.com/3319450/87240726-bfbb4300-c3e1-11ea-80ac-e53bfa3386f4.gif"></p>

* SSH
  * Automatically configured SSH to the `eqemu-server` with automatically generated 30+ character password
  * Persistent keys through reboot
* Configurable INNODB_BUFFER_POOL_MEMORY (Default: 256MB) (Must set before make install or rebuild mariadb)
* PEQ Editor
* PhpMyAdmin (Password Protected)
* [Occulus](https://github.com/Akkadius/eqemu-web-admin) Automatically installed server admin panel
* Symlinked resources
  * Server binaries - Never need to copy binaries after a compile
  * Patch files
  * Quests
  * Plugins 
  * LUA Modules


## File Structure

```
eqemu@f8b74a38cd62:~$ ls -l
total 12
lrwxrwxrwx  1 eqemu eqemu   35 Jul 12 00:34 Makefile -> /home/eqemu/assets/scripts/Makefile
drwxr-xr-x  6 eqemu eqemu 4096 Jul 12 00:10 assets
drwxr-xr-x 22 eqemu eqemu 4096 Jul 12 00:28 code
drwxr-xr-x  9 eqemu eqemu 4096 Jul 12 00:34 server
eqemu@f8b74a38cd62:~$ ls -l server
total 172
drwxr-xr-x   4 eqemu eqemu   4096 Jul 12 00:19 assets
drwxr-xr-x   2 eqemu eqemu   4096 Jul 12 00:34 bin
-rw-r--r--   1 eqemu eqemu   1606 Jul 12 00:34 eqemu_config.json
-rwxr-xr-x   1 eqemu eqemu 103551 Jul 12 00:27 eqemu_server.pl
-rw-r--r--   1 eqemu eqemu    792 Jul 12 00:34 login.json
drwxr-xr-x   3 eqemu eqemu   4096 Jul 12 00:34 logs
lrwxrwxrwx   1 eqemu eqemu     38 Jul 12 00:33 lua_modules -> /home/eqemu/server/quests/lua_modules/
drwxr-xr-x   8 eqemu eqemu   4096 May 25 03:01 maps
lrwxrwxrwx   1 eqemu eqemu     34 Jul 12 00:33 plugins -> /home/eqemu/server/quests/plugins/
drwxr-xr-x 273 eqemu eqemu  12288 Jul 12 00:19 quests
-rw-r--r--   1 eqemu eqemu   5879 Jul 12 00:34 server_launcher.pl
-rwxr-xr-x   1 eqemu eqemu    264 Jul 12 00:34 server_start.sh
-rwxr-xr-x   1 eqemu eqemu    265 Jul 12 00:34 server_start_dev.sh
-rwxr-xr-x   1 eqemu eqemu     61 Jul 12 00:34 server_status.sh
-rwxr-xr-x   1 eqemu eqemu     55 Jul 12 00:34 server_stop.sh
drwxr-xr-x   2 eqemu eqemu   4096 Jul 12 00:34 shared
drwxr-xr-x   2 eqemu eqemu   4096 Jul 12 00:34 updates_staged
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

1) The IP Addres we're going to use
2) The zone port range we're going to use

Make sure that you only open as many ports as you need on the zone end, because `docker-proxy` will NAT all ports individually in its own docker userland which does take some time when starting and shutting off containers. The more ports you nail up, the longer it takes to start / stop. Since this is a test server, I'm only going to use 30 ports. This `make` command also drives the `eqemu_config.json` port and address parameters as well automatically for you

```
root@host:/opt/eqemu-servers# make set-vars port-range-high=7030 ip-address=66.70.153.122
Wrote [IP_ADDRESS] = [66.70.153.122] to [.env]
Wrote [PORT_RANGE_HIGH] = [7030] to [.env]
```

# Install

From this point you're ready to run the fully automated install with a simple `make install`

<p align="center"><img src="https://user-images.githubusercontent.com/3319450/87240353-7289a200-c3de-11ea-8afe-1b0a5ad8400e.gif"></p>
  
  
  
