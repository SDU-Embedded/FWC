#!/usr/bin/perl6
use v6;

unit class FwcActions;

#has %.somevar = {};

method TOP($/) {
#	say "pol: " ~  $<policy>;
	 $/.make: $<policy>.made;
}

method header($/){
	unless ($<Options>.made) {
		say "No options specified";
		$/.make: "Protocol" => $<Protocol>.made;
	}
#	$/.make: "Protocol" => $<Protocol>.made, "Options" => $<Options>.made;
}

method policy($/) {
	my (%rules, %header);
	
	#%header = $<GlobalOption>.made;
	

	for  $<Rule> -> $rule {
		my $rule1 = $rule.made;
		my Str $from = $rule1[0].Str;
		my Str $to = $rule1[1].Str;

		my $tozone = $to => %header;
		%rules{$from} = $tozone;
	}

	say "Content of map: " ~%rules;

	$/.make: %rules;
}

method Protocol($/){
#	$/.make: "test" => "coolnok";
	$/.make: $/;
#	make $proto;
#	say "Protocol found: $proto"
}

method FromZone($zone){
#	$zone.make: $zone;
#	say "From zone: $zone"
}

method GlobalOption($opt) {
#	say "Option: " ~ $opt; 
}

method LocalOption($opt) {
#	say "Option: " ~ $opt; 
}
method action:sym<=\>>($dir){
#	$/.make: $dir;
#	print "Direction in\n";
}

method action:sym<\<=>($dir){
#	$/.make: $dir;
#	print "Direction out\n";
}
method ToZone($zone){
#	$zone.make: $zone;
#	say "To zone: $zone"
}

method Rule($tmp){

	my ($from, $to) = ($tmp<FromZone>, $tmp<ToZone>);
	if $tmp<action> ~~ /"<"/ {
		($to, $from) = ($from, $to);
	}

	$tmp.make: ($from, $to);
}
