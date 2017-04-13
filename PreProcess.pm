package PreProcess; 

use strict; 
use 5.010; 
use Exporter; 
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION 	= 1.0; 
@ISA		= qw(Exporter); 
@EXPORT		= (); 
@EXPORT_OK	= qw(keys_match coffee preprocess);
%EXPORT_TAGS	= (	DEFAULT => [qw(preprocess)], 
			Both	=> [qw(keys_match coffee preprocess)]);
			
			

sub keys_match{
    my ($hc, $hd) = (shift, shift); 
    #return (keys %{$hc} ~~ keys %{$hd});
    map{
	return 0 unless ${$hd}{$_}; 
    }(keys %{$hc});

    map{
	return 0 unless ${$hc}{$_}; 
    }(keys %{$hd});
    return 1 ; 
}


sub coffee{  # print it out and save it to log 
    my ($file, $msg) = (shift, shift); 
    say $msg; 
    print $file $msg." \n"; 
}


sub say{
    print $_[0]."\n";

}


1; 
