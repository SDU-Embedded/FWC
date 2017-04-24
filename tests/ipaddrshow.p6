#!/opt/rakudo-star-2017.01/bin/perl6
use v6.c;

# 1: lo    inet 127.0.0.1/8 scope host lo       valid_lft forever preferred_lft forever
# 1: lo    inet 169.254.0.0/24 brd 169.254.0.255 scope global lo:1       valid_lft forever preferred_lft forever


grammar KeyValuePairs {
    token TOP {
        [<Interface> \n+]*
    }

    rule Interface {
        <IfaceNum><colon><IfaceName><ws><inet>
    }

    rule inet {
	inet[6]?\s<ipaddress><param>
    }

#    rule params { <param>* }
    token param {
	<[\w\d.:\s]>+
    }
    token ipaddress {
	<ip>"/"<cidr>
    }

    token ip6 {<[:\d\w]>+}
    token ip {[\d ** 1..3] ** 4 % '.' || <ip6>}
    token cidr { \d **1..3  }

    token IfaceNum  {
	\d+
    }
    token IfaceName {
	\w+
    }

    token ws { <[\s]>* }
    token colon   { \s* ':' \s* }
}
 
class KeyValuePairsActions {
    method TOP ($/) { 
#        for $<Interface>.kv -> $iface,$ips {
#		say "Interface: $iface";
#		for $ips -> $ip {
#			say "\tIp address: $ip";
#		}
#        }

#	say $/;
    }

    method IfaceNum($/){
	say "Iface number: $/";
    }

    method IfaceName($/){
#	say "Iface name: $/";
    }

    method param($/){
	say $/;
    }

    method Interface($/){
	say "Interface: $/";

	my %map;
	%map{$<IfaceName>}.push: $<ipaddress>;
	say %map;
    }

    method inet($/){
#	say "Inet: $/";
    }

   method ipaddress($/){
	say "Ipaddress: $/";
	$/.make: $/;
   }
}
 

my $output = q:x/ip -o addr show/.subst(/\\/,'', :g);
#say $output;

my $res = KeyValuePairs.parse($output, :actions(KeyValuePairsActions)).made; 
 
#say $res;
