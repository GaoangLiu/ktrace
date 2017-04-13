#!/usr/bin/perl 
# TODO : find whether each tau has a confluence with other methods 
# ... 
# Created by Gaoang@i, 2016/01/28 
use autodie ; 
use Data::Printer ; 
use FileProcess qw(update_trans) ; 
use Modern::Perl '2014' ; 


sub has_confluence { 
    # the input file should has no invisible tau transition 
    open my $fh, '<',  shift || die "No file was specified ", $! ; 
    my $gtrans = update_trans($fh) ; 

    my $find_all_possible_sinks ;
    $find_all_possible_sinks = sub {
	# find all possible sinks from the current state 
	my $state = shift ; 
	my $href ; 
	#say "The current number is $state >> " ;

	foreach my $suc ( keys %{$gtrans->{$state}} ) {
	    my $act = $gtrans->{$state}{$suc} ; 
	    my ($tid, $met) ; 

	    if ($act =~ /(.*?) \!(?<m>\w+) .* \!(?<tid>\d+)$/x) { 
		my ($tid, $met) = ($+{tid}, $+{m}) ; 
		push @{ $href->{$tid}{$met} }, $suc ; 
		
		my $continue = 1 ; 
	      WHILE: while ($continue) { 
		  $continue = 0 ; # break while if no transition for the same thread 
		  foreach ( keys %{$gtrans->{$suc}} ) { 
		      my $x_suc = $_ ; 
		      $act = $gtrans->{$suc}{$x_suc} ; 
		      
		      if ($act =~ /\!($tid)$/) { 
			  next WHILE if $act =~ /call/i ;     # we shall not start a new method 
			  push @{ $href->{$tid}{$met} }, $x_suc ;
			  $continue = 1 ; 
			  $suc = $x_suc ;
			  if ( $act =~ /^ret \!(\w+)/i) {
			      my $m_name = $1 ; 
			      my $arr = $href->{$tid}{$met} ; 
			      delete $href->{$tid}{$met} ; 
			      $href->{$tid}{$m_name} = $arr ; 
			  }
			  #last if $act =~ /ret/i ; # this is the end of a method 
			  next WHILE 
		      }#if 
		  }#foreach 
	      }#while 
	    } else { 
		die "Something is wrong. The regrex doesn't catch anything" ;
	    }#if 
	}#foreach 
	return $href 
    };
    #p $gtrans ;

    foreach my $pre ( sort{$a<=>$b} keys %$gtrans ) {
	foreach my $suc ( keys %{$gtrans->{$pre}} ) {
	    my $act = $gtrans->{$pre}{$suc} ; 
	    next if $act =~ /call|ret/i ;  # we're only interested in tau trans
	    
	    my $sink_pre = &$find_all_possible_sinks($pre) ;
	    my $sink_suc = &$find_all_possible_sinks($suc) ;
	    
	    my $this_id = $1 if $act =~ /\!(\d+)$/ ;
	    my $mark = 0 ; 

	  SAME_SINK: foreach my $tid ( keys %$sink_pre ) {
	      next if $tid == $this_id ;
	      next unless exists $sink_suc->{$tid} ; # thread id should be the same 
	      
	      foreach my $method ( keys %{$sink_pre->{$tid}} ) {
		  next unless exists $sink_suc->{$tid}{$method} ;
		  my %x_hash = map {$_, 42} @{ $sink_pre->{$tid}{$method} } ;
		  map { 
		      if (exists $x_hash{$_} ){
			  $mark = 1 ;
			  #p %x_hash ; 
			  #p $sink_pre->{$tid} ; 
			  #p $sink_suc->{$tid} ; 
			  #exit ; 
			  last SAME_SINK 
		      }
		  } @{ $sink_suc->{$tid}{$method} } ;
	      }#foreach 		
	  }
	  
	    
	    #"No same sink was found for states " , 
	    if (0 == $mark) { 
		printf "%5d  %5d  %-20s \n", $pre, $suc, $act ;
	    }

	    if (0) {
		use YAML ; 
		print Dump $sink_pre ;
		say "------------------------cut line" ;
		print Dump $sink_suc ;
		exit 
		#say "$pre / $suc / $act" 
	    }
	}
    }#foreach 
}

sub main {
    has_confluence($ARGV[0]) ;
}


main() if 1 
