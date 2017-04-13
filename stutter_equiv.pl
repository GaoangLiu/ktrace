# we decide a pair of states (s1, s2) is 'stuttering equivalent' if they satisfy :
# 1. between them there exist a tau transition (s1, tau, s2)
# 2. if there is a complete method run from s1, s1 - call -> u1 - tau -> u2 - tau -> u3 - ret -> u4,
#    then there must be a similiar run: s2 - call -> v1 - tau -> v2 - tau -> v3 - ret -> v4, and
#    (ui, vi) satisfy :
#        1. ui == vi
#        2. a tau transition exists ( ui, tau, vi )

use v5.18;
use strict;
use autodie;
use FileProcess qw(flush_trans);
use YAML;
use Data::Dumper; no warnings 'experimental::smartmatch';

# NOTATIONS:
# gt  : -- global transition
# pt  : -- part transition, i.e., tau transitions from gt; 
# ia  : -- independent actions, i.e., actions form a diamond
# inf : -- input file .. (if is keywords) 

my  $file = shift || "msqueue23/MS_23_qo.aut";
our $gt   = update_trans( IO::File->new($file) );
our $pt; 
our $ia; 

#print Dump($gt); exit; 
check_lp();

sub check_lp{
    map { 
	my $k = $_; 
	map  { is_in_diamond($k, $_) }
	grep { not $gt->{$k}{$_} =~ /call|ret/i } 
	keys %{ $gt->{$k} } 
    } keys %$gt ; 

    map{
	my $k = $_; 
	map  { printf "%7d  %17s  %7d\n",  $k, $gt->{$k}{$_}, $_ }
	grep { $pt->{$k}{$_} == 0 }
	keys %{ $pt -> {$k} }
    }(); #sort {$a<=>$b} keys %$pt ; 

    #flush_trans($pt);
    print Dump($ia);
    print ":-- done\n";
}


sub is_in_diamond {        # prove whether states S and T are part of a diamond
    my ( $s, $t ) = @_;    # note : s -- tau --> t
    my $bool = 0;

    unless ( defined $t and not $gt->{$s}{$t} =~ /call|ret/i ){
	die ":-- Not a tau transition : $s, $t" ;
    }

    not defined $pt->{$s}{$t} and $pt->{$s}{$t} = 0 ;

    foreach my $suc ( keys %{ $gt->{$s} } ) {
        my ( $b, $taus ) = has_tau_trans($suc);
        next if $suc == $t;
        next unless $b == 1;
	
        my $act = $gt->{$s}{$suc};

        foreach my $v (@$taus) {
            next unless exists $gt->{$t}{$v};
            next unless $act ~~ $gt->{$t}{$v};
	    
	    $pt->{$s}{$t} = 1 ; 
	    $pt->{$suc}{$v} = 1 ; 
	    #$act = lc($act) ; 
	    $ia->{$gt->{$s}{$t}}{$act} ++; 
            $bool = 1;
            last;
        }
        #map say, @$taus;
    }

    return $bool;
}


sub has_tau_trans {
    my $s      = shift;
    my $hastau = 0;       # whether state s has a tau trans
    my $tauSucs;

    not $gt->{$s}{$_} =~ /call|ret/i  
	and $hastau = 1
	and push @$tauSucs, $_
	for keys %{ $gt->{$s} };

    return ( $hastau, $tauSucs );
}


=for_comment
    rename the invisible actions in the original system by deleting all information
    except the real name of action and thread id. i.e., 
    'M !READ_FIRST_NEXT !0 !1 !2' is replaced by: 'READ_FIRST_NEXT 2'
=cut
sub update_trans{ 
    my $f = shift; 
    my $trs ;
    while (<$f>){
	chomp ; 
	s/["]//g; 
	next if /des/; 
	if (/(\d+), (.*), (\d+)/) {
	    my ($p, $act, $s) = ($1, $2, $3); 

	    if ( $act =~ /^(?:M|P) !(?<name>\S+) (?:\!\d+)?.*!(?<id>\d+)$/i ) {
		$act = join( " ", $+{name}, "!".$+{id} );
	    } elsif ( $act =~ /(?<name>CAS\_DESCRIPTOR) .* \!CONS \((?<id>\d+)$/i ){
		$act = join( " ", $+{name}, $+{id} );
	    } elsif ( $act =~ /^(?<cr>call|ret) !(?<name>\S+)(?:.*)\!(?<id>\d+)$/i ) {
		$act = join( " ", $+{cr}, $+{name}, $+{id} );
	    } else { 
		say $_ ; 
		die ":.. Fail to capture ";
	    }

	    $trs->{$p}{$s} = $act ; 
	} else {	
	    say $_;
	    die ":-- cannot parse file : update_trans : stutter_equiv.pl";
	}
    }
    return $trs; 
}



