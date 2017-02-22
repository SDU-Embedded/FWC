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

my $actions = TestActions.new;
my $match = TestGrammar.parse('Policy:SSH', :$actions);
say $match;         # ｢40｣ 
say $match.made;    # 42 
