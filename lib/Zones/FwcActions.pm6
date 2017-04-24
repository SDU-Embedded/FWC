unit class Zones::FwcActions;

method TOP ($/) {
        my %zones;
        for  $<zonedef> -> $/ {
                %zones.append: $<zonename> => {'interface' =>  $<interface>, 'islocal' => ($<islocal>.made ?? "true" !! "false"),'ip' => $<ip>, 'cidr' => $<cidr>}
        }

        $/.make: %zones;
}

method zonedef($/){
}

method zonename($/){
        $/.make: $/;
}

method ip($/){
        $/.make: $/;
}

method cidr($/) {
        $/.make: $/;
}

method interface($/){
	$/.make: $/;
}
method islocal:sym<local>($/){
	$/.make: "true";
}
