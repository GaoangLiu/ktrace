use v5.18; 
use autodie; 
use YAML; 
use Data::Printer; 

die "--specify a file first" unless 
    defined ( my $file =  $ARGV[0] ); 
open my$fh, '<', $file; 
my $inner_acts; 

my $methods = {
    #qr/GENERATOR/  => undef ,
    #qr/COMPARE\_AND\_SET\_ADD/  => undef ,
    #qr/COMPARE\_AND\_SET\_REMOVE/  => undef ,
    #qr/READ\_NEXT\_MARK/  => undef ,
    qr/processing/  => undef ,
    qr/Finale/  => undef ,
    qr/M/  => undef ,
    qr/P/  => undef ,
};

parser_actions(); 
print Dump($inner_acts); 

sub parser_actions{
    my $flag = 0; 
    while(<$fh>){
	chomp; 
	$flag = 1 if /Finale|call|ret/i;
	next unless $flag; 
	next if /call|ret/i;  # ignore call and return 

	if( /\!(.*?)!.*/i ){
	    $inner_acts -> {$1} ++; 
	}
    }
    print ":...Good ! No unexpected inner actions\n";
}



sub match_method{
    my ($line, $m) = @_; 
    map{ 
	return 1 if $line =~ $_
    } keys %$m; 
    return 0; 
}
