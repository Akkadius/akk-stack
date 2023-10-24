#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

my %fields_to_scramble = (
    "MARIADB_ROOT_PASSWORD"  => 1,
    "MARIADB_PASSWORD"       => 1,
    "PHPMYADMIN_PASSWORD"    => 1,
    "SERVER_PASSWORD"        => 1,
    "FTP_QUESTS_PASSWORD"    => 1,
    "SPIRE_ADMIN_PASSWORD"   => 1,
    "PEQ_EDITOR_PASSWORD"    => 1
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

            my $write = 1;
            if ($fields_to_scramble{$key}) {
                my $new_hash = hash();

                if ($ARGV[0] && $ARGV[0] ne $key) {
                    $write = 0;
                }

                if (defined $write && $write == 1) {
                    $row =~ s/$value/$new_hash/g;
                }
            }
        }

        $new_file_buffer .= $row;
    }
}

##################################
# Write env
##################################

open(my $fh, '>', '.env');
print $fh $new_file_buffer;
close $fh;

print "Wrote updated config to [.env]\n";

sub hash
{
    my @alphanumeric    = ('a' .. 'z', 'A' .. 'Z', 0 .. 9);
    my $random_password = join '', map $alphanumeric[rand @alphanumeric], 0 .. 30;
    return $random_password;
}

sub trim
{
    my $string = $_[0];
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}
