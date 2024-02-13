#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

my %fields_to_scramble = (
    "MARIADB_ROOT_PASSWORD"      => 1,
    "MARIADB_PASSWORD"           => 1,
    "PHPMYADMIN_PASSWORD"        => 1,
    "PEQ_EDITOR_PROXY_PASSWORD"  => 1,
    "SERVER_PASSWORD"            => 1,
    "FTP_QUESTS_PASSWORD"        => 1,
    "SPIRE_ADMIN_PASSWORD"       => 1,
    "PEQ_EDITOR_PASSWORD"        => 1,
    "TRAEFIK_DASHBOARD_PASSWORD" => 1
);

##################################
# Load .env
##################################

my $filename        = '.env';
my $new_file_buffer = "";
if (-e $filename) {
    open(my $fh, '<:encoding(UTF-8)', $filename) or die "Could not open file '$filename' $!";

    while (my $row = <$fh>) {
        if ($row =~ /=/i) {
            my @values = split("=", $row);
            my $key    = trim($values[0]);
            my $value  = trim($values[1]);
            my $write  = 1;
            if ($fields_to_scramble{$key} && $value =~ /template/i) {
                my $new_hash = hash();
                if ($ARGV[0] && $ARGV[0] ne $key) {
                    $write = 0;
                }

                if (defined $write && $write == 1 && $value eq "<template>") {
                    print "Scrambling [$key]\n";
                    $row =~ s/$value/$new_hash/g;
                } elsif ($value ne "<template>") {
                    print "Skipping [$key] because it was already set\n";
                }
            }

        }

        $new_file_buffer .= $row;
    }
    close $fh;
}

##################################
# second pass - traefik
##################################
my @lines = split /\n/, $new_file_buffer;
my %env   = ();
foreach my $line (@lines) {
    my @values = split("=", $line);
    if (scalar(@values) != 2) {
        next;
    }
    my $key    = trim($values[0]);
    my $value  = trim($values[1]);
    $env{$key} = $value;
}

if ($env{"TRAEFIK_DASHBOARD_PASSWORD"}) {
    my $auth = `docker run -it httpd htpasswd -bBn admin $env{"TRAEFIK_DASHBOARD_PASSWORD"}`;
    $auth    = trim($auth);
    # escape $ with double $$
    $auth =~ s/\$/\$\$/g;

    my $even_newer_file_buffer = "";
    foreach my $line (@lines) {
        if ($line =~ /TRAEFIK_DASHBOARD_AUTH/) {
            my @values = split("=", $line);
            my $key    = trim($values[0]);

            if ($key eq "TRAEFIK_DASHBOARD_AUTH") {
                $line = "TRAEFIK_DASHBOARD_AUTH=$auth";
            }
        }
        $even_newer_file_buffer .= $line . "\n";
    }

    $new_file_buffer = $even_newer_file_buffer;
}

##################################
# Write env
##################################

open(my $fh, '>', '.env');
print $fh $new_file_buffer;
close $fh;

print "Wrote updated config to [.env]\n";

sub hash {
    my @alphanumeric    = ('a' .. 'z', 'A' .. 'Z', 0 .. 9);
    my $random_password = join '', map $alphanumeric[rand @alphanumeric], 0 .. 30;
    return $random_password;
}

sub trim {
    my $string = $_[0];
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}
