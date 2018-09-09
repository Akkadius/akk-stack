#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

my %current_values = ();

#################################
# Open current .env
#################################

my $filename = '.env';
if (-e $filename) {
    open(my $fh, '<:encoding(UTF-8)', $filename) or die "Could not open file '$filename' $!";

    while (my $row = <$fh>) {
        if ($row =~ /#/i) {
            next;
        }

        if (trim($row) eq "") {
            next;
        }

        if ($row =~ /=/i) {
            my @values = split("=", $row);
            my $key    = trim($values[0]);
            my $value  = trim($values[1]);

            $current_values{$key} = $value;
        }
    }
}

#################################
# Open template .env
#################################

$filename           = '.env.example';
my $new_file_buffer = "";
if (-e $filename) {
    open(my $fh, '<:encoding(UTF-8)', $filename) or die "Could not open file '$filename' $!";

    while (my $row = <$fh>) {
        if ($row =~ /=/i) {
            my @values = split("=", $row);
            my $key    = trim($values[0]);
            my $value  = trim($values[1]);

            if ($current_values{$key} && $current_values{$key} ne $value) {
                $row =~ s/$value/$current_values{$key}/g;
            }
        }

        $new_file_buffer .= $row;
    }
}

#################################
# Write new config
#################################

open(my $fh, '>', '.env');
print $fh $new_file_buffer;
close $fh;

print "Wrote updated config to [.env]\n";

sub trim {
    my $string = $_[0];
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}
