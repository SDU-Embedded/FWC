#!/usr/bin/perl6
use v6;

unit class FwcActions;

method TOP($/) {
	 $/.make: $<policy>.made;
}

method Header($/){
	my %header = "Protocol" => $<Protocol>.made;

	unless ($<Options>.made) {
	}

	$/.make: %header;
}

method policy($/) {
	my (%rules, %header);

	%header = $<Header>.made;

	for  $<Rule> -> $rule {
		my $rule1 = $rule.made;
		my Str $from = $rule1[0].Str;
		my Str $to = $rule1[1].Str;

		my $tozone = $to => %header;
		%rules{$from} = $tozone;
	}

	$/.make: %rules;
}

method Protocol($/){
	$/.make: $/;
}

method FromZone($zone){
}

method GlobalOption($opt) {
}

method LocalOption($opt) {
}
method action:sym<=\>>($dir){
}

method action:sym<\<=>($dir){
}
method ToZone($zone){
}

method Rule($tmp){

	my ($from, $to) = ($tmp<FromZone>, $tmp<ToZone>);
	if $tmp<action> ~~ /"<"/ {
		($to, $from) = ($from, $to);
	}

	$tmp.make: ($from, $to);
}
