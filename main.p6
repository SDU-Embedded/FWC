#!/opt/rakudo-star-2017.01/bin/perl6
use v6;

use FwcGrammar;
use FwcActions;


use Text::Table::Simple;

sub dumper(%data){
	my @rows;
        for %data.kv -> $from, $rule {
		my ($to, $options) = $rule.kv;
		my ($option, $value) = $options.kv;

		my $protocol = $options<Protocol>;
		@rows.push: ($protocol, $from, $to, "$option,$value");
        }

	my @headers = ['Protocol','From','To','Options'];
	my @table   = lol2table(@headers,@rows);

	.say for @table;
}




multi MAIN( Str :$policies=".", Int :$verbose = 0, Bool :$dumper = False, Bool :$dump_rules = False ) {  #Named parameters
        say "Policy path: $policies";
        say "Verbose: $verbose" if $verbose > 0;
	say "Dumping rules created from policy files" if $dump_rules;

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
	dumper(%FwcRules) if $dump_rules;
}
