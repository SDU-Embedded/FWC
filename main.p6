#!/opt/rakudo-star-2017.01/bin/perl6
use v6;

use FwcGrammar;
use FwcActions;


use Text::Table::Simple;

my $str1 = "lsd";
my $str2 = "lds";



sub dumper(%data){
	my @rows;
        for %data.kv -> $from, $value {
		my ($to, $options) = $value.kv;
               	say "Key: " ~ $to ~ " value: " ~$options;
		@rows.push: ($from, $to, $options);
        }

	say @rows.perl;
	my @headers = ['From','To','Options'];
#	my @rows    = ((1,2,3,4,5),(1,2,3,4,5),(6,7,8,9,10));
	my @table   = lol2table(@headers,@rows);

	.say for @table;
}




multi MAIN( Str :$policies=".", Int :$verbose = 0, Bool :$dumper = False, Bool :$dump_rules = False ) {  #Named parameters
        say "Policy path: $policies";
        say "Verbose: $verbose";
	say "Dumping rules created from policy files" if $dump_rules;

	my $actions = FwcActions.new;

	# Match files with "policy" extension
	my @policy_files = dir("policies/", test => /.*\.policy$/);
	my $number_of_policies = @policy_files.elems;
	say "Number of policy files found: $number_of_policies";


	my %FwcRules;

	for @policy_files -> $file {
	        my $policy_content =  try slurp($file);
	        if ($!) {
	             note "Unable to open and read file,$file, $!";
	        }


	        my $match = FwcGrammar.parse($policy_content, :$actions).made;

		dumper($match) if $dump_rules;

		#say $match;
#		for @$match -> $p {
#		    say "Key: $p.key()\tValue: $p.value()";
#		}


#	        if $match {
	#               say "\t Found protocol: $match<protocol>";
	#               say $match;
#	        } else {
#	                say "no match"
#	        }
	exit 1;
	}
	say "This code took " ~ (time - CHECK time) ~ "s to compile";
}
