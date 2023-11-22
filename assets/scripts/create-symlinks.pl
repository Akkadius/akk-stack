#!/usr/bin/perl

#########################################
# load config
#########################################
use JSON;
my $json = new JSON();

my $content;
open(my $fh, '<', "/home/eqemu/server/eqemu_config.json") or die "[create-symlinks] cannot open config file [$filename]"; {
    local $/;
    $content = <$fh>;
}
close($fh);

my $config = $json->decode($content);

#########################################
# paths
#########################################
my $code_path                = "/home/eqemu/code/";
my $patches_source_path      = $code_path . "utils/patches";
my $binary_path              = "/home/eqemu/code/build/bin";
my $server_path              = "/home/eqemu/server";
my $patches_server_directory = $server_path . "/" . $config->{"server"}{"directories"}{"patches"};
my $opcodes_server_directory = $server_path . "/" . $config->{"server"}{"directories"}{"opcodes"};

#########################################
# server binaries
#########################################
opendir(DH, $binary_path);
my @files = readdir(DH);

my @binaries = (
    "export_client_files",
    "import_client_files",
    "loginserver",
    "queryserv",
    "shared_memory",
    "ucs",
    "world",
    "zone",
);

foreach my $bin (@binaries) {
    my $source = $binary_path . "/" . $bin;
    my $target = $server_path . "/bin/" . $bin;
    print "\tSymlinking Source: " . $source . " Target: " . $target . "\n";
    print `ln -s -f $source $target`
}

#########################################
# patches
#########################################
print "# Symlinking patches\n";

opendir(DH, $patches_source_path);
@files = readdir(DH);

foreach my $file (@files) {
    my $source = $patches_source_path . "/" . $file;
    my $target = $patches_server_directory . $file;
    next if (substr($file, 0, 1) eq ".");
    next if (substr($file, 0, 2) eq "..");
    next if $file !~ /patch/i;
    print "\tSymlinking Source: " . $source . " Target: " . $target . "\n";
    print `ln -s -f $source $target`
}

#########################################
# opcodes
#########################################
print "# Symlinking opcodes\n";

opendir(DH, $patches_source_path);
@files = readdir(DH);

foreach my $file (@files) {
    my $source = $patches_source_path . "/" . $file;
    my $target = $opcodes_server_directory . $file;
    next if (substr($file, 0, 1) eq ".");
    next if (substr($file, 0, 2) eq "..");
    next if $file !~ /opcodes/i;
    print "\tSymlinking Source: " . $source . " Target: " . $target . "\n";
    print `ln -s -f $source $target`
}

#########################################
# plugins
#########################################
print "# Symlinking plugins\n";
print "\tSymlinking Source: $server_path/quests/plugins/ Target: $server_path\n";
print `rm $server_path/plugins; ln -s $server_path/quests/plugins/ $server_path`;

#########################################
# lua_modules
#########################################
print "# Symlinking lua_modules\n";
print "\tSymlinking Source: $server_path/quests/lua_modules/ Target: $server_path\n";
print `rm $server_path/lua_modules; ln -s $server_path/quests/lua_modules/ $server_path`;
