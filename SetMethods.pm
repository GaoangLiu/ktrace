package SetMethods; 
use v5.16; 
use Exporter; 
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION 	= 1.0; 
@ISA		= qw(Exporter); 
@EXPORT		= (); 
@EXPORT_OK	= qw(set_diff set_compare set_merge);
%EXPORT_TAGS	= (	DEFAULT => [qw(set_diff)], 
			Both	=> [qw(set_diff set_compare set_merge)]);
			
			
			
sub set_compare{  # compare two sets 
    return 0 unless ($#{$_[0]} == $#{$_[1]});   # different length 

    my %h; 
    map{
	$h{$_} = 1;
    }@{$_[0]};
    
    foreach my $item (@{$_[1]}){
	return 0 unless defined($h{$item});
    }
    return 1; 
}



sub set_diff{  # decide the difference of two sets 
    my (%ha, %hb);
    map{$ha{$_} = 1}@{$_[0]};
    map{$hb{$_} = 1}@{$_[1]};
    
    say "\n== Items that are in SET-1 but not in SET-2 are: "; 
    map{say $_ unless defined $hb{$_}}@{$_[0]};
    
    say "\n== Items that are in SET-2 but not in SET-1 are: "; 
    map{say $_ unless defined $ha{$_}}@{$_[1]};

}



sub set_merge{  # merge two sets into one 
    my %h;  my @ary; 
    map{
	$h{$_} = 1;
    }(@{$_[0]}, @{$_[1]});
    
    push @ary, (keys %h);
    return \@ary; 
}


sub say{
    print $_[0]."\n";
}


1; 
