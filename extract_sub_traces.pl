use v5.10;
# use DDP  ;
use FileProcess qw(update_trans) ;
use warnings;
# Given a certain trace that is extracted from QUOTIENT LTS, and 
# extract its corresponding paths from the ORIGINAL LTS
# Gaoang @ April 24 / 16 

END {
    my $file = $ARGV[0] || 'input/msqueue23.aut';
    my $trans = update_trans(IO::File->new($file, 'r')) ;

    my @todos = map { qr($_) } (
	"CALL \!POP \!1", "CALL \!PUSH \!11 \!2", "RET \!PUSH \!2", "CALL \!PUSH \!12 \!2", 
	"RET \!POP \!11 \!1", "CALL \!POP \!1", "RET \!PUSH \!2", "CALL \!PUSH \!13 \!2", 
	"RET \!POP \!13 \!1", "CALL \!POP \!1", "RET \!POP \!0 \!1") ;
    
    my ($pre, $act, $suc) ;
    my %result_trans ; 
    my %alreay_done ; 
    
    local *extract_lts = sub {
	my ($state, $index) = @_ ; # index stands the current id in todos 
	my $is_legal = 0 ;
	
	if ( exists $alreay_done{$state}{$index} ) { # alreay been processed before
	    #say "alreay_done: " , $state, $index ;
	    return 1 if $alreay_done{$state}{$index} ;
	    return 0 unless $alreay_done{$state}{$index} ;
	}
	
	foreach $suc (keys %{ $trans->{$state} }) {
	    $act = $trans->{$state}{$suc} ;
	    if ( $act =~ /call|ret/i ) {
		if ($act =~ /$todos[$index]/) {
		    if ($index == $#todos){
			$is_legal = 1 ;
			$result_trans{$state}{$suc} = 1 ;
			$alreay_done{$state}{$index} = 1 ;
			next ;
		    } else {
			if( extract_lts->($suc, $index + 1) ) {
			    $is_legal = 1 ;
			    $result_trans{$state}{$suc} = 1 ;
			    $alreay_done{$state}{$index} = 1 ;
			}
		    }
		} else {
		    #$alreay_done{$state}{$index} = 0 ;
		    next ;
		}
	    } else {
		if( extract_lts->($suc, $index) ) {
		    $is_legal = 1 ;
		    $result_trans{$state}{$suc} = 1 ;
		    $alreay_done{$state}{$index} = 1 ;
		}
	    }
	}

	unless ($is_legal)  { $alreay_done{$state}{$index} = 0 ;} 
	
	return $is_legal ;
    } ;

    extract_lts->(0, 0) ;

    ########## filter those legal paths 
    foreach $pre (sort numerically keys %$trans) {
	foreach $suc (sort numerically keys %{ $trans->{$pre} }) {
	    if ( exists $result_trans{$pre}{$suc} ) {
		$act = $trans->{$pre}{$suc}  ;
		say "($pre, $act, $suc)" ;
	    }
	}
    }
    
    #p %result_trans ;
}


sub numerically { $a <=> $b} 
