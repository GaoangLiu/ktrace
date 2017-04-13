# Given an LTS, this will return 
# 1. how many THREADS in it
# 2. how many methods each thread perform 
# 3. the final states (probably more than one)
# 
# -- 
# Gaoang@i, 2015 12 08

use Modern::Perl ; 
use DDP ;  
use FileProcess qw(update_trans); 
use List::Util qw(first max) ; 

END {
    die "No LTS was given" unless defined $ARGV[0];
    say "Size of '$ARGV[0]' is: ", (split /\s+/, qx "du -h $ARGV[0]")[0];
    
    open my $lts, '<', $ARGV[0];
    our $global_trans = update_trans($lts);
    
    thread_info($global_trans); 
    find_final_states($global_trans); 
}

sub thread_info {     # this will dump info (methods) about each thread
    my $loc_trans = shift; 
    my $init = (sort {$a<=>$b} keys %$loc_trans)[0];
    my $traces; 

    while( scalar keys %{ $loc_trans ->{$init} } ){
	my $suc = (keys %{ $loc_trans ->{$init}})[0]; 
	my $act = $loc_trans ->{$init}{$suc}; 
	$act =~ s/"//g;
	
	if ($act =~ /\!(\d+)$/i) {
	    push @{$traces -> {$1}}, $act; 
	}
	
	$init = $suc; 
    }
    
    p $traces;
    print "  The number of threads: ", scalar keys %$traces, "\n";
    print "  Method number for each thread: ", @{$traces->{1}} / 2, "\n"; 
}


sub find_final_states {
    my $loc_trans = shift; 
    my $states_final = {}; 
    # how many STATES and TRANSITIONS we have 
    my %S ;  
    my $ct = 0 ; 

    foreach my $key (keys %$loc_trans) {
	$S{$key} = 1; 
	map {
	    $ct ++ ; 
	    $S{$_} = 1 ; 
	    $states_final -> {$_} ++
		unless scalar keys %{$loc_trans -> {$_}} > 0 
	} keys %{$loc_trans -> {$key}}; 
    }
    
    print "\n  There are ", scalar keys %S, " states, ",  $ct , " transitions"; 
    print "\n  The number of final states is : ", 
    scalar keys %$states_final, "\n", "  and the final states are :\n" ; 
    map {print "< $_ : $states_final->{$_} > "} keys %$states_final;
}
