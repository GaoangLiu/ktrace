#!/usr/bin/perl 
use v5.10;
use strict; # use warnings; 
use SetMethods qw(:Both); 
use PreProcess qw(:Both);
use FileProcess qw(original_trace flush_trans); 
use List::Util qw(max first);
use Carp qw(croak carp);
=C
Comments TBW 
=cut 

END {
    if (defined $ARGV[2] and $ARGV[1] =~ /^\d+$/ and $ARGV[2] =~ /^\d+$/) {
	#if(1) {
	inequivalent_traces($ARGV[1], $ARGV[2]);
    } else {
	check_traces_equivalence();
    }
}

# Reading a file from command line  
# die "" unless defined $ARGV[0];
my ($file, $fh, $wh, $con); 
{
    die ">> You may forget to specify a quotient file\n\n" 
	unless defined $ARGV[0]; 

    $file = $ARGV[0];
    $fh = IO::File->new($file, "r"); # Reading quotient file 

    # Create directory 'output/' unless it already exists, 
    # wh: log file which contains info about trace-equivelence and so on.
    unless (-d "output") {
	system("mkdir output");
    }
    
    $file = (split("/", $ARGV[0]))[-1];
    $wh = IO::File -> new("output/$file", 'w'); 
    $con = " . "; 
}


my (%sucs, 
    %trans,
    %equivalent,  # whether two states s1 and s2 are equivalent
    %prefixzero,  # prefix for pure traces 
    %prefix_multi,
    );

do_preprocess($fh);
my $nodesnum	= max(keys %sucs);	# number of nodes

# 0-trace encode $setcode{2}{0} = @zerosets, the 0-trace set (and rank) for state 2 
my %setcode ;				
my $k_bound	= 3;			# maximum k 
my @kcounter	= map{1}(0..$k_bound);


# 'upper' is the upper bound of k you want to figure out 
sub check_traces_equivalence { 
    my @ca = map { 0 } (0 .. $k_bound);
    my $DEBUG_	= 1; 
    my $debug	= $DEBUG_ ? *STDOUT : IO::Null -> new();

    foreach my $i ( sort numerically keys %trans ) {
	foreach my $j ( sort numerically keys %{$trans{$i}} ) {
	    #say "processing <$i, $j>"; 
	    next unless $trans{$i}{$j} =~ /i/ ;

	    if (pure_trace_equiv($i, $j))
	    {
		$ca[0] ++; 
		my $format = "%10d %9d %25s\n"; 
		$wh -> printf( $format, $i, $j, " 1-trace equivalent" ); 
		$debug -> printf( $format, $i, $j, " 1-trace equivalent" );
		my $continue = 2;
		
		while(k_trace_equiv($i, $j, $continue))
		{
		    $wh -> printf( $format, $i, $j, " $continue-trace equivalent" ); 
		    $debug -> printf( $format, $i, $j, " $continue-trace equivalent" );
		    $ca[$continue-1] ++ ;
		    last if $continue ++ > $k_bound; 
		}
	    }
	}
    }

    my $info_x = join("", map{ $_ <= $k_bound ? $_.", " : $_ }(1 .. $k_bound+1));
    my $info_t = join("", map{ $_ == $k_bound ? $ca[$_] : $ca[$_].", "}(0 .. $k_bound));
    my $msg = join("", "\t(", $info_x, ")_equiv = (", $info_t, ")\n");
    print $wh $msg; 
    print STDOUT $msg; 
    print STDOUT "\t__END__\n"; 
}


# SUBROUTINES
sub k_trace_equiv {
    my ($c, $d, $k) = (shift, shift, shift); 
    if (defined $equivalent{$c}{$d}) {
	return 1 if $equivalent{$c}{$d} >= $k; 
	return 0 if $equivalent{$c}{$d} <= $k - 2; 
    }

    return pure_trace_equiv($c, $d) if $k <= 1; 
    $k --; 

    my $dep = 1; 
    while(1) {
	my $array_c = prefix_k_trace($c, $dep, $k);
	my $array_d = prefix_k_trace($d, $dep, $k);
	return 0 unless (keys %{$array_c} ~~ keys %{$array_d}); 
	last unless (%{$array_c});
	$dep ++ ; 
    }
    $equivalent{$c}{$d}  = $equivalent{$d}{$c} = $k + 1; # been here means it's not defined 
    return 1 ;   # since c, d equiv, 0 is useless here. 
}


sub prefix_k_trace {
    my ($n, $len, $k) = (shift, shift, shift); 
    defined $prefix_multi{$k}{$n}{$len} and return $prefix_multi{$k}{$n}{$len};
    trace_set_encoding($n, $k) unless defined $setcode{$n}{$k};
    
    my $cur_pref = {} ; 
    return $cur_pref unless $sucs{$n} and $len > 0;
    
    foreach my$suc (keys %{$trans{$n}}) {
	my $act = $trans{$n}->{$suc};     # action
	trace_set_encoding($suc, $k) unless defined $setcode{$suc}{$k}; 

	if ($act =~ /i/ and $setcode{$n}{$k} == $setcode{$suc}{$k}) {
	    map{ 
		$cur_pref -> {$_} = 1;
	    }keys %{prefix_k_trace($suc, $len, $k)};
	} elsif ($len == 1) {
	    my $this_trace = join($con, $setcode{$n}{$k}, $act, $setcode{$suc}{$k});
	    $cur_pref -> {$this_trace} = 1; 
	    next;
	} else {
	    my $suc_pref  = prefix_k_trace($suc, $len - 1, $k);
	    map{ 
		$cur_pref -> {join($con, $setcode{$n}{$k}, $act, $_)} = 1
	    } keys %$suc_pref;
	}
    }

    $prefix_multi{$k}{$n}{$len} = $cur_pref; 
    return $cur_pref; 
}

