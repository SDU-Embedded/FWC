#!/usr/bin/perl6
use v6;

sub dumper(%data){
	for %data.kv -> $key,$value {
		say "Key: " ~ $key ~ " value: " ~$value;
	}
	say %data;
}

#my %zones = zone1 => "=>", zone2 => "||", zone3 => "awesomenok";
#%zones.push("zone4"=>"REJECT");

my %zones1 = "world" => "ssh", "vlan5" => "ftp";
my %zones2 = homenet => %zones1, zone2 => "cool";


say %zones2<homenet><world>

#%zones{'zone1'}= 10;


#dumper(%zones);


#%zones<World><Internet>
