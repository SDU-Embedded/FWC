#!/usr/bin/perl6
use v6;
unit class GrammarActions;

   method TOP($/) {
   }
    method Protocol($proto){
        say "Protocol found: $proto"
   }
   method FromZone($zone){
        say "From zone: $zone"
   }

   method Option($opt) {
        say "Option: " ~ $opt;
   }

   method Option2($opt) {
        say "Option: " ~ $opt;
   }
   method action:sym<=\>>($dir){
        print "Direction in\n";
   }

   method action:sym<\<=>($dir){
        print "Direction out\n";
   }
   method ToZone($zone){
        say "To zone: $zone"
   }

   method Rule($rule){
        say "Rule found, from: $rule<FromZone>, to: $rule<ToZone>"
  }


