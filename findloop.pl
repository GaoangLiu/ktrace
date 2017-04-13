# Find whether there exists a state in a given LTS will lead to a loop 
# Gaoang@i, 2015, 12, 21
# Modified Mar 28, 2016

# use Modern::Perl ; 
use v5.16; 
use SetMethods qw(:Both);
use FileProcess qw(update_trans);
use Term::ANSIColor qw(:constants);

die ":--Please specify a file:" unless defined $ARGV[0];
my %trans = %{ update_trans( IO::File->new( $ARGV[0], 'r' ) ) };

# $sorted : stores nodes that has been visited, value == 1 means this state leads to no loop
# value == 2 means it can lead to a loop
my %sorted;
my $loop_cter;

_main_();

if ( defined $ARGV[1] ) {
    find_loop_from(
        $ARGV[1],
        {
            -1       => 1,
            $ARGV[1] => 1,
        }
    );
}

# ---------------------------------------------------------------------------------------------------
sub _main_ {
    my $wloop = IO::File->new( "output/loopstates.txt", 'w' );
    my $mark  = 0 ;

    foreach my $cur ( keys %trans ) {
        if ( findloop( $cur, {} ) ) {
            printf "%9d %15s \n", $cur, " leads to a loop ";
            $wloop->printf( "%9d %15s \n", $cur, " leads to a loop " );
            $mark++;
        }
    }

    say ":... No loop was found " if $mark == 0;
    say ":... $mark loop were found" if $mark > 0;
    close $wloop;
}

# ---------------------------------------------------------------------------------------------------
# when a state '$n' was given, this function will decide whether this state will lead to a loop
# the arg $hash is used to store states that can be visited from state $n

sub findloop {
    my ( $n, $hash ) = ( shift, shift );

    foreach my $item ( sort { $a <=> $b } keys %{ $trans{$n} } ) {
	if ( exists $sorted{$item} ) {
	    next if $sorted{$item} == 1 ;
	    if ( $sorted{$item} == 2 ){
		$sorted{$n} = 2 ;
		return 1 ;
	    }
	}

        if ( exists $hash->{$item} and $hash->{$item} == 1 ) { # this item has been visited before
            map { $sorted{$n} = 2 } keys %$hash;
            return 1;
        }
	
        $hash->{$item} = 1;
        return 1 if findloop( $item, $hash );
    }

    $sorted{$n} = 1;
    return 0;
}

# when a state is specified, return all the traces that with loop from it
sub find_loop_from {
    my ( $n, $hash ) = ( shift, shift );

    foreach my $suc ( keys %{ $trans{$n} } ) {
        my %suc_hash = %$hash;
        my $cter     = $suc_hash{-1};    # key -1 is used as counter;
        if ( defined $suc_hash{$suc} ) { # already visited
            $suc_hash{-1} = $suc;   # kye -1 is now used to store the loop state
            print_loop_trace( \%suc_hash );
        }
        else {
            $suc_hash{$suc} = ++$cter;
            $suc_hash{-1}++;
            find_loop_from( $suc, \%suc_hash );
        }
    }
}

sub print_loop_trace
{ # print a given hash according its values, the value of KEY 0 shall be ignored
    my $loch       = shift;
    my @keys       = sort { $loch->{$a} <=> $loch->{$b} } keys %$loch;
    my $last_state = $loch->{-1};
    my $cur        = shift @keys;
    my $act;

    foreach my $suc (@keys) {
        unless ( $suc == -1 ) {
            $act = $trans{$cur}{$suc};
            $act =~ s/"//g;
            if ( $cur == $last_state ) {
                print BOLD YELLOW "$cur ", RESET;
            }
            else {
                print BOLD BLUE "$cur ", RESET;
            }
            print "$act ";
            $cur = $suc;
        }
        else {
            $act = $trans{$cur}{$last_state};
            $act =~ s/"//g;
            print BOLD BLUE "$cur ", RESET;
            print " $act ";
            print BOLD YELLOW "$last_state", RESET;
        }
    }
    say "\n";
}
