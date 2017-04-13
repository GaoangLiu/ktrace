# Given an LTS, this will return
# 1. how many THREADS in it
# 2. how many methods each thread perform
# 3. the final states (probably more than one)
#
# --
# Gaoang@i, 2015 12 08

use v5.18;
use autodie;
use strict;
use YAML;
use Data::Printer;
use FileProcess qw(update_trans);
use List::Util qw(first max) ;


die ":--No LTS was given" unless defined $ARGV[0];
open my $lts, '<', $ARGV[0];
my $global_trans = update_trans($lts);
thread_info($global_trans);
find_final_states($global_trans);

sub thread_info {    # this will dump info (methods) about each thread
    my $loc_trans = shift;
    my $init = ( sort { $a <=> $b } keys %$loc_trans )[0];
    my $loc_threads;

    while ( scalar keys %{ $loc_trans->{$init} } ) {
        my $suc = ( keys %{ $loc_trans->{$init} } )[0];
        my $act = $loc_trans->{$init}{$suc};
        $act =~ s/"//g;
        if ( $act =~ /(?:call|ret).*?(\d+)? \!(\d+)$/i ) {

            #say "$1, $2, $act";
            if ( $1 < 3 and $1 > 0 ) {
                push @{ $loc_threads->{$1} }, $act;
            }
            elsif ( $2 < 3 and $2 > 0 ) {
                push @{ $loc_threads->{$2} }, $act;
            }
            else {
                die "Die: don't match any cases.";
            }
        }
        $init = $suc;
    }
    print Dump($loc_threads);
}


sub find_final_states {
    my $loc_trans    = shift;
    my $states_final = {};

    foreach my $key ( keys %$loc_trans ) {
        map {
            $states_final->{$_}++
              unless scalar keys %{ $loc_trans->{$_} } > 0
        } keys %{ $loc_trans->{$key} };
    }

    print "\n  the number of final states : ",
      scalar keys %$states_final, "\n", "  and they are :\n";
    print Dump($states_final);
}
