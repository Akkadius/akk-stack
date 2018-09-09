#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

##################################
# Parse args
##################################

my $arg_variable = $ARGV[0];
my $arg_value    = $ARGV[1];

if (!$arg_variable || !$arg_value) {
    print "$0 variable value\n";
    exit;
}

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

            if ($key eq $arg_variable) {
                $row =~ s/$value/$arg_value/g;
            }
        }

        $new_file_buffer .= $row;
    }
}

##################################
# Write file changes
##################################

open(my $fh, '>', '.env');
print $fh $new_file_buffer;
close $fh;

print "Wrote [" . $arg_variable . "] = [" . $arg_value . "] to [.env]\n";

sub trim {
    my $string = $_[0];
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}
