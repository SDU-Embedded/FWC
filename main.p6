#!/opt/rakudo-star-2017.01/bin/perl6
use v6.c;

use lib "./lib";

# Perl5 compatibility
use Inline::Perl5; my $p5 = Inline::Perl5.new; $p5.use('NetAddr::IP');

use Policies::FwcGrammar; use Policies::FwcActions;

use Zones::FwcActions; use Zones::FwcGrammar;

use MONKEY-SEE-NO-EVAL; use Text::Table::Simple;


multi MAIN( Str :$policies=".", Str :$zones=".", Int :$verbose = 0, Bool :$dumper = False, Bool :$dump_rules = False, Str :$dump_format = "table" ) { #Named parameters
        note "Policy path: $policies";
	note "Zone path: $zones";
        note "Verbose: $verbose" if $verbose > 0;
	note "Dumping rules to $dump_format" if $dump_rules;

	# Match files with "policy" extension
	my @policy_files = dir($policies, test => /.*\.policy$/);
	my $number_of_policies = @policy_files.elems;
	note "Number of policy files found: $number_of_policies";


	# Match files with "zone" extension
	my @zone_files = dir($zones, test => /.*\.zone$/);
	my $number_of_zones = @zone_files.elems;
	note "Number of zones files found: $number_of_zones";

	# Loop through all zone files, parse and append
	my %FwcZones;
	for @zone_files -> $file {
	        my $zone_content = try slurp($file);
	        if ($!) {
	             note "Unable to open and read file, $file, $!";
	        }
		%FwcZones.append: Zones::FwcGrammar.parse($zone_content, actions => Zones::FwcActions.new).made
	}
	dumpZones(%FwcZones);

	# Loop through all policy files, parse and append
	my (%FwcRules, %FwcAllZones);
	for @policy_files -> $file {
	        my $policy_content = try slurp($file);
	        if ($!) {
	             note "Unable to open and read file,$file, $!";
	        }

		my %rules = Policies::FwcGrammar.parse($policy_content, actions=> Policies::FwcActions.new).made;
	        %FwcRules.append: %rules<Rules>[0];
		%FwcAllZones.append: %rules<AllZones>[0];
	}
	dumper(%FwcRules, $dump_format) if $dump_rules;

	note "Number of zones: ", %FwcZones.elems;
	note "Number of policies: ", %FwcAllZones.elems;

	# Error checking
	for keys %FwcAllZones -> $key {
		if %FwcZones{$key}:exists {
			#say "\t$key does exist";
		} else {
			 note "\t\"$key\" is not a defined zone";
		}
	}

	for keys %FwcZones -> $key {
		if %FwcAllZones{$key}:exists {
			#say "\t$key does exist";
		} else {
			note "\t\"$key\" is defined but not used";
		}
	}


	IptablesGeneratePolicies(%FwcZones, %FwcRules);
}

sub IptablesGeneratePoliciesStdout(%FwcZones, %FwcRules){
        for %FwcRules.kv -> $from, @rules {
	        my $FromIp = $p5.invoke('NetAddr::IP','new', %FwcZones{$from}{'ip'} ~ '/' ~ %FwcZones{$from}{'cidr'});
                for @rules -> $rule {
                        my ($to, %options) = $rule.kv;
                        my $protocol = %options<Protocol>;

			my ($name, $alias, $port, $proto) = $p5.call("CORE::getservbyname", $protocol, 'tcp');
#			say "From: $from %FwcZones{$from}{'ip'}, To $to %FwcZones{$to}{'ip'}, Protocol: $protocol, Port: $port";
		        my $ToIp = $p5.invoke('NetAddr::IP','new',%FwcZones{$to}{'ip'} ~ '/' ~ %FwcZones{$to}{'cidr'});

			say "%FwcZones{$from}{'ip'} DNAT to %FwcZones{$to}{'ip'}, port $port" unless $ToIp.contains($FromIp);
#			say "iptables -t nat -A POSTROUTING -o world -j MASQUERADE" unless $ToIp.contains($FromIp);
			if %FwcZones{$to}{'islocal'} !~~ /true/ {
				say "iptables -A FORWARD -s $FromIp -i %FwcZones{$from}{'interface'} -d $ToIp -o %FwcZones{$to}{'interface'} -p tcp --dport $port";
				say "iptables -A FORWARD -d $FromIp -o %FwcZones{$from}{'interface'} -s $ToIp -i %FwcZones{$to}{'interface'} -p tcp --sport $port";
			} else {
				say "iptables -A INPUT -s $FromIp -i %FwcZones{$from}{'interface'} -d $ToIp -o %FwcZones{$to}{'interface'} -p tcp --dport $port";
				say "iptables -A OUTPUT -d $FromIp -o %FwcZones{$from}{'interface'} -s $ToIp -i %FwcZones{$to}{'interface'} -p tcp --sport $port";
			}
                }
        }
}



