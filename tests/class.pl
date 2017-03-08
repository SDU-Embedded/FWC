use v6.c;


class Grammar {
	has $.test is rw = "cool nok";

	method parse_policy($policy_file){
		say "Hello from parse_policy() with $policy_file";
	}
}



#my $test = Grammar.new;

#say $test.test();
#$test.test;
#say $test.test();

#$test.parse_policy("cool nok");
