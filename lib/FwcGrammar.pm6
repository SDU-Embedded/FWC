#!/usr/bin/perl6
unit grammar FwcGrammar;

token TOP { <policy> }
token policy {
	<header>
	<Rule>*
}

rule header {
	"Policy" <space> <Protocol>[ \(<GlobalOption>\) ]? <colon> <space>
}

token GlobalOption {
	\d+
}

token LocalOption {
	\w+
}

token word {
	\w+
}

rule Rule {
	<FromZone=word><space> <action><space><ToZone=word>[","\{<LocalOption>\}]?
}

token space {\s*}
token Protocol { <[A..Za..z]>*}
token colon   { \s* ':' \s* }

proto token action {*}
token action:sym<=\>>   { <sym> } # => 
token action:sym<\<=> { <sym> }   # <=