sub IptablesGeneratePolicies(%FwcZones, %FwcRules){
	my $fh = open "IptablesPolicies.sh", :w;
	$fh.print("#!/bin/bash\n");

	for %FwcRules.kv -> $from, @rules {
                my $FromIp = $p5.invoke('NetAddr::IP','new', %FwcZones{$from}{'ip'} ~ '/' ~ %FwcZones{$from}{'cidr'});
                for @rules -> $rule {
                        my ($to, %options) = $rule.kv;
                        my $protocol = %options<Protocol>;

                        my ($name, $alias, $port, $proto) = $p5.call("CORE::getservbyname", $protocol, 'tcp');
#                       say "From: $from %FwcZones{$from}{'ip'}, To $to %FwcZones{$to}{'ip'}, Protocol: $protocol, Port: $port";
                        my $ToIp = $p5.invoke('NetAddr::IP','new',%FwcZones{$to}{'ip'} ~ '/' ~ %FwcZones{$to}{'cidr'});

                        say "%FwcZones{$from}{'ip'} DNAT to %FwcZones{$to}{'ip'}, port $port" unless $ToIp.contains($FromIp);
#                       say "iptables -t nat -A POSTROUTING -o world -j MASQUERADE" unless $ToIp.contains($FromIp);
                        if %FwcZones{$to}{'islocal'} !~~ /true/ {
				$fh.say("# -----------------------REMOTE--------------------");
				$fh.print("sudo iptables -N $from-$to\n");
				$fh.print("sudo iptables -N $to-$from\n");
				$fh.print("sudo iptables -A FORWARD -j $from-$to\n");
				$fh.print("sudo iptables -A FORWARD -j $to-$from\n");
				$fh.say("# -----------------------REMOTE END--------------------");
#                                say "iptables -A FORWARD -s $FromIp -i %FwcZones{$from}{'interface'} -d $ToIp -o %FwcZones{$to}{'interface'} -p tcp --dport $port"; say "iptables -A FORWARD -d $FromIp -o %FwcZones{$from}{'interface'} -s $ToIp -i 
#                                %FwcZones{$to}{'interface'} -p tcp --sport $port";
                        } else {
				$fh.say("# -----------------------LOCAL--------------------");
				$fh.print("sudo iptables -N $from-$to\n");
				$fh.print("sudo iptables -N $to-$from\n");
				$fh.print("sudo iptables -A INPUT -j $from-$to\n");
				$fh.print("sudo iptables -A OUTPUT -j $to-$from\n");
				$fh.say("# -----------------------LOCAL END--------------------");
#                                say "iptables -A INPUT -s $FromIp -i %FwcZones{$from}{'interface'} -d $ToIp -o %FwcZones{$to}{'interface'} -p tcp --dport $port"; say "iptables -A OUTPUT -d $FromIp -o %FwcZones{$from}{'interface'} -s $ToIp -i 
#                                %FwcZones{$to}{'interface'} -p tcp --sport $port";
                        }
                }
        }

	$fh.close;
}

sub dumper(%data, $format = "table"){
	my @rows;
        for %data.kv -> $from, @rules {
		for @rules -> $rule {
			my ($to, %options) = $rule.kv;

			my $protocol = %options<Protocol>;
			%options<Protocol>:delete;

			@rows.push: ($protocol, $from, $to, %options.perl);
		}
        }

	my @headers = ['Protocol','From','To','Options'];
	my @table = lol2table(@headers,@rows);

	if $format eq "table" {
		.note for @table;
	}

	if $format eq "json" {
		say('{"FWC":[');
		my $output;
		for @rows -> $row {
			$output ~= '{';
			my Int $i = 0;
			my %options = EVAL($row[3]);
			for @headers -> $head {
				if $head eq "Options" {
					$output~= '"Options": {';
					for %options.kv -> $key, $value {
						$output ~= "\"$key\":\"$value\","
					}
					$output = chop($output);
					$output~= '},';
				} else {
					$output~="\"$head\":\"$row[$i++].subst(/\"/, "'",:g)\",";
				}
			}
			$output =chop($output);
			$output ~= '},';
		}
		$output = chop $output;
		say("$output]}");
	}
}


sub dumpZones(%FwcZones){
	my @rows;
	for %FwcZones.kv -> $zonename, $ip {
		$ip{'cidr'} = '-' unless $ip{'cidr'};
		@rows.push: ($zonename, $ip{'interface'},$ip{'islocal'},$ip{'ip'}, $ip{'cidr'});
	}


	my @headers = ['Zone name','Interface','IsLocal','IP','CIDR'];
	my @table = lol2table(@headers,@rows);

	.note for @table;
}

