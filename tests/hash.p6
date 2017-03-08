#!/usr/bin/perl6


sub dumper(%data){
	for %data.kv -> $key,$value {
		say "Key: " ~ $key ~ " value: " ~$value;
	}	
#	say %data;
}

my %zones = zone1 => "=>", zone2 => "||", zone3 => "awesomenok";

%zones.push("zone4"=>"REJECT");
#say  %zones;
#print "Dump map %zones<zone3>\n";

dumper(%zones);

#dumper(%*ENV);
#say %*ENV
