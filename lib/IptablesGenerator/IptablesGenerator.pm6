#!/opt/rakudo-star-2017.01/bin/perl6
use v6.c;

use MONKEY-SEE-NO-EVAL; 

# Perl5 compatibility
use Inline::Perl5;

my $p5 = Inline::Perl5.new;
$p5.use('NetAddr::IP');
$p5.use('IPTables');



sub load_protocol($protocol){
	state %protocol_definitions;

	if not %protocol_definitions{$protocol}:exists {
		my $proto_file = "protos/" ~ $protocol ~ ".proto";
#		say "Proto to load: ", $proto_file;
		if $proto_file.IO ~~ :e {
	        	my @proto = lines $proto_file.IO; # Slurp!

			my @iptableLines =  grep(/^\s*iptables/, @proto); # should be combined with map below.
			@iptableLines = map {$_ ~~ s/^\s*iptables\s*//; $_}, @iptableLines;

			%protocol_definitions{$protocol} := @iptableLines;
		} else {
		    say "Protocol $protocol does not exist";
		    return ();
		}
	} else {
		say "Protocol \"$protocol\"already loaded";
	}	
#	say "out:", join(",",%protocol_definitions{$protocol});
	return %protocol_definitions{$protocol};
}

class IptablesGenerator {
	has %!Zones;
	has %!Rules;

	has $!FileHandle;
	has %!UniqProtocols;

	submethod BUILD(:%!Zones, :%!Rules, :$Filename = "Iptables.sh") {
		$!FileHandle = open $Filename, :w;	

		my $header = slurp "template/header.tmpl";
		$!FileHandle.print($header);

	}

        method finishUp {
		my $content = slurp "template/footer.tmpl";
		$!FileHandle.print($content);
	}

	submethod GenerateRules {
		my @rules_to_file;
		for %!Rules.kv -> $from, @rules {
                	my $FromIp = $p5.invoke('NetAddr::IP','new', %!Zones{$from}{'ip'} ~ '/' ~ %!Zones{$from}{'cidr'});
                	for @rules -> $rule {
                	        my ($to, %options) = $rule.kv;
                	        my $protocol = %options<Protocol>;

				%!UniqProtocols{$protocol} = 1;
			}
		}


		for %!UniqProtocols.keys -> $protocol {

			my @content = load_protocol($protocol);
			if @content.elems > 0 {
				my ($port,$alias) = self.GetPortFromServiceName($protocol);
#				print "Loaded protocol: ", @content.elems,"\n";
				my @parsed_objs = map { $p5.invoke("IPTables::Rule","parser",split(' ', $_ ))}, @content;
				for @parsed_objs -> $obj {
					my $test;
					if "SPORT" eq any($obj.vars()) {
#						print "DEBUG: ", $obj.argvec(1),"\n";
						$test = $obj.clone1(CHAIN=> "{$alias}-s2c", SPORT => $port);
	                                        @rules_to_file.push: $test.argvec(1);
					} elsif ( "DPORT" eq any( $obj.vars() ) ) {
						$test = $obj.clone1(CHAIN=> "{$alias}-c2s", DPORT => $port);
	                                        @rules_to_file.push: $test.argvec(1);
					} else {
						print "SPORT or DPORT not found - I got no clue where this rule should be going...";
					}

					my @test = @($obj.match.matches);
#					print "transport protocol: ", @test[2].match(), "\n";


					%!UniqProtocols{$protocol} = TransportProto => @test[2].match();
				}
			}
		}


		self.GenerateClientServerProtoChains();

		$!FileHandle.print("#---------- Create rules --------#\n");
#		print join("\n",@rules_to_file),"\n";
		for @rules_to_file -> $elm {
			$!FileHandle.print($elm ~"\n");
		}
		$!FileHandle.say("#---------- End create rules --------#\n\n");
	}

	method GenerateClientServerProtoChains{
		my @ToBeCreated;
		my %UniqChainNames;

		for %!Rules.kv -> $from, @rules {
                	for @rules -> $rule {
                	        my ($to, %options) = $rule.kv;
                	        my $protocol = %options<Protocol>;

				my ($port,$alias, $transportProto) = self.GetPortFromServiceName($protocol);

				%UniqChainNames{"{$alias}-s2c"} = $protocol;
				%UniqChainNames{"{$alias}-c2s"} = $protocol;

				my $TransportProtocol = %!UniqProtocols{$protocol}{'TransportProto'};
				@ToBeCreated.append( "\$!FileHandle.print\(\"iptables -A {$from}-{$to} -p $TransportProtocol --dport $port -j {$alias}-c2s\\n\"\)" );
				@ToBeCreated.append( "\$!FileHandle.print\(\"iptables -A {$to}-{$from} -p $TransportProtocol --sport $port -j {$alias}-s2c\\n\");" );
			}
		 }

		$!FileHandle.print("#-------- Create proto-client/server chains ------\n");
		for %UniqChainNames.keys -> $chainNames {
			$!FileHandle.print("iptables -N $chainNames\n");
		}

		$!FileHandle.print("#-------- End create proto-client/server chains ------\n\n");

		$!FileHandle.print("#-------- Append protos to proto-client/server chains ------\n");
		for @ToBeCreated -> $rule {
			 EVAL($rule);
		}
		$!FileHandle.print("#-------- End append protos to proto-client/server chains ------\n\n");
	}

	submethod GenerateUniqueChainNames {
		my %FromTo;

		# Generate an unique list of FromZone-ToZone, so that even though we use the same FromZone-ToZone more than once, it will only appear in the iptables-script once.
		for %!Rules.kv -> $from, @rules {
			for @rules -> $rule {
	                        my $to = $rule.key;
				%FromTo{$from ~ "-" ~ $to} = 1;
				%FromTo{$to ~ "-" ~ $from} = 1;
			}
		}


		$!FileHandle.print("#-------- Create zones ------\n");
		for %FromTo.keys -> $FromTo {
			$!FileHandle.print("iptables -N $FromTo\n");
		}
		$!FileHandle.print("#-------- End create zones ------\n\n");
	}

	submethod GenerateChains {
		my %ToBeCreatedNewLocal;
		my %ToBeCreatedAddLocal;

		my %ToBeCreatedNewRemote;
		my %ToBeCreatedAddRemote;

		for %!Rules.kv -> $from, @rules {
                	my $FromIp = $p5.invoke('NetAddr::IP','new', %!Zones{$from}{'ip'} ~ '/' ~ %!Zones{$from}{'cidr'});
                	for @rules -> $rule {
                	        my ($to, %options) = $rule.kv;
                	        my $protocol = %options<Protocol>;

                                my ($port,$alias) = self.GetPortFromServiceName($protocol);
                	        my $ToIp = $p5.invoke('NetAddr::IP','new',%!Zones{$to}{'ip'} ~ '/' ~ %!Zones{$to}{'cidr'});

                	        if %!Zones{$to}{'islocal'} !~~ /true/ and %!Zones{$from}{'islocal'} !~~ /true/ {
                	                %ToBeCreatedAddRemote{"\$!FileHandle.print\(\"iptables -A FORWARD -i %!Zones{$from}{'interface'} -s $FromIp -o %!Zones{$to}{'interface'} -d $ToIp -j {$from}-{$to}\\n\"\)"} = 1;
                	                %ToBeCreatedAddRemote{"\$!FileHandle.print\(\"iptables -A FORWARD -i %!Zones{$to}{'interface'} -s $ToIp -o %!Zones{$from}{'interface'} -d $FromIp -j {$to}-{$from}\\n\"\)"} = 1;

                	        } else {

					if %!Zones{$from}{'islocal'} ~~ /true/ {
	                	                %ToBeCreatedAddLocal{"\$!FileHandle.print\(\"iptables -A INPUT -i %!Zones{$to}{'interface'} -s $ToIp -d $FromIp -j {$to}-{$from}\\n\"\)"} = 1;
	                	                %ToBeCreatedAddLocal{"\$!FileHandle.print\(\"iptables -A OUTPUT -o %!Zones{$from}{'interface'} -s $FromIp -d $ToIp -j {$from}-{$to}\\n\"\)"} = 1;
#						print "$to -> $from\n";
					}
					if %!Zones{$to}{'islocal'} ~~ /true/ {
	                	                %ToBeCreatedAddLocal{"\$!FileHandle.print\(\"iptables -A INPUT -i %!Zones{$from}{'interface'} -s $FromIp -d $ToIp -j {$from}-{$to}\\n\"\)"} = 1;
	                	                %ToBeCreatedAddLocal{"\$!FileHandle.print\(\"iptables -A OUTPUT -o %!Zones{$to}{'interface'} -s $ToIp -d $FromIp -j {$to}-{$from}\\n\"\)"} = 1;
#						print "$from -> $to\n";
					}
                	        }
                	}
        	}


		$!FileHandle.print("#-------- Add zone-chains(Remote) to chains ------\n");
		for %ToBeCreatedAddRemote.keys -> $line {
			EVAL($line);
		}
		$!FileHandle.print("#-------- End add zone-chains(Remote) to chains ------\n\n");



		$!FileHandle.print("#-------- Add zone-chains(Local) to chains ------\n");
		for %ToBeCreatedAddLocal.keys -> $line {
			EVAL($line);
		}
		$!FileHandle.print("#-------- End add zone-chains(Local) to chains ------\n\n");

	}

	submethod ReadIptableFromFile($file){
		my @lines = $file.IO.lines;

		@lines =  grep(/^\s*iptables/, @lines);
                @lines = map {$_ ~~ s/^\s*iptables\s*//; $_}, @lines;

                if ($!) {
                     note "Unable to open and read file, $file, $!";
                }

		return @lines;	
	}

	submethod GenerateSpoofRules {

		my @linesSpoofHeader = self.ReadIptableFromFile("template/spoof/spoof-header.tmpl");
		my @linesSpoofFooter = self.ReadIptableFromFile("template/spoof/spoof-footer.tmpl");
		my @linesSpoofOutput = self.ReadIptableFromFile("template/spoof/spoof-output.tmpl");
		my @linesSpoofPrerouting = self.ReadIptableFromFile("template/spoof/spoof-prerouting.tmpl");
		my @linesSpoofRules = self.ReadIptableFromFile("template/spoof/spoof-rules.tmpl");


                $!FileHandle.print("#------------ Spoof - only allow certain ips to send and receive packets\n");

		# Header - create chains, allow loopback interface'n stuff
		my @parsed_objs = map { $p5.invoke("IPTables::Rule","parser",split(' ', $_ ))}, @linesSpoofHeader;
                for @parsed_objs -> $obj {
			my $j = $obj.clone1(BCAST_SRC=>'0.0.0.0', BCAST_DST => '255.255.255.255');
			my $table = $obj.table();
	                $!FileHandle.print($j.argvec(1) ~" --table " ~ $table ~"\n");
#			print $j.argvec(1) ~" --table " ~ $table ~"\n";
		}

		$!FileHandle.print("#" ~"-" x 64 ~ "\n");

		# Loadin spoof-rules(bogon IPs)
		@parsed_objs = map { $p5.invoke("IPTables::Rule","parser",split(' ', $_ ))}, @linesSpoofRules;
                for @parsed_objs -> $obj {
			my $j = $obj.clone1(BCAST_SRC=>'0.0.0.0', BCAST_DST => '255.255.255.255');
			my $table = $obj.table();
	                $!FileHandle.print($j.argvec(1) ~" --table " ~ $table ~"\n");
#			print $j.argvec(1) ~" --table " ~ $table ~"\n";
		}


		# Generate interface dependent rules
		my @parsed_objs_prerouting = map { $p5.invoke("IPTables::Rule","parser",split(' ', $_ ))}, @linesSpoofPrerouting;
		my @parsed_objs_output = map { $p5.invoke("IPTables::Rule","parser",split(' ', $_ ))}, @linesSpoofOutput;
		for %!Zones.kv -> $zonename, %values {
			my $interface = %values<interface>;
                	my $ip = $p5.invoke('NetAddr::IP','new', %values{'ip'} ~ '/' ~ %values{'cidr'});

#			print $zonename, "IP-range: ", $ip, "\n";

			$!FileHandle.print("#" ~"-" x 64 ~ "\n");
	                for @parsed_objs_output -> $obj {
				my $j = $obj.clone1(BCAST_SRC=>'0.0.0.0', BCAST_DST => '255.255.255.255', IF=>$interface, SOURCE_IP=>$ip);
				my $table = $obj.table();
		                $!FileHandle.print($j.argvec(1) ~" --table " ~ $table ~"\n");
#				print $j.argvec(1) ~" --table " ~ $table ~"\n";
			}


			$!FileHandle.print("#" ~"-" x 64 ~ "\n");
	                for @parsed_objs_prerouting -> $obj {
				my $j = $obj.clone1(BCAST_SRC=>'0.0.0.0', BCAST_DST => '255.255.255.255', IF=>$interface, SOURCE_IP=>$ip);
				my $table = $obj.table();
		                $!FileHandle.print($j.argvec(1) ~" --table " ~ $table ~"\n");
#				print $j.argvec(1) ~" --table " ~ $table ~"\n";
			}


		}


		$!FileHandle.print("#" ~"-" x 64 ~ "\n");

		# Footer - jump if no table match
		@parsed_objs = map { $p5.invoke("IPTables::Rule","parser",split(' ', $_ ))}, @linesSpoofFooter;
                for @parsed_objs -> $obj {
			my $j = $obj.clone1(BCAST_SRC=>'0.0.0.0', BCAST_DST => '255.255.255.255');
			my $table = $obj.table();
	                $!FileHandle.print($j.argvec(1) ~" --table " ~ $table ~"\n");
#			print $j.argvec(1) ~" --table " ~ $table ~"\n";
		}


		$!FileHandle.print("#------------ End spoof - only allow certain ips to send and receive packets\n");
	}

	method GetPortFromServiceName($protocol){
		my ($name, $alias, $port, $proto) = ("",$protocol,"","");
		($name, $alias, $port, $proto) = $p5.call("CORE::getservbyname", $protocol, 'tcp');

		$alias = $protocol if $alias eq 0; # some alias doesn't exist, just use name given in policy-file
		return ($port, $alias);
	}

}
