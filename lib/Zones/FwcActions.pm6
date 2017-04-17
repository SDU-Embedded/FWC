unit class Zones::FwcActions;

method TOP ($/) {
        my %zones;
        for  $<zonedef> -> $/ {
                %zones.append: $<zonename> => {'interface' =>  $<interface>, 'location' => $<location>,'ip' => $<ip>, 'cidr' => $<cidr>}
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
method location:sym<local>($/){
#	say "\t\tLocation: $/";
	$/.make: "local";
}
