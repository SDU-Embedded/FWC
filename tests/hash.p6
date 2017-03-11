#!/usr/bin/perl6
use v6;

sub dumper(%data){
	say ""
	for %data.kv -> $key,$value {
		say "Key: " ~ $key ~ " value: " ~$value;
	}
}

#my %zones = zone1 => "=>", zone2 => "||", zone3 => "awesomenok";
#%zones.push("zone4"=>"REJECT");

my %zones1 = "world" => "ssh", "vlan5" => "ftp";
my %zones2 = homenet => %zones1, zone2 => "cool";


say %zones2<homenet><world>;


my %hashmap;

my  $test = "test";
%hashmap<$test> = "cool";


#%zones{'zone1'}= 10;


dumper(%hashmap);


#%zones<World><Internet>
