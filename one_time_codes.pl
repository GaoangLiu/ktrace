# All the codes in this file can be discarded at will. 
# Gaoang@2016, 05, 12
use Modern::Perl ;
use DDP ;
use Switch; 
use FileProcess qw(update_trans); 

END {
    $SCHEDULER = 0;
    switch ($SCHEDULER) {
	when 1 {		# EXPE 1 
	    
	}
    }

    
    if ($SCHEDULER == 0) {
	# Whether all "tau" transition following 'Call \!ENQ \!1' is 1-trace equivlent
	# Answer: No, only 56 of 501 are 1-trace eqiv .
	my $file  = 'output/read_back.aut';
	my $trans = update_trans(IO::File->new($file, 'r'));
	
	open my $rh, '<', "output/HW_qo_32.aut" or die "Cannot open file : $!";
	my %tmp = ();
	
	while (<$rh>) {
	    chomp;
	    next unless /1\-trace/;
	    my ($pre, $suc) = (split /\s+/)[1 .. 2];
	    $tmp{$pre}{$suc} = undef; 
	}
	       
	foreach my $pre ( sorted_keys($trans) ){
	    foreach my $suc ( sorted_keys($trans->{$pre}) ){
		if (exists $tmp{$pre}{$suc}) {
		    printf "(%-4s, i, %4s)\n", $pre, $suc;
		}
	    }
	}
	    
    }
}


sub numerically { $a <=> $b } 

sub sorted_keys { sort numerically keys %{shift()} } 
