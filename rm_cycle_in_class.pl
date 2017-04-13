# remove states with star, i.e., states like : 3* = { ... }
# Gaoang@i, 2015, 12, 18 ;
# Edited Mar 25/ 2016

use Modern::Perl ;
use Carp ; 

END { main() } 

sub main {
    defined $ARGV[0] || croak ':.. No file was specified'; 
    remove_cycles($ARGV[0]);
}

sub remove_cycles{
    my $f = IO::File->new(shift, 'r'); 
    my $h ;
    
    while(<$f>){
	chomp ; 
	next unless /\d+/;
	my ($rep, $rest) = split /=/; 
	$rep =~ s/\s//g; 
	
	map {
	    if ( /\*/ ) {
		@{$h->{$rep}}{ keys %{$h->{$_}} } = values %{$h->{$_}} 
	    } else { $h->{$rep}{$_} = 1 }
	}
	grep	{/\d/}
	split	/[{}\s+]/, $rest ;
    }
    
    my $new_name = "new_".( split(/[\/\.]/, $ARGV[0]) )[1].".txt"; 
    print ":..writing to output/$new_name \n" ;
    my $w = IO::File->new("output/$new_name", 'w') ;
	
    map { 
	$w->print("$_ = ") ; 
	map{ $w->print("$_ ") } keys %{$h->{$_}}; 
	$w->print("\n")
    }
    grep { not /\*/ } 
    sort {$a<=>$b} keys %$h ;
    
    say ":..done";
}