sub trace_set_encoding {  # encode the traces into number which is stored in setcode  
    my ($s, $k) = (shift, shift);  
    die "\t Enter a key:" unless defined $k;
    die '\t unexpected k-value( == 0)' if $k == 0;

    if ( exists $setcode{$s}{$k} and $setcode{$s}{$k} > 0) {
	return 1
    }
    
    foreach my $key(keys %setcode) {
	next if		$key == $s; 
	next unless	defined $setcode{$key}{$k};
	next unless	k_trace_equiv($s, $key, $k);  # k-trace equiv
	$setcode{$s}{$k} = $setcode{$key}{$k}; 
	return 1; 
    }

    $setcode{$s}{$k} = $kcounter[$k] ++; 
    return 1; 
}



# whether two states (c, d) have same pure traces set 
sub pure_trace_equiv { 
    my ($c, $d) = (shift, shift);
    if (defined $equivalent{$c}{$d}) {
	return 1 if $equivalent{$c}{$d} >= 1; 
	return 0; 
    }
    
    my $dep = 1; 
    while(1) {
	my $array_c = prefix_trace($c, $dep);
	my $array_d = prefix_trace($d, $dep);
	return 0 unless keys %$array_c ~~ keys %$array_d;
	last unless %$array_c;
	$dep ++ ; 
    }
    
    $equivalent{$c}{$d}  = $equivalent{$d}{$c} = 1; # been here means it's not defined 
    return 1 ;   # since c, d equiv, 0 is useless here. 
}


sub prefix_trace {		# for 0-trace only 
    my	($n, $len) = (shift, shift);
    return $prefixzero{$n}{$len} if defined $prefixzero{$n}{$len} ; 
    
    my	$cur_pref = {};		# prefix set for this node $n;
    return $cur_pref unless $sucs{$n} and $len > 0;

    foreach my $suc (keys %{$trans{$n}}) {
	my $act = $trans{$n}{$suc};     # action
	if ($act =~ /i/) {
	    map{ $cur_pref -> {$_} = 1 } keys %{prefix_trace($suc, $len)};
	} elsif ($len == 1) { # doesn't matterh what suc may be 
	    $cur_pref -> {$act} = 1; 
	    next; 
	} else{
	    my $suc_pref  = prefix_trace($suc, $len - 1);
	    map{ $cur_pref -> {join($con, $act, $_)} = 1 } keys %$suc_pref;
	}
    }

    $prefixzero{$n}{$len} = $cur_pref; 
    return $cur_pref; 
}



sub do_preprocess {  # read file and update %trans and %sucs 
    my $file = shift; 
    my ($trans_num, $tau_num) = (0, 0); 
    my $states_counter; 

    while(<$file>) {
	chomp ;
	s/"//g ;
	next if /des/ ;
	
	if (/(\d+), (.*), (\d+)/) {
	    $trans{$1}{$3} = $2; 
	    push @{$sucs{$1}}, $3;
	    map{ $states_counter -> {$_} = 1 }($1, $3);
	    $tau_num ++ if $2 ~~ 'i'; 
	} else{
	    croak(" == MISS ! CHECK YOUR INPUT ==:") ;  
	}
	$trans_num ++; 
    }
    my $n = scalar keys %$states_counter; 
    $wh -> say("States: $n") ;
    $wh -> print("Tau trans: $tau_num\n");
    $wh -> print("Transitions: $trans_num\n");
}

# --------------------------------------------------------------------------------
# Given two states, if they are not 1-trace equivalent, this subroutine find one of
# the shortest inequivalent traces and transition graph that contains the trace 
sub inequivalent_traces {
    my ($sa, $sb) = @_; 
    my $depth = 1;
    
  L:while ('TRUE') {		
      my $ta = prefix_trace($sa, $depth);
      my $tb = prefix_trace($sb, $depth);
      
      if ($ta ~~ $tb) {
	  last unless %$ta; 
	  $depth ++;
	  next;
      } else {		# Find an  
	  say "Find an inequivalent trace with length: $depth \nThe trace is: ";
	  delete @{$ta}{ keys %$tb };
	  
	  for (keys %$ta) {
	      say "\t ($sa) $_ (..) \n";
	      my %all_traces = original_trace($sa, $_, \%trans);
	      say "The sub-LTS that leads to this trace is : "; 
	      flush_trans(\%all_traces);

	      say "\nThe path (with tau transition) is: ";
	      print_counterexample($sa, \%all_traces);
	      last L;		# break out WHILE loop
	  }
      }
  }
}

sub print_counterexample {	# We assume counterexamples are stored in 'thisTrans'
    my ($state, $thisTrans) = @_;
    while (defined $thisTrans->{$state}) {
	my $suc = (keys %{$thisTrans->{$state}})[0];
	my $act = $thisTrans->{$state}{$suc};
	print "{$state}  $act  ";
	$state = $suc; 
    }
    print "{$state} \n"
}

sub numerically {$a<=>$b}
__END__ 
