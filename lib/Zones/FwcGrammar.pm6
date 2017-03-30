use v6;

unit grammar Zones::FwcGrammar;

#grammar Grammar {
token TOP { <zonedef>+ }

token zonedef {<zonename><space>is<space>at<space><ip>["/"<cidr>]? [<space>*]? }
token zonename {[\w]+}
token space {\s+}
token ip {[\d ** 1..3] ** 4 % '.'}
token cidr { \d **1..2  }
#}


#class Actions {
#        method TOP ($/) {
#                my %zones;
#                for  $<zonedef> -> $/ {
#                        %zones.append: $<zonename> => {'ip' => $<ip>, 'cidr' => $<cidr>}
#                }
#
#                $/.make: %zones;
#        }
#
#        method zonedef($/){
#        }
#
#        method zonename($/){
#                $/.make: $/;
#        }
#
#        method ip($/){
#                $/.make: $/;
#        }
#
#        method cidr($/) {
#                $/.make: $/;
#        }
#}
