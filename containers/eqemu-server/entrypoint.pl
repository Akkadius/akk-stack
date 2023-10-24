#!/usr/bin/perl

#############################################
# vars
#############################################
my $SERVER_PASSWORD   = $ENV{'SERVER_PASSWORD'};
my $EQEMU_DB_PASSWORD = $ENV{'EQEMU_DB_PASSWORD'};
my $server_path       = "/home/eqemu/server";
my $bin_path          = $server_path . "/bin/";
my $SPIRE_PORT        = $ENV{'SPIRE_PORT'};
my $spire_admin       = $bin_path . "/spire";

if (-e "~/server/eqemu_config.json") {
    print "# Creating symlinks\n";
    print `~/assets/scripts/create-symlinks.pl`;
}

if (defined $SERVER_PASSWORD) {
    print "# Updating 'eqemu' user password\n";
    print `sudo usermod --password \$(echo $SERVER_PASSWORD | openssl passwd -1 -stdin) eqemu`;
    print `unset SERVER_PASSWORD`;
}

#############################################
# time
#############################################
print "# Setting timezone\n";
print `sudo rm /etc/localtime`;
print `sudo ln -s /usr/share/zoneinfo/\$TZ /etc/localtime`;

#############################################
# ssh
#############################################
print "# Starting SSH server\n";
print `sudo service ssh restart`;

#############################################
# ulimit
#############################################
print "# Setting ulimit (ulimit -m 1000000 -c 99999999)\n";
print `ulimit -m 1000000 -c 99999999`;

# Rest of operations rely on the file mounts being accessible and initialized...
if (!-d $server_path) {
    print "Server directory [$server_path] not initalized... exiting entrypoint...\n";
    exit;
}

#############################################
# process watcher
#############################################
print "# Starting Process Watcher\n";
print `while true; do nohup ~/assets/scripts/process-watcher.pl && break; done >/dev/null 2>&1 &`;

#########################
# ownership
#########################
print "# chmod/chown | scripts\n";
print `sudo chmod +x ~/assets/scripts/*`;
print `sudo chown eqemu -R ~/.ccache`;

#########################
# bash symlinks
#########################
print "# bash aliases\n";
print `sudo rm -rf ~/.bash_aliases && ln -s ~/assets/bash/.bash_aliases ~/.bash_aliases`;

#########################
# in-container makefile
#########################
print "# Makefile\n";
print `rm -rf ~/Makefile && ln -s ~/assets/scripts/Makefile ~/Makefile`;

#########################
# stored ssh-keys
#########################
print `rm -rf ~/.ssh && ln -s ~/assets/ssh ~/.ssh`;

#########################
# cleanup
#########################
print `rm -rf ~/server/db_update`;
print `rm -rf ~/server/updates_staged`;

#########################
# run startup scripts if exists
#########################
print `cd $server_path && nohup ./startup/* >/dev/null 2>&1 &`;

#########################
# spire-admin
#########################
print "# Starting Spire\n";
print `while ! mysqladmin status -ueqemu -p$EQEMU_DB_PASSWORD -h "mariadb" --silent; do sleep .5; done;`;
print `while true; do cd ~/server/ && nohup ./bin/spire http:serve --port=$SPIRE_PORT >/dev/null 2>&1; sleep 1; done &`;

#############################################
# cron watcher
#############################################
print `while inotifywait -e modify ~/assets/cron/; do bash -c "crontab ~/assets/cron/*; sudo pkill cron; sudo cron -f &"; done >/dev/null 2>&1 &`;
print `crontab ~/assets/cron/*; sudo cron -f &`;
