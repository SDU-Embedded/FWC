use v6;

unit grammar Zones::FwcGrammar;

token TOP { <zonedef>+ }

token zonedef {<zonename>\{<interface>\}<space>is[<space><islocal>]?<space>at<space><ip>["/"<cidr>]? [<space>*]? }
token zonename {[\w]+}
token space {\s+}
token ip {[\d ** 1..3] ** 4 % '.'}
token cidr { \d **1..2  }
token interfaces {
	<interface>+[","]?
}
token interface {
	<[\d\w:]>+
}

proto token islocal {*}
      token islocal:sym<local>   { local }
