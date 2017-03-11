#!/opt/rakudo-star-2017.01/bin/perl6
use v6;

use FwcGrammar;
use FwcActions;




multi MAIN( Str :$policies=".", Int :$verbose = 0, Bool :$dumper = False ) {  #Named parameters
        say "Policy path: $policies";
        say "Verbose: $verbose";


	my $actions = FwcActions.new;

	# Match files with "policy" extension
	my @policy_files = dir("policies/", test => /.*\.policy$/);
	my $number_of_policies = @policy_files.elems;
	say "Number of policy files found: $number_of_policies";


	for @policy_files -> $file {
	        my $policy_content =  try slurp($file);
	        if ($!) {
	             note "Unable to open and read file,$file, $!";
	        }


	        my $match = FwcGrammar.parse($policy_content, :$actions).made;


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
