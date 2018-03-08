## find lp
use lib '.';
use Modern::Perl ; no warnings ;
use autodie;
use JSON;
use YAML;
use IO::Null;
use Data::Printer;
use List::Util qw(max first);
use FileProcess qw(update_trans flush_trans);
use Storable qw(dclone);
no warnings 'experimental::smartmatch';


my $real_trans; 

if ( defined $ARGV[0] ){
    $real_trans = update_trans( IO::File->new($ARGV[0] , 'r' ) );
}else{
    warn "-- no file was specified, using default file: msqueue25 \n";
    $real_trans = update_trans( IO::File->new("input/msqueue25.aut" , 'r' ) );
}

exit ;
my %legal_trans;    # global

# print_real_trans(); exit;
# print Dump($real_trans);
#_produce_sub_lts();
# ---------------------------------Sub Functions ------------------------------------------------
# ***********************************************************************************************
# ---------------------------------Sub Functions ------------------------------------------------
sub _produce_sub_lts {    # run all kinds of experiments
    my $file_name = 'input/ccasbig.aut';
    my $self_trans =
      FileProcess::update_trans( IO::File->new( $file_name, 'r' ) );
    my $sink      = {};
    my $precursor = {};
    my $debug     = 1;
    my $debug_fh  = $debug ? *STDOUT : IO::Null->new;

    $debug_fh->say(':...locating sinks...');

    foreach my $cur ( keys %$self_trans ) {
        map {
            $sink->{$_} = 1 unless $self_trans->{$_};
            push @{ $precursor->{$_} }, $cur;
        } keys %{ $self_trans->{$cur} };
    }

    $debug_fh->print( ":...sum of sink: ", scalar keys %$sink, "\n" );
    $debug_fh->print( ":...producing sub-lts for $file_name : \n" );

    my $cter = 0;
    map { print_each_sink($_) } keys %$sink;

    sub print_each_sink {
        exit if $cter++ == 5000;
	
        my $sub_trans = {};
        my $todo;
        my $qs = shift;
        l $todo->{$qs} = 1;
        $debug_fh->printf( "%15d %10d\n", $qs, $cter );

        open my $out_fh, '>', "sink/$cter\_ori";

        while (%$todo) {
            my $self = ( each %$todo )[0];
            map {
                $todo->{$_} = 1;
                $sub_trans->{$_}{$self} = $self_trans->{$_}{$self};
            } @{ $precursor->{$self} };
            delete $todo->{$self};
        }

        FileProcess::flush_trans_to_file( $sub_trans, $out_fh );
    }
}



# ---------------------------------------------------------------------------------------------------
run_extract();

sub run_extract {
    my $tha = [ qr/CALL \!ENQ \!1/, 
		qr/RET \!ENQ \!1/,
	];
    my $thb = [ qr/CALL \!DEQ \!2/, 
		qr/RET \!DEQ \!(100|200) \!2/,
	];
    my $thc = [ qr/CALL \!ENQ \!3/, 
		qr/RET \!ENQ \!3/, 
	];

    extract_sub_lts( 0, $tha, $thb, $thc );
    flush_trans( \%legal_trans );
}

my %visited ; 

sub extract_sub_lts {
    my ( $node, $tha, $thb, $thc ) = @_;
    my $bool = 0;
    
    return $visited{$node} if exists $visited{$node} ;
    return 1 unless @$tha or @$thb or @$thc;
    #say " Current node is: ", $node, "\n", @$tha, "\n", @$thb ;

    foreach my $suc ( keys %{ $real_trans->{$node} } ) {
        my $act    = $real_trans->{$node}{$suc};
        my @newtha = @$tha;
        my @newthb = @$thb;
	my @newthc = @$thc;	

        if ( $act =~ /^(call|ret).*(?<tid>\d+)$/i ) {
            if ( $+{tid} == 1 ) {    # thread 1
                next unless defined $newtha[0] and $act =~ $newtha[0];
                shift @newtha ;
            } elsif ( $+{tid} == 2 ) {
                next unless defined $newthb[0] and $act =~ $newthb[0];
                shift @newthb ;
	    } elsif ($+{tid} == 3) {
		next unless defined $newthc[0] and $act =~ $newthc[0];
                shift @newthc ;
	    } else {
		say "Do you really have more than 3 threads ? Press 'y' to confirm : " ;
		my $more_thread = <> ; 
		next if $more_thread =~ /y/i ;
            }
        }

        if ( extract_sub_lts( $suc, \@newtha, \@newthb, \@newthc ) ) {
            $legal_trans{$node}{$suc} = $act ;
            $bool = 1 ;
	    $visited{$node} = $visited{$suc} = 1 ;
        } else { $visited{$suc} = 0 }
    }

    return $bool;
}

# --------------------------------------------------------------------------------------------------

sub print_real_trans {    # print legal_trans on the screen
    map {
        my $self = $_;
        map {
            my $act = $real_trans->{$self}{$_};
            say "($self, \"$act\", $_)\r";
        } sort { $a <=> $b } keys %{ $real_trans->{$self} };
    } sort { $a <=> $b } keys %$real_trans;
}

