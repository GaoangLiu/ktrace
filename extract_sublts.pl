# Given an LTS of size T x N (msqueue 2 x 5, for example), 'Thread Num' TN <= T and 'Method Num' mn <= N, 
# the algorithm returns a sub-LTS with size TN x N 
#

use Modern::Perl ;
use DDP deparse => 1, sort_keys => 0 ;
use FileProcess qw(update_trans flush_trans_to_file) ;
use Switch ;
use File::Copy; 

END {
    my @files = (#'input/msqueue23.aut', 
		 #'input/msqueue25.aut', 
		 #'input/msqueue32.aut', 
		 #'input/msqueue28_withNoEnqArgs.aut'
		 'input/treiber/qo_2_6.aut',
		 'input/treiber/qo_3_6.aut',
	);
    
    
    for my $f (@files) {
	my $trans  = update_trans( IO::File->new($f, 'r' )) ;
	my $opName = (split /[\/.]/, $f)[-2];
	
	truncate_lts('TN' => 2, 'MN' => 8, 'TRANS' => $trans) ;
	#move("output/sub", "output/$opName") ;
	system("perl produce_lts.pl output/sub") ;
	move("output/sub_lts.aut", "output/$opName.aut") ;
	
	my $print = qx "head output/$opName.aut" ;
	say $print ;
    }
}

sub truncate_lts {
    my %self = @_ ; 
    my ($tn, $mn) = @self{('TN', 'MN')} ; 	# Represents Thread Number and Method Number for sub-LTS
    my %trans = %{$self{'TRANS'}} ;		# Represents transition
    say " Thread Number := $tn, Method Number := $mn " ;

    my @todos	= (0) ; 	# Assume 0 is the initial state 
    my %done	= () ;		# Recording states that have been visited before 
    my %trans_copy ;
    my ($pre, $act, $suc) ;

    # The first thing we do is removing transitions with unwanted thread ID. And 
    # since we assume the transition system is symmetric, we drop transitions of 
    # threads whose ID are larger than $tn

    while (@todos) {
	$pre = pop @todos ;
	
	next if exists $done{$pre} ;
	$done{$pre} = undef ;
	
	foreach $suc (keys %{ $trans{$pre} }) {
	    $act = $trans{$pre}{$suc} ;
	    
	    switch ($act) 
	    {
		case /\!(\d+)$/ 
		{
		    if ($act =~ /\!(\d+)$/ and $1 <= $tn) {
			$trans_copy{$pre}{$suc} = $act ;
			push @todos, $suc ; 
		    }		# else do nothing
		}
		case 'i'
		{
		    # The action could be TAU, in which case we don't know what its thread ID is, 
		    # therefore, we assume its ID is smaller than $tn 
		    $trans_copy{$pre}{$suc} = $act ;
		    push @todos, $suc ;
		}
		# die "Failed to grasp thread ID" ;
	    }	       
	}
    }

    
    # Now we will truncate traces whose 'Method Number' is larger than $mn, the function 'inner' 
    # recursively pairs each state with a string (or undef, as been stored in HASH %image) that 
    # indicates whethere this state can (or can't) occur in a well-formed trace and by well-formed
    # we mean: 
    #  1. this trace is completed, i.e., with no pending calls
    #  2. every ret action in it has a corresponding call action and 
    #  3. the number of call/ret action in each trace is NO MORE than $mn
    #
    # As always we assume the initial state is 0 .
    
    undef %trans ;
    my %image	= ()  ;			
    
    local *inner = sub {
	my ($self, $call_num, $ret_num) = @_ ;
	
	# indicating whether there is a 'well-formed' trace from state s 
	my $bool = 0  ;		
	# say " ($self, $call_num, $ret_num) " ;
	
	if (exists $image{ $self }) {
	    return 1 if $image{$self} eq join('_', $call_num, $ret_num) ;
	    return 0 ; 		# return FALSE otherwise 
	}
	
	foreach $suc ( keys %{ $trans_copy{$self} } ) {
	    my $locact = $trans_copy{$self}{$suc} ;
	    switch ($locact) {
		case /call/i 
		{
		    if ($call_num == 0) {
			# in this case, no legal trace can be generated from $suc
			$image{$suc} = undef ;
		    } 
		    elsif ($call_num > 0) { 
			if ( inner($suc, $call_num - 1, $ret_num) ) {
			    $bool = 1 ;
			    $trans{$self}{$suc} = $locact ;
			}
		    } # The case when 'call_num < 0' is impossible and therefore ignored
		}
		
		case /ret/i 
		{
		    if ($ret_num == 1) {
			if ($call_num == 0) {
			    $image{$suc} = '0_0' ;
			    $image{$self} = '0_1' ;
			    $trans{$self}{$suc} = $locact;
			    $bool = 1 ;
			} # Other cases, i.e., call_num > ret_num is impossible
		    } 
		    elsif ($ret_num > 1) {
			if ( inner($suc, $call_num, $ret_num - 1) ) {
			    $bool = 1 ;
			    $trans{$self}{$suc} = $locact ;
			}
		    } # The case that 'ret_num <= 0' is impossible and therefore ignored
		}
		
		case "i" 
		{
		    if ( inner($suc, $call_num, $ret_num) ) {
			$bool = 1 ;
			$trans{$self}{$suc} = $locact ;
		    }
		}
	    }			# End of switch 
	}			# End of for loop 

	if ($bool) {
	    $image{$self} = join('_', $call_num, $ret_num) ;
	} else {
	    $image{$self} = undef ;
	}
	
	return $bool ;
    } ; 

    inner(0, $mn, $mn) ;
    # open my $wh, '>', "output/sublts.dat" or die "$!" ;
    flush_trans_to_file(\%trans, IO::File->new("output/sub", 'w')) ;
}

