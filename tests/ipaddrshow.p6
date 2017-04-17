#!/opt/rakudo-star-2017.01/bin/perl6
use v6.c;

#1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
#    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
#    inet 127.0.0.1/8 scope host lo
#       valid_lft forever preferred_lft forever
#    inet 169.254.0.0/24 brd 169.254.0.255 scope global lo:1
#       valid_lft forever preferred_lft forever
#    inet6 ::1/128 scope host 
#       valid_lft forever preferred_lft forever


grammar KeyValuePairs {
    token TOP {
	<Interface>*
    }

    rule Interface {
        <IfaceNum><colon><IfaceName><colon>\< <state>+ \><options><ws><type><mac>brd<ws><mac><ws><inets>
    }

    rule inets { <inet>* }
    rule inet {
	inet\s<ipaddress><params>
    }
    rule params { <param>* }
    rule param {
	[\s]?<[\w\d.:]-inet>+\s
    }

    rule mac {
	[\d ** 2] ** 6 % ':'
    }
    rule type {
	<[a..z/]>+
    }
    token state {
	<[A..Z_]>+[","]?
    }

    token ipaddress {
	<ip>"/"<cidr>	
    }

#    proto rule inet          {*}
#    rule inet:sym<ipv4> { inet\s<ipaddress><params> }
#    rule inet:sym<ipv6> { inet6\s<ip6address><params> }
 
    token ip6address {
	<ip6>"/"<cidr>	
    }
    token ip6 {<[:\d]>+}
    token ip {[\d ** 1..3] ** 4 % '.'}
    token cidr { \d **1..2  }

    token IfaceNum  {
	\d+
    }
    token IfaceName {
	\w+
    }
    token options {
	<option>+
    }
    token option {
	[\s]?<key>\s<value>
    }
    token key {
	\w+
    }
    token value {
	<[a..zA..Z0..9]>+
    }
    token ws { <[\s\n\t\h\v]>* }
    token colon   { \s* ':' \s* }
}
 
class KeyValuePairsActions {
    method TOP ($/) { 
#	say $/;
    }

    method state($/){
	say "state: $/";
    }

    method params($/){
	say "params: $/";
    }
    method IfaceNum($/){
	say "Iface number: $/";
    }

    method IfaceName($/){
	say "Iface name: $/";
    }

    method key($/){
	say "key:$/"
    }

    method value($/){
	say "value:$/"
    }
    method options($/){
	say "Options: $/";
    }
    method option($/){
	say "Option: $/";
    }
    method type($/){
	say "Type: $/";
    }
    method mac($/){
	say "Mac: $/";
    }


   method Interface($/){
#	say "Interface: $/";
   }

   method inet4($/){
	say "Inet: $/";
   }
   method inet6($/){
	say "Inet: $/";
   }

   method ipaddress($/){
	say "Ipaddress: $/";
   }
}
 

my $output = q:x/cat content/;
say $output;

my $res = KeyValuePairs.parse($output, :actions(KeyValuePairsActions)).made; 
 
#say $res;
