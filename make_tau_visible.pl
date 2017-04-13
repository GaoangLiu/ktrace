use 5.010; 
use strict; 
use List::Util qw(first);
use FileProcess qw(flush_trans); 
# no warnings 'experimental::smartmatch'; 


# ---------------------------------------------------------------------------------------------------
# Replace each tau transition with its real action, this will need the class file and the original LTS
# ---------------------------------------------------------------------------------------------------

my (
    %trans,      # global 
    %real_trans, # tau is replace with real action
    %restore_tau,# store transitions in Qo that correspond to multiple transitions in the original 
    );

die " ** Please specify files < quo.aut, class.aut, original.aut>:" unless defined $ARGV[2]; 
my $quo_lts = $ARGV[0];
_main_();

sub _main_
{
    my $rh         = IO::File -> new($quo_lts, 'r');
    my $rhclass    = IO::File -> new($ARGV[1], 'r');
    my $rhoriginal = IO::File -> new($ARGV[2], 'r');
    
    update_trans(); # cann't removed from here 
    mark_potential_lp($rh, $rhclass, $rhoriginal);
    flush_trans(\%real_trans);
    #p %restore_tau;
}

#----------------------------------------------------------------------------------------------------
# input files: (quotient lts, original lts, and states equivalent class). 
# the quotient lts is traversed to locate all its tau-transitions(or plp: potential LP), and each plp, 
# as represented below by a pair of states, has its corresponding implicit transition(s) stored in hash %potential_lp
#----------------------------------------------------------------------------------------------------
sub mark_potential_lp
{
    my ($rh, $rhclass, $rhoriginal) = (shift, shift, shift);
    
    my (%a, %b);
    while(<$rh>)
    {
	chomp; 
	s/"//g; 
	if(/(\d+), ([a-z]), (\d+)/) # only consider tau transition 
	{
	    $a{$1}{$3} = 1; 
	    $b{$3}{$1} = 1; 
	}
    } 
    
    my (%pres, %sucs);
    while(<$rhclass>)
    {
	chomp; 
	if(/^(\d+)/ and $a{$1}){ # $1 has some successors 
	    map{$pres{$_} = $1} keys %{equiv_states($_)};
	}
	
	if(/^(\d+)/ and $b{$1}){ # $1 has some precusors
	    map{$sucs{$_} = $1} keys %{equiv_states($_)};
	}
    }
    

    while(<$rhoriginal>)
    {
	chomp; 
	s/"|//g;
	s/\r//g; 
	if(/(\d+), (.*), (\d+)/){
	    my($cur_qo, $suc_qo) = ($pres{$1}, $sucs{$3});
	    if($cur_qo and $suc_qo and $a{$cur_qo}{$suc_qo}){
		
		my $vis_act = $real_trans{$cur_qo}{$suc_qo};
		$real_trans{$cur_qo}{$suc_qo} = $2; # update real transitions
		next ;
		
		if ( defined  $vis_act ){
		    next if $vis_act ~~ $2 ;
		    next if $vis_act =~ /cas/i; 
		    
		    my $thisact = $2; 
		    my ($act1, $act2, $act3) = ($1, $2, $3); 
		    $thisact =~ s/\!\d\s//g;
		    $vis_act =~ s/\!\d\s//g;
		    next if $thisact ~~ $vis_act; 

		    push @ { $restore_tau{$cur_qo}{$suc_qo} }, 
		    join (" ", $act1, $act2, $act3) ; 
		    
		    next ;
		    
		    say #":-- this tau may correspond to multipul actions \n",  # else 
		    ":-- represents (pre, suc) = ($cur_qo, $suc_qo)\n", 
		    ":-- action     ", $real_trans{$cur_qo}{$suc_qo}, "\n", 
		    $_, "\n";
		    #exit; 
		} else {
		    push @ { $restore_tau{$cur_qo}{$suc_qo} }, 
		    join (" ", $1, $2, $3) ; 
		}#end_if
	    }#end_if
	}#end_if
    }#end_while
    
    # remove transition with unique transition in original
    foreach my $pre (keys %restore_tau) {
	foreach my $suc (keys %{ $restore_tau{$pre} } ) {  
	    delete $restore_tau{$pre}{$suc} 
	    if 1 == @{ $restore_tau{$pre}{$suc} } 
	}
	delete $restore_tau{$pre} if 0 == keys %{ $restore_tau{$pre} } 
    }

    close $rhoriginal; 
    close $rhclass; 
    close $rh; 
}

# ----------------------------------------------------------------------------------------------------
# update transtions stored in %trans for file $ARGV[0], this is needed in process pure_trace();
# ----------------------------------------------------------------------------------------------------
sub update_trans
{ # it also update real transitions 
    open my$rh, '<', $quo_lts; 
    while(<$rh>){
	chomp; 
	s/"//g; 
	next if /des/;
	if(/(\d+), (.*), (\d+)/){
	    $trans{$1}{$3} = $2 ;
	    $real_trans{$1}{$3} = $2 unless $2 ~~ 'i';
	}
    }
    #map{print "$_ : "; map{print " $_ "} keys %{$trans{$_}}; say "";}sort {$a<=>$b} keys %trans; 
}


sub equiv_states
{ # input file: state equivelent, returned hash: <key: equiv_state lable, value: equiv_state set>
    my $line = shift; 
    my %states; 
    map{
	$states{$_} = 1 if /\d+/;
    }do{
	my @arr = split(/[{=}\s+]/, $line);
	my $head = shift @arr; 
	die "  ** some tau-cycles are found, you might want to remove them first:" if $head =~ /\*/;
	@arr; 
    }; 
    return \%states; 
}



