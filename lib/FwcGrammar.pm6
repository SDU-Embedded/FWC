unit grammar FwcGrammar;

token TOP { <policy> }
token policy {
	<header>
	<Rule>*
}

rule header {
	"Policy" <space> <Protocol>[ \(<Option>\) ]? <colon> <space>
}

token Option {
	\d+
}

token Option2 {
	\w+
}

token word {
	\w+
}

rule Rule {
	<FromZone=word><space> <action><space><ToZone=word>[","\{<Option2>\}]?
}

token space {\s*}
token Protocol { <[A..Za..z]>*}
token colon   { \s* ':' \s* }

proto token action {*}
token action:sym<=\>>   { <sym> } # => 
token action:sym<\<=> { <sym> }   # <=
