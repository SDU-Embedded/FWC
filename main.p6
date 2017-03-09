#!/usr/bin/perl6
use v6;

use Parser;

my $actions = Parser::Actions.new;


# Match files with "policy" extension
my @policy_files = dir("policies/", test => /.*\.policy$/);
my $number_of_policies = @policy_files.elems;
say "Number of policy files found: $number_of_policies";


for @policy_files -> $file {
        my $policy_content =  try slurp($file);
        if ($!) {
             note "Unable to open and read file,$file, $!";
        }


        my $match = Parser.parse($policy_content, :$actions);
        if $match {
#               say "\t Found protocol: $match<protocol>";
#               say $match;
        } else {
                say "no match"
        }
}

