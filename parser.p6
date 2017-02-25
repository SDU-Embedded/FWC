#!/opt/rakudo-star-2017.01/bin/perl6
use v6.c;

grammar TestGrammar {
	token TOP { <policy> }
	token policy {
		<header>
		<Rule>*
	}

	rule header {
		"Policy" <space> <Protocol> <colon> <space>
	}

	token word {
		\w+	
	}

	rule Rule {
		<FromZone=word> '=>' <ToZone=word>
	}

	token space {\s*}
	token Protocol { <[A..Za..z]>* }
	token colon   { \s* ':' \s* }
}

class TestActions {
    method TOP($/) {
    }
    method Protocol($proto){
	say "Protocol found: $proto"
   }
   method FromZone($zone){
	say "From zone: $zone"
   }

   method ToZone($zone){
	say "To zone: $zone"
   }

   method Rule($rule){
	say "Rule found, from: $rule<FromZone>, to: $rule<ToZone>"
  }
}



# Match files with "policy" extension
my @policy_files = dir("policies/", test => /.*\.policy$/);
my $number_of_policies = @policy_files.elems;
say "Number of policy files found: $number_of_policies";


for @policy_files -> $file {
	my $policy_content =  try slurp($file);
	if ($!) {
	     note "Unable to open and read file,$file, $!";
	}

	my $actions = TestActions.new;
	my $match = TestGrammar.parse($policy_content, :$actions);
	if $match {
#		say "\t Found protocol: $match<protocol>";
#		say $match;
	} else {
		say "no match"
	}
}




