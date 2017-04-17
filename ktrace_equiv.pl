#!/usr/bin/perl 
use v5.16;
use strict; # use warnings; 
use SetMethods qw(:Both); 
use PreProcess qw(:Both);
use FileProcess qw(original_trace flush_trans); 
use List::Util qw(max first);
use Carp qw(croak carp);
no warnings "experimental::smartmatch"; 


END {
    if (defined $ARGV[2] and $ARGV[1] =~ /^\d+$/ and $ARGV[2] =~ /^\d+$/) {
	inequivalent_traces($ARGV[1], $ARGV[2]);
    } else {
	check_traces_equivalence();
    }
}


croak "Please specify a quotient file first!\n" # Reading a quotient file from command line  
    unless defined $ARGV[0]; 

my $file = $ARGV[0];
my $fh = IO::File->new($file, "r"); # Reading quotient file 
system("mkdir output") unless (-d "output");

$file = (split("/", $ARGV[0]))[-1];
my $wh = IO::File -> new("output/$file", 'w'); 
my $con = " . "; 		
my (%sucs,		      # maps each state to a set of successors
    %trans,		
    %equivalent,	 # whether two states s1 and s2 are equivalent
    %oneTracePrefixes,	 # prefixes for pure traces 
    %prefix_multi,
    );

process_quotient_system($fh);	# 

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



# To decide whether two states (c, d) have same pure traces (in which tau are omitted) set.
# This subroutine increasingly compares whether the two states have the same set of trace
# prefixes that with length up to 'n'. 
sub pure_trace_equiv { 
    my ($c, $d) = (shift, shift);
    if (defined $equivalent{$c}{$d}) {
	return 1 if $equivalent{$c}{$d} >= 1; 
	return 0; 
    }
    
    my $depth = 1; 
    while(1) {
	my $array_c = get_trace_prefixes($c, $depth);
	my $array_d = get_trace_prefixes($d, $depth);
	return 0 unless keys %$array_c ~~ keys %$array_d;
	last unless %$array_c;
	$depth ++ ; 
    }
    
    $equivalent{$c}{$d}  = $equivalent{$d}{$c} = 1; # been here means it was not defined before 
    return 1 ;  
}


# Return for a state a set of trace prefixes with length 'n'. 
sub get_trace_prefixes {		
    my ($state, $length) = (shift, shift);
    my $prefixes = {};		# is an anonymous hash table that stores traces 
    return $oneTracePrefixes{$state}{$length} if defined $oneTracePrefixes{$state}{$length} ; 
    return unless ($sucs{$state} and $length > 0);
    
    foreach my $suc (keys %{$trans{$state}}) {
	my $act = $trans{$state}{$suc};
	if ($act =~ /i/) {
	    map{ $prefixes -> {$_} = 1 } keys %{get_trace_prefixes($suc, $length)};
	} elsif ($length == 1) { 
	    $prefixes -> {$act} = 1; 
	} else{
	    my $suc_pref  = get_trace_prefixes($suc, $length - 1);
	    map{ $prefixes -> {join($con, $act, $_)} = 1 } keys %$suc_pref;
	}
    }

    $oneTracePrefixes{$state}{$length} = $prefixes; 
    return $prefixes; 
}



sub process_quotient_system {  # read file and update %trans and %sucs 
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
      my $ta = get_trace_prefixes($sa, $depth);
      my $tb = get_trace_prefixes($sb, $depth);
      
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
