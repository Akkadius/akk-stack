#!/usr/bin/perl

my $dropbox_list_path       = $ARGV[0];
my $truncate_keep_days_back = $ARGV[1];

if (!$dropbox_list_path || !$truncate_keep_days_back) {
    print "Example [list_path] [keep_days_back]\n\n";
}

my $output = `dropbox_uploader.sh list $dropbox_list_path`;
my @lines  = split("\n", $output);
my %files  = ();
foreach my $line (@lines) {
    if ($line =~ /\[F]/i) {
        my @columns     = split(" ", $line);
        my $date_column = trim($columns[2]);
        my @date_split  = split("-", $date_column);
        my $month       = trim($date_split[1]);
        my $day         = trim($date_split[2]);
        my $year        = trim($date_split[3]);
        $year =~ s/.tar.gz//g;

        my $unix_time = trim(`date -d "$year-$month-$day 00:00:00" +%s`);
        $files{$unix_time} = trim($date_column);
    }
}

# print "# Files\n";
my @files_to_truncate = ();
my $index = 0;
foreach my $key (reverse sort keys %files) {
    # print "[" . $key . "] [" . $files{$key} . "]\n";
    if ($index >= $truncate_keep_days_back) {
        push (@files_to_truncate, $files{$key});
    }
    else {
        # print "Not deleting [" . $files{$key} . "] ($index) \n";
    }
    $index++;
}

foreach my $file (@files_to_truncate) {
    print $file . "\n";
}

sub trim {
    my $string = $_[0];
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}
