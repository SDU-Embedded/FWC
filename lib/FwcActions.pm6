#!/usr/bin/perl6
use v6;

unit class FwcActions;

method TOP($/) {
	 $/.make: $<policy>.made;
}

method Header($/){
	my %header = "Protocol" => $<Protocol>.made;

	%header.push: $<GlobalOptions>.made;
	$/.make: %header;
}

method policy($/) {
	my (%rules, %header);

	%header = $<Header>.made;

	for  $<Rule> -> $rule {
		my $rule1 = $rule.made;
		my Str $from = $rule1[0].Str;
		my Str $to = $rule1[1].Str;
		my $tozone = $to => $rule1[2].push: %header; # Add global to local parameters
		%rules{$from} = $tozone;
	}

	$/.make: %rules;
}

method Protocol($/){
	$/.make: $/;
}

method GlobalOptions($/) {
        my %map;
        for $<kvpair> -> $option {
                my ($key, $value) = $option.made.kv;
                %map{$key.Str} = $value.Str;
        }

        $/.make: %map;
}

method kvpair($/) {
	$/.make: $<Key> => $<Value>;
}

method LocalOptions($/) {
	my %map;
	for $<kvpair> -> $option {	
		my ($key, $value) = $option.made.kv;
		%map{$key.Str} = $value.Str;
	}

	$/.make: %map;
}
method action:sym<=\>>($dir){
}

method action:sym<\<=>($dir){
}
method Rule($tmp){
	my %options;

	if $tmp<LocalOptions>.made { # Options are optional
		%options = $tmp<LocalOptions>.made;
	}

	my ($from, $to) = ($tmp<FromZone>, $tmp<ToZone>);
	if $tmp<action> ~~ /"<"/ {
		($to, $from) = ($from, $to);
	}


	$tmp.make: ($from, $to, %options);
}
