package FileProcess ;
use v5.16; 
use Carp qw(croak carp) ; 
use Exporter ;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.0;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(update_trans flush_trans flush_trans_to_file original_trace);
%EXPORT_TAGS = (
    DEFAULT => [qw(update_trans)],
    Both    => [qw(update_trans flush_trans)]
    );

# ---------------------------------------------------------------------------------------------------
# The input arg $self must be a file handler, this function will read the handler and store transtions to
# an anonymous hash "$trans" and then return it
#
# -- Dec 05 2015 Gaoang@i

sub update_trans {
    my $self = shift;
    croak " Forgot to specify a file:" unless defined $self;
    my $trans;

    while (<$self>) {
        next if /des/;
	s/"//g; 
        if (/(\d+), (.*), (\d+)/) {
            $trans->{$1}{$3} = $2 ;
        } else {
	    croak "Not a legal transition" ;
        }
    }
    close $self;
    return $trans;
}

# Given a transtion "$trans", this function will write its contents to a file that is handled by $outfh.
# The 3rd argument "$hide_tau" (defalut is 0) is used to hide inner actions when its value is 1, 
# that is all actions expect 'CALL', 'RET' will be replaced by 'i' 
# modified May 12, 2015  Gaoang@i

sub flush_trans_to_file {
    my ($trans, $outfh, $hide_tau) = defined $_[2] ? @_ : (@_, 0) ;
    my ($pre, $act, $suc)  ;
    
    foreach $pre ( sort numeracally keys %$trans ) {
	foreach $suc ( sort numeracally keys %{ $trans->{$pre} }) {
	    $act = $trans->{$pre}{$suc};
            $act =~ s/"//g;
            if ( $act =~ /i/ ) { 
		$outfh->print("($pre, $act, $suc)\r\n"); 
	    } else {
                if ( $hide_tau == 1 ) {
		    # use ^(call|ret) instead of (call|ret)
                    $outfh->print("($pre, \"$act\", $suc)\r\n")	if $act =~ /^(call|ret)/i ;     
                    $outfh->print("($pre, i, $suc)\r\n") unless	$act =~ /^(call|ret)/i ;
                } else {
                    $outfh->print("($pre, \"$act\", $suc)\r\n");
                }
            }
        } 
    }
}


# Print transitions out 
sub flush_trans {
    my $self = shift ;
    foreach my $pre (sort numeracally keys %$self) {
	foreach my $suc (sort numeracally keys %{ $self->{$pre} }) {
	    my $act = $self->{$pre}{$suc};
	    say "($pre, $act, $suc)";
	}
    }
}

# Given a STATE, a TRACE with no 'i' in it and a TRANSITION GRAPH, this subroutine returns
# a sub transition graph that can lead to such TRACE. This subroutine can be used to find 
# an COUNTEREXAMPLE TRACE for two 1-trace inequivalent states
sub original_trace {
    my ($state, $trace, $trans) = @_;
    my @actions	  ; # Store the regrex form of each actions, i.e., qr(..)
    my %part_trans; # Contails all possible transitions that form this trace. 
    
    for my $act (split /\./, $trace) {
	$act =~ s/^\s+|\s+$//g;
	push @actions, qr($act);
    }

    local *recursive = sub {
	my ($self, $index) = @_; # index is the index of "@actions"
	my $bool = 0;
	    
	for my $suc (keys %{ $trans->{$self} }) {
	    my $act = $trans->{$self}{$suc};
	    if ($act eq 'i') {
		if (recursive($suc, $index)) {
		    $bool = 1;
		    $part_trans{$self}{$suc} = $act;
		}
	    } else {
		if ($act =~ /$actions[$index]/) {
		    if ($index == $#actions or recursive($suc, $index + 1)) { # Already the last match
			$bool = 1;
			$part_trans{$self}{$suc} = $act;
		    }
		} 		# OTHERWISE NEXT
	    }
	}
	return $bool; 
    }; 

    recursive($state, 0);
    return %part_trans; 
    #flush_trans(\%part_trans); 
}


    
sub numeracally { $a <=> $b } 

1;

