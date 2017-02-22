use v6.c;

grammar TestGrammar {
    token TOP { "Policy:" <protocol> }
    token protocol { <[A..Z]>* }
}

class TestActions {
    method TOP($/) {
#       say $/;
#        $/.make($/);
    }
    method protocol($/){
#       say $/;
   }
}




my $policy_content =  try slurp("ssh.policy");
if ($!) {
     note "Unable to open and read file";
}
print "cool nok\n"
#die("end");
#my $actions = TestActions.new;
#my $match = TestGrammar.parse($policy_content, :$actions);
#say $match;         # ｢40｣ 
#say $match.made;    # 42 
