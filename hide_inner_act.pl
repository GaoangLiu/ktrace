# Given a AUT file, we do :
#   1. produce the transition, and print it out (inner action hided as tau) 
#   2. to do 
# Gaoang @i, Dec 05 2015 

use v5.18; 
use strict;
use autodie;
use FileProcess; 
use IO::Null; 

while(@ARGV){
    hide_inner_act($ARGV[0]);
    shift @ARGV; 
}

sub hide_inner_act{
    my $DDBBUUGG = 1; 
    my $put_folder = "output";
    my $debug = $DDBBUUGG ? *STDOUT : IO::Null -> new(); 
 
    my $loc_rh = shift; 
    my $out_name = ( split /\//, $loc_rh )[-1];
    die "-- there is no input file:" unless defined $loc_rh; 
    $debug -> print ( ":...hiding inner action in file $loc_rh\n" );
    
    open my$loc_wh, '>', "$put_folder/$out_name\_tau";
    $debug -> print ( ":...writing to file $put_folder/$out_name\_tau\n" );

    my $loc_trans = 
	FileProcess::update_trans( IO::File -> new($loc_rh, 'r') );
    FileProcess::flush_trans_to_file($loc_trans, $loc_wh, 1);

    $debug -> print ( ":...Done\n" );
}

