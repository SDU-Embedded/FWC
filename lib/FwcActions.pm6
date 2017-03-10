#!/usr/bin/perl6
use v6;

unit class FwcActions;

#has %.somevar = {};

method TOP($/) {
#	say "pol: " ~  $<policy>;
	 $/.make: $<policy>.made;
}


method policy($/) {
	say $<Rule>[1].made; # array
	$/.make: $<Rule>».made;
}
method Protocol($proto){
	$/.make: "test" => "coolnok";
#	make $proto;
#	say "Protocol found: $proto"
}

method FromZone($zone){
#	$zone.make: $zone;
#	say "From zone: $zone"
}

method Option($opt) {
#	say "Option: " ~ $opt; 
}

method Option2($opt) {
#	say "Option: " ~ $opt; 
}
method action:sym<=\>>($dir){
#	print "Direction in\n";
}

method action:sym<\<=>($dir){
#	print "Direction out\n";
}
method ToZone($zone){
#	$zone.make: $zone;
#	say "To zone: $zone"
}

method Rule($/){
#	say "Rule found, from: $rule<FromZone>, to: $rule<ToZone>";
	$/.make: $<FromZone> => $<ToZone>;
}
