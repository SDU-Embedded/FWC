use v6.c;

grammar TestGrammar {


	token TOP { <policy> }
	token policy {
		<header>
		<rule>*
	}

	rule header {
		"Policy" <space> <Protocol> <colon> <space>
	}

	token word {
		\w+	
	}

	rule rule {
		<FromZone=word> '=>' <ToZone=word>
	}

	token space {\s*}
	token Protocol { <[A..Za..z]>* }
	token colon   { \s* ':' \s* }

#    token TOP { "Policy"<space><protocol><colon>'\n'<space><rules>}


#    token rule {<from>'?'<to>}
#    token rules {<rule>*}

#    token from {<[A..Za..z]>*}
#    token to {<[A..Za..z]>*}
}

class TestActions {
    method TOP($/) {
#       say $/;
#        $/.make($/);
    }
    method Protocol($proto){
	say "Protocol found: $proto"
#       say $/;
   }
   method FromZone($zone){
	say "From zone: $zone"
   }

   method ToZone($zone){
	say "To zone: $zone"
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

#	say $policy_content;
	my $actions = TestActions.new;
	my $match = TestGrammar.parse($policy_content, :$actions);
#	say $match;         # ｢40｣
	if $match {
#		say "\t Found protocol: $match<protocol>";
#		say $match;
	} else {
		say "no match"
	}
}




