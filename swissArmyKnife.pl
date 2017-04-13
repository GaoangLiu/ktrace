#
use v5.10 ; 
use strict;
use FileProcess qw(update_trans);

END {
    parser_2327_2325();
    #find_all_traces_from_0_to_($ARGV[1]);
}

sub find_all_traces_from_0_to_ {
    # LTS is given as an ARG 
    # find all traces from 0 to the target state 

    my $self = shift;
    my $gtrans = update_trans( IO::File->new( $ARGV[0], 'r' ) );
    my $legaltrans;
    my $visited;

    is_reachable(0);

    #print Dump($legaltrans);
    FileProcess::flush_trans($legaltrans);
    
    sub is_reachable {
        my $state = shift;
        my $bool  = 0;
	
        if ( defined $visited->{$state} ) {
            return 1 if $visited->{$state} == 99;    # is reachable ;
            return 0;
        }

        if ( defined $gtrans->{$state}{$self} ) {
            $legaltrans->{$state}{$self} = $gtrans->{$state}{$self};
            $visited->{$state} = 99;
            return 1;
        }

        foreach my $suc ( keys %{ $gtrans->{$state} } ) {
            if ( is_reachable($suc) ) {
                $legaltrans->{$state}{$suc} = $gtrans->{$state}{$suc};
                $visited->{$state}          = 99;
                $bool                       = 1;
            }
        }

        unless ($bool) { $visited->{$state} = -1 }
        return $bool;
    }

}

sub parser_2327_2325 {

    open my $classa, '<', 'output/1962_class.txt';
    open my $classb, '<', 'output/1960_class.txt';

    my $statesa = decompose_class($classa);
    my $statesb = decompose_class($classb);
    my $gtrans  = update_trans( IO::File->new( "input/lfs/lfs23big.aut", 'r' ) );

    map { shift @$_ } ( $statesa, $statesb );

    foreach my $i (@$statesa) {
        foreach my $j (@$statesb) {
            my $act = $gtrans->{$i}{$j};
            print "\t $i, $act, $j \n" if defined $act;
        }
    }
}

# ---------------------------------------------------------------------------------------------------

sub decompose_class {
    my $rh = shift;
    my $reps;    # array
    while (<$rh>) {
        chomp;
        s/"//g;
        @$reps = grep { /\d+/ } split /\s|=|\{|\}/;
    }
    return $reps;
}



