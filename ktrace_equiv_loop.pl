use 5.010; 
use strict; 
use SetMethods qw(:Both); 
use PreProcess qw(:Both); 
use List::Util qw(max); 
## 
## For each k-trace of a node $n, the path that produced this k-trace will be stored in an
## hash for future comparison between two connected but not k-trace equivalent nodes 

my $file = shift @ARGV; 
my @inputarray = @ARGV; 
open my$fh, '<', "$file" or die 'Can not read file';  $file = (split("/", $file))[1];
open my$wh, '>', "output/$file" or die 'Can not write : $@';

my (%sucs, %trans, %visible, %tautrans);
my %equivalent; 
my %prefixzero; 
my %prefixone; 
my %prefix_multi; 
my $con = " . ";

preprocess($fh);

my $nodesnum = max(keys %sucs);  # number of nodes  
my %zte;  # 0-trace encode $zte{2}{0} = @zerosets, the 0-trace set (and rank) for state 2 
my $counter = 1 ; 
my @kcounter; 
my $max_k = 10; 
map{$kcounter[$_] = 1}(0..$max_k);
my %pre_set; 
# ==================================================
#my $ccc = 0 ;
experiments();
sub experiments{
    my @ca; 
    my $upper = 1; 
    map{$ca[$_] = 0}(0..$upper);
    foreach my$i(reverse(0..$nodesnum)){
	foreach my$j($i..$nodesnum){
	    say "processing <$i, $j>"; 
	    next unless $trans{$i}{$j} =~ /i/ or $trans{$j}{$i} =~ /i/;
	    if ($i == $j){# or 
		#map{$ca[$_] ++}(0..$upper);
		next; 
	    }elsif($trans{$i}{$j} =~ /i/ and $trans{$j}{$i} =~ /i/){ 
		#map{$ca[$_] ++}(0..$upper);
	    }
	    
	    if(pure_trace_equiv($i, $j)){
		next; 
		$ca[0] ++; 		
		#say $wh "<$i, $j> 1-trace equivalent"; 
		#say "<$i, $j> 1-trace equivalent" ;
		my $continue = 2;
		while(1){
		    say $wh "($i, $j) are not $continue - equiv" and last if k_trace_equiv($i, $j, $continue) == 0;
		    say "<$i, $j> $continue-trace equivalent" ; #if $continue == 2; 
		    $ca[$continue-1] ++ ;
		    last if $continue ++ > $upper; 
		}
	    }else{		$ca[0] ++;  		say $wh "<$i, $j> are not 1-trace equivalent -- $ca[0]";	    }
	}
    }
    #print $wh "( "; map{print $wh $_."-trace equiv "}(1..$upper+1); print $wh ") = ( " ; map{print $wh $ca[$_]." "}(0..$upper); print $wh ")"; 
}

# ================================================== 
sub k_trace_equiv{
    my ($c, $d, $k) = (shift, shift, shift); 
    return 1 if defined $equivalent{$c}{$d} and $equivalent{$c}{$d} >= $k; #and $equivalent{$c}{$d} >= $k; 
    return 0 if defined $equivalent{$c}{$d} and $equivalent{$c}{$d} <= $k-2; #and $equivalent{$c}{$d} >= $k; 
    $k --; 
    return pure_trace_equiv($c, $d) if $k == 0; 
    my $dep = 1; 
    while(1){
	#last if $dep == 200; 
	clear_preset($k); 
	my $array_c= prefix_k_trace($c, $dep, $k);
	clear_preset($k); 
	my $array_d = prefix_k_trace($d, $dep, $k);
	return 0 unless (keys_match($array_c, $array_d)); 

	last unless (%{$array_c});
	$dep ++ ; 
    }
    $equivalent{$c}{$d}  = $equivalent{$d}{$c} = $k + 1; # been here means it's not defined 
    return 1 ;   # since c, d equiv, 0 is useless here. 
}



sub prefix_k_trace{
    my ($n, $len, $k) = (shift, shift, shift); 
    #return $prefix_multi{$k}{$n}{$len} if defined $prefix_multi{$k}{$n}{$len};
    my %h ; 
    return \%h unless $sucs{$n};
    return \%h if $len <= 0 ;
    
    mark_alpha_k($n, $k) unless defined $zte{$n}{$k};
    
    foreach my$suc (@{$sucs{$n}}){
	my $act = $trans{$n}->{$suc};     # action\
	mark_alpha_k($suc, $k) unless defined $zte{$suc}{$k}; 
	if($act =~ /i/ and $zte{$n}{$k} == $zte{$suc}{$k}){
	    next if $suc == $n; 
	    next if ${$pre_set{$k}{$n}}{$suc} == 1; 
	    ${$pre_set{$k}{$suc}}{$n} = 1; 
	    @{$pre_set{$k}{$suc}}{keys %{$pre_set{$k}{$n}}} = values %{$pre_set{$k}{$n}};
	    
	    map{$h{$_} = 1}(keys %{prefix_k_trace($suc, $len, $k)});
	}else{
	    next if $suc == $n; 
	    next if ${$pre_set{$k}{$n}}{$suc} == 1; 
	    ${$pre_set{$k}{$suc}}{$n} = 1; 
	    @{$pre_set{$k}{$suc}}{keys %{$pre_set{$k}{$n}}} = values %{$pre_set{$k}{$n}};
	    
	    #${$priority[$k]}{$suc} = $this_level unless defined ${$priority[$k]}{$suc};
	    #next if ${$priority[$k]}{$suc} < ${$priority[$k]}{$n}; 
	    
	    my %g  = %{prefix_k_trace($suc, $len - 1, $k)};
	    $h{join($con, $zte{$n}{$k}, $act, $zte{$suc}{$k})} = 1 and next if $len == 1; 
	    map{$h{join($con, $zte{$n}{$k}, $act, $_)} = 1}(keys %g);
	}	
	
    }
    $prefix_multi{$k}{$n}{$len} = \%h; 
    return \%h; 
}



