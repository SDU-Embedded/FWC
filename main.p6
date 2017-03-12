#!/opt/rakudo-star-2017.01/bin/perl6
use v6;

use FwcGrammar;
use FwcActions;

use MONKEY-SEE-NO-EVAL;
use Text::Table::Simple;

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
	my @table   = lol2table(@headers,@rows);

	if $format eq "table" {
		.say  for @table;
	}

	if $format eq "json" {
		my $filename = "out.json";

		my $fh = open $filename, :w;
		$fh.say('{');
		$fh.say('"FWC":[');
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
		$fh.say("$output]");
		$fh.say('}');
		$fh.close;
	}
}




multi MAIN( Str :$policies=".", Int :$verbose = 0, Bool :$dumper = False, Bool :$dump_rules = False, Str :$dump_format = "table" ) {  #Named parameters
        say "Policy path: $policies";
        say "Verbose: $verbose" if $verbose > 0;
	say "Dumping rules to $dump_format" if $dump_rules;

	my $actions = FwcActions.new;

	# Match files with "policy" extension
	my @policy_files = dir($policies, test => /.*\.policy$/);
	my $number_of_policies = @policy_files.elems;
	say "Number of policy files found: $number_of_policies";


	my %FwcRules;

	for @policy_files -> $file {
	        my $policy_content =  try slurp($file);
	        if ($!) {
	             note "Unable to open and read file,$file, $!";
	        }

	        %FwcRules.append: FwcGrammar.parse($policy_content, :$actions).made;
	}
	dumper(%FwcRules, $dump_format) if $dump_rules;
}
