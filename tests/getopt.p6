#!/usr/bin/perl6
use Getopt::Kinoko;
use Getopt::Kinoko::OptionSet;

my OptionSet $opts .= new;
my Int $verbosity = 0;

$opts.insert-normal("h|help=b");
$opts.push-option("version=b");
$opts.push-option("v=b", 0, callback => -> \value{ $verbosity++; } );
$opts.push-option(
    "p|policy=s",
    "policy/",
    comment => "Location to policy files"
);

$opts.push-option(
    "d|definitions=s",
    "zones/",
    comment => "Location to zone policy files"
);

$opts.push-option(
    "dumper=b",
    0,
    comment => "Set to dump policy files in a pretty table"
);

main(getopt($opts));

sub main(@pid) {
    note "Version 0.0.1" if $opts{'version'};


    say "Verbosity: $verbosity" if $opts{'v'};

    if $opts{'h'} {
        note "{$*PROGRAM-NAME} {$opts.usage}\n";
        note(.join("") ~ "\n") if .[1].chars > 1 for $opts.comment(2);
        exit 0;
    }


   if $opts{'p'} {
	my $var = $opts{'p'};
	say "That's a location: $var";
  }

  if $opts{'d'} {
	my $var = $opts{'d'};
	say "That's a location: $var";	
  }
}
