#!/usr/bin/perl6
unit grammar FwcGrammar;

token TOP { <policy> }
token policy {
	<Header>
	<Rule>*
}

rule Header {
	"Policy" <space> <Protocol>[\{<GlobalOptions>\}]?  <colon> <space>
}

token GlobalOptions {
	<kvpair>*
}

token LocalOptions {
	<kvpair>*
}

token kvpair { 
	<Key=identifier> '=' <Value=word>[',']?
}

token identifier {
	<alpha>* # Only alphabetic characters
}

token word {
	\w+
}

rule Rule {
	<FromZone=word><space> <action><space><ToZone=word>[\{<LocalOptions>\}]?
}

token space {\s*}
token Protocol { <[A..Za..z]>*}
token colon   { \s* ':' \s* }

proto token action {*}
token action:sym<=\>>   { <sym> } # => 
token action:sym<\<=> { <sym> }   # <=
