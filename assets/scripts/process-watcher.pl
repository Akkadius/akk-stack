#!/usr/bin/perl

###############################
# Kills runaway processes
###############################

use strict;
use warnings FATAL => 'all';

my $seconds_before_kill = 60;
my $cpu_threshold       = 30;
my %threshold_data      = ();

while (1) {
    my $process_list = `ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10`;
    my @processes    = split("\n", $process_list);

    foreach my $process (@processes) {
        my @process_data = split(" ", $process);

        if ($process =~ /gcc|mysql|wget|unzip|node|go-build/i) {
            next;
        }

        if ($process_data[0] =~ /cpu/i) {
            next;
        }

        my $cpu = sprintf '%.2f', trim($process_data[0]);
        my $pid = trim($process_data[1]);
        my $cmd = trim($process_data[3]);

        if ($cpu > $cpu_threshold) {
            if (!$threshold_data{$pid}) {
                $threshold_data{$pid} = time() + $seconds_before_kill;
            }

            if ($threshold_data{$pid} <= time()) {
                print "Time to kill [" . $pid . "]\n";

                system("echo \$(date) '[process-watcher] Killed process [$pid] [$cmd] for taking too much CPU time [$cpu]' >> ~/process-kill.log");
                system("sudo kill -9 " . $pid);
            }

            print $cpu . " -- " . $pid . "\n";
        }
        else {
            $threshold_data{$pid} = undef;
        }
    }

    sleep(5);
}

sub trim {
    my $string = $_[0];
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}