sub mark_alpha_k{  ## return the set of pure traces 
    my ($s, $k) = (shift, shift);  
    say "\t Forgot to give a k, man" and exit unless defined $k;
    return mark_alpha_one($s) if $k == 1; 
    return 1 if $zte{$s}{$k} > 0;
    map{
	if($s != $_ and k_trace_equiv($s, $_, $k) and defined $zte{$_}{$k}){
	    $zte{$s}{$k} = $zte{$_}{$k} ; 
	    return 1; 
	}
    }(keys %zte);
    $zte{$s}{$k} = $kcounter[$k] ++; 
    return 1; 
}


sub two_trace_equiv{
    my ($c, $d) = (shift, shift);
    my $dep = 1; 
    return 1 if $equivalent{$c}{$d} >= 2; 
    return 0 if defined $equivalent{$c}{$d} and $equivalent{$c}{$d} == 0; 
    while(1){
	clear_preset(1); 
	my $array_c = prefix_one_trace($c, $dep);
	clear_preset(1); 


	#for my$key (keys %{$pre_set{1}{146}}){
	 #   say "  mhkdjffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffkdjfffffffffffff $key, and ${$pre_set{1}{102}}{$key}";
	#}


	my $array_d = prefix_one_trace($d, $dep);
	unless (keys_match($array_c, $array_d)){
	    #say $dep ; 
	    #map{say $_} keys %$array_c if $c == 66; 
	    #say "";
	    #$array_c= prefix_one_trace($c, $dep-1);
	    #map{say $_} keys %$array_c if $c == 66; 
	    #say "";


	    #map{say $_} keys %$array_d if $d == 146; 
	    #say "";
	    #$array_d = prefix_one_trace($d, $dep-1);
	    #map{say $_} keys %$array_d if $d == 146; 
	    
	    #foreach my $key(keys %zte){
#		say $key and last if $zte{$key}{1} == 3; 
#	    }
	    
	    return 0 ;
	}
	last unless (%{$array_c}); 
	$dep ++ ; 
    }
    $equivalent{$c}{$d}  = $equivalent{$d}{$c} = 2; # been here means it's not defined 
    return 1 ;   # since c, d equiv, 0 is useless here. 
}


sub prefix_one_trace{
    my ($n, $len) = (shift, shift); 
    #return $prefixone{$n}{$len} if defined $prefixone{$n}{$len};
    my %h ; 

    return \%h unless $sucs{$n};
    return \%h if $len <= 0 ;
    
    mark_alpha_one($n) unless defined $zte{$n}{1};


    #say " working on (n, len) is ($n, $len)"; 

    
    foreach my$suc (@{$sucs{$n}}){
	my $act = $trans{$n}->{$suc};     # action
	mark_alpha_one($suc) unless defined $zte{$suc}{1}; 

	if($act =~ /i/ and $zte{$n}{1} == $zte{$suc}{1}){
	    next if $suc == $n; 
	    
	    #say " tau transition and equiv (n, suc, len) is ($n, $suc, $len)"; 
	    #say "== for 66:   $n , $suc"  and say keys %{$pre_set{1}{$n}} if $n == 102 and $suc == 146 and $len == 1; 
	    #say "== ha, hit $n , $suc"  and say keys %{$pre_set{1}{$n}}  and say values %{$pre_set{1}{$n}}  if $n == 146 and $suc == 66 and $len == 1; 
	    next if ${$pre_set{1}{$n}}{$suc} == 1; 
	    ${$pre_set{1}{$suc}}{$n} = 1; 
	    
	    #say "fuckkkkkkkkkkkkkkkkkkkkkkkkkkkkk" and say keys %{$pre_set{1}{$suc}} if $n == 66 and $suc == 102 and $len == 1; 
	    #say "== any difference $n , $suc"  and say keys %{$pre_set{1}{$n}} if $n == 146 and $suc == 66 and $len == 1; 

	    @{$pre_set{1}{$suc}}{keys %{$pre_set{1}{$n}}} = values %{$pre_set{1}{$n}};
	    
	    map{$h{$_} = 1}(keys %{prefix_one_trace($suc, $len)});
	}else{

	    #say " now (n, suc, len) is ($n, $suc, $len)"; 


	    next if $suc == $n; 
	    next if ${$pre_set{1}{$n}}{$suc} == 1; 
	    ${$pre_set{1}{$suc}}{$n} = 1; 
	    @{$pre_set{1}{$suc}}{keys %{$pre_set{1}{$n}}} = values %{$pre_set{1}{$n}};
	    
	    my %g  = %{prefix_one_trace($suc, $len - 1)};
	    $h{join($con, $zte{$n}{1}, $act, $zte{$suc}{1})} = 1 and next if $len == 1; 
	    map{$h{join($con, $zte{$n}{1}, $act, $_)} = 1}(keys %g);
	}
    }
    $prefixone{$n}{$len} = \%h; 
    return \%h; 
}


