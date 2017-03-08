use v6.c;

use MyTestModule;

my $test = Grammar.new;

say $test.test();
$test.test;
say $test.test();

$test.parse_policy("cool nok");
