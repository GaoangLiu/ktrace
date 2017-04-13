# Given an AUT file, using produce_lts() to produce a standard LTS file that can be 
# accepted by "pseuco.com/#/import/lts". And when the state labels are too large but 
# the transitions number is very small, the state labels will be renamed for readability.
#
# Gaoang @i, 2015 12 05
use v5.16; 
use Carp; 
use SetMethods qw(:Both);
use List::Util qw(max);
use FileProcess;

# given a (or more) state, produce their transition graph
END { produce_lts( @ARGV ) }

sub produce_lts {
    my $loc_rh     = shift;
    my $put_folder = "output";
    croak " No file was specified: " unless defined $loc_rh;

    my $out_name = ( split( "/", $loc_rh ) )[-1];
    my $trans = FileProcess::update_trans( IO::File->new( $loc_rh, 'r' ) );

    # When the state labels are too large but the transitions number is very small, 
    # the state labels will be renamed for readability.
    if ($_[0]) {
	$trans = rename_state_label($trans) if shift =~ /re/i;
    }
    
    # Return initial state, max state_label 
    my ($init, $max_label) = do { 
	my %tmpKeys	= map { $_, undef } keys %$trans;
	
	foreach my $k ( keys %$trans ) {
	    map	{ delete $tmpKeys{$_} } keys %{ $trans->{$k} }; 
	}

        my $do_max = 0;
        map { $do_max = max( $do_max, $_, keys %{ $trans->{$_} } ) } keys %$trans;

	# If there are more than one initial states, then a new initial state '0' will be created as 
	# the precussor for all the aforementioned initial states
	my $more_than_one_init	=  keys %tmpKeys > 1  ; # has more than one initial states
	my $has_zero_as_init	=  exists $tmpKeys{0} ; # 0 is one of them

	if ( not $has_zero_as_init ) {
	    map { $trans->{0}{$_} = 'i' } keys %tmpKeys;
	} else {
	    if ( $more_than_one_init ) {
		carp "0 is one of the initial states, you may want to rename the NEW INITIAL STATE ";
	    } else { 1 } 	# do nothing 
	}

        ( 0, ++ $do_max ); 
    };

    my $trans_num;
    
    map { $trans_num += scalar keys %{ $trans->{$_} } } keys %$trans;

    open my $loc_wh, '>', "$put_folder/$out_name\_lts.aut";
    # ( init, lines num, max_state + 1)
    $loc_wh->say("des ($init, $trans_num, $max_label)");   

    FileProcess::flush_trans_to_file( $trans, $loc_wh )
}


# Rename state labels for the input LTS
sub rename_state_label {
    my $self = shift;
    my (%ret, %tmp);
    my $init = 0;

    local *rn_label = sub {
	$tmp{shift()} = ++ $init; 
	return $init; 
    };
    
    foreach my $pre (sort numerically keys %$self) {
	foreach my $suc (sort numerically keys %{ $self->{$pre} }) {
	    my $act = $self->{$pre}{$suc};
	    my $newpre = exists $tmp{$pre} ? $tmp{$pre} : rn_label($pre);
	    my $newsuc = exists $tmp{$suc} ? $tmp{$suc} : rn_label($suc);
	    $ret{$newpre}{$newsuc} = $act;
	}
    }

    return \%ret; 
}

sub numerically {$a <=> $b}