sub mark_alpha_one{  ## encode the T0 set for states 
    my $s = shift;  
    return 1 if defined $zte{$s}{1};
    map{
	if($s != $_ and pure_trace_equiv($s, $_)){
	    $zte{$s}{1} = $zte{$_}{1}; 
	    return 1; 
	}
    }(keys %zte);
    $zte{$s}{1} = $counter ++; 
    return 1; 
}




sub pure_trace_equiv{
    my ($c, $d) = (shift, shift);
    if(defined $equivalent{$c}{$d}){
	return 1 if $equivalent{$c}{$d} >= 1; 
    }
    

    my $dep = 1; 
    while(1){
	&clear_preset(0);
	my $array_c = prefix_trace($c, $dep);
	&clear_preset(0);
	my $array_d = prefix_trace($d, $dep);
	unless(keys_match($array_c, $array_d)){
	    $equivalent{$c}{$d}  = $equivalent{$d}{$c} = 0; # been here means it's not defined 
	    return 0; 
	}
	last unless (%{$array_c});
	$dep ++ ; 
    }
    $equivalent{$c}{$d}  = $equivalent{$d}{$c} = 1; # been here means it's not defined 
    return 1 ;   # since c, d equiv, 0 is useless here. 
}

sub clear_preset{
    my $k = shift; 
    delete $pre_set{$k};

    #say "dkjk1-2324837483kjasdk387437267r7eyr369273486266623" and say ${$pre_set{1}{102}}{66} if defined {$pre_set{1}{102}} and $k == 1;
}

sub prefix_trace{  # for 0-trace only 
    my ($n, $len) = (shift, shift); 
    return $prefixzero{$n}{$len} if defined $prefixzero{$n}{$len}; 
    my %h ; 
    return \%h unless $sucs{$n};
    return \%h if $len <= 0 ;

    foreach my$suc (@{$sucs{$n}}){
	my $act = $trans{$n}->{$suc};     # action
	if($act =~ /i/){
	    next if $suc == $n; 
	    next if ${$pre_set{0}{$n}}{$suc} == 1; 
	    ${$pre_set{0}{$suc}}{$n} = 1; 
	    @{$pre_set{0}{$suc}}{keys %{$pre_set{0}{$n}}} = values %{$pre_set{0}{$n}};
	    map{$h{$_} = 1}(keys %{prefix_trace($suc, $len)});
	}else{
	    ${$pre_set{0}{$suc}}{$n} = 1; 
	    @{$pre_set{0}{$suc}}{keys %{$pre_set{0}{$n}}} = values %{$pre_set{0}{$n}};
	    my %g  = %{prefix_trace($suc, $len - 1)};
	    $h{$act} = 1 and next if $len == 1; 
	    map{$h{join($con, $act, $_)} = 1}(keys %g);
	}

    }
    $prefixzero{$n}{$len} = \%h; 
    return \%h; 
}



sub preprocess{ 
    my $file = shift; 
    my ($trans_num, $tautrans_num, $state_num) = (0, 0, 0); 
    while(<$file>){
	chomp; 
	if($_ =~ /([0-9]+), "(([A-Z]|\s|\!|[0-9]|\_|\+|\,|\(|\))+)", (\d+)/){
	    $trans{$1}{$4} = $2; 
	    $visible{$1}{$2} = $4;  # visible transtion 
	    push @{$sucs{$1}}, $4;
	    $state_num = max($state_num, $1, $4);
	    #say "<$1, $2, $4>" if (int(rand(100))) == 99; 
	}elsif($_ =~ /([0-9]+),\s(i),\s([0-9]+)/){  # for tau transition 
	    $trans{$1}{$3} = $2; 
	    $tautrans{$1}{$3} = 1;  # invisible transtion 
	    push @{$sucs{$1}}, $3;
	    $tautrans_num ++; 
	    $state_num = max($state_num, $1, $4);
	}else{
	    say " == MISS ! CHECK YOUR INPUT == "; exit; 
	}
	$trans_num ++; 
    }
    #$state_num = 1 + max{keys %sucs};
    say $wh "States: $state_num + 1" ;
    say $wh "Tau trans: $tautrans_num" ;
    say $wh "Transitions: $trans_num" ;
}


