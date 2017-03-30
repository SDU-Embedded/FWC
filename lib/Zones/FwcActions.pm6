unit class Zones::FwcActions;

method TOP ($/) {
        my %zones;
        for  $<zonedef> -> $/ {
                %zones.append: $<zonename> => {'ip' => $<ip>, 'cidr' => $<cidr>}
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
