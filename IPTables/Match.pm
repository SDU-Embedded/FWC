# IPTables::Match

package IPTables::Match;

require IPTables;
require IPTables::Match::ip;
require IPTables::Match::dev;

use strict;
use vars qw( @ISA );

use Carp;

@ISA = qw( IPTables::Class IPTables );

use vars qw( %_Allowed %_Required %_Default %_Variable );

# A Match object describes a packet matching fragment of an iptables command
#
# One such object is constructed for a Rule, containing a specialist
# object for each -p or -m clause in the command line.  This object
# class handles those two options.

sub _build_parse {
    my $self = shift;
    my $class = ref($self);

    croak "Calling an illegally inherited _build_parse() in package $class"
	unless( $class eq __PACKAGE__ );

    # Load a protocol match extension, possibly negated
    sub load_protocol {
	my ($self,$name,$proto) = @_;
	my $neg = ($name =~ m/^no-/? 1 : 0);
	my $class = 'IPTables::Match::' . $proto;

	do {
	    local $@ = undef;
	    eval "require $class" or
	    die "Failed to load protocol extension 'IPTables::Match::$proto'";
	};

##print STDERR "Loaded new proto extension $proto\n";

	# Make new parseable protocol extension object
	my $obj = $class->new( match => $proto, parse => 1 );
	push @{$self->{matches}}, $obj;
	if( $obj->type() eq 'proto' ) {
	    $obj->invert($neg) if($neg);	# Mark match as inverted
	} else {
	    carp "Match extension $proto loaded using --protocol flag";
	}	
	IPTables::Match->_add_to_parser( $obj->parse() );
	$self->_reload_parser();
    }

    # Load a match extension
    sub load_match {
	my ($self,$name,$match) = @_;
	my $class = 'IPTables::Match::' . $match;

	do {
	    local $@ = undef;
	    eval "require $class" or
	    die "Failed to load match extension 'IPTables::Match::$match'";
	};

##print STDERR "Loaded new match extension $match\n";

	# Make new parseable match extension object
	my $obj = $class->new( match => $match, parse => 1 );
	carp "Protocol extension $match loaded using --match flag" unless( $obj->type() eq 'match' );
	push @{$self->{matches}}, $obj;
	IPTables::Match->_add_to_parser( $obj->parse() );
	$self->_reload_parser();
    }

    $self->{parse} =  [
	'p|protocol=s'		=> sub { load_protocol($self, @_) },
	'no-p|no-protocol=s'	=> sub { load_protocol($self, @_) },
	'm|match=s'		=> sub { load_match($self, @_) },
	];
    if( $self->{matches} ) {
	for my $o ( @{$self->{matches}} ) {
	    $self->_add_to_parser( $o->parse() );
	}
    }
    return $self;
}

# Clean up / finish off after parsing a Match object.
# Recursively call the after-parse methods on all the match objects.

sub _after_parse {
    my $self = shift;

##print STDERR "AfterParse called for $self\n";
    if( ref($self) eq 'IPTables::Match' ) {
	for my $m ( @{$self->{matches}} ) {
	    $m->_after_parse();
	    push @{$self->{vars}}, $m->vars();
	}
    }
    return $self;
}

# Finalise a Match object.  This involves constructing a set of
# initial match entries for ip and dev, if matches is empty, and
# propagating the _init parse value to those sub-objects.  If building
# a parseable object, _build_parse will add the sub-object options to
# the Match parse array.
#
# Since this is inherited by any IPTables::Match::X object that
# doesn't define its own method, we check the class to ensure the
# inherited version does nothing.

sub _finalise {
    my $self = shift;

    if( ref($self) eq 'IPTables::Match' ) {
	my @parse = $self->{parse}? ( parse => 1 ) : ();

	push @{$self->{matches}}, IPTables::Match::ip->new( @parse );
	push @{$self->{matches}}, IPTables::Match::dev->new( @parse );
    }
    return $self;
}

# Reconstruct the argument vector from a Match object

sub argvec {
    my $self = shift;
    my @argv = ( );

    return @argv if( $self->error() );

    @argv = map { $_->argvec(); } @{$self->{matches}};
    return @argv;
}

#----------------------------------------------------------------#

# Build the class standard components from a class field descriptor
__PACKAGE__->__class( {
	matches => { t => 'req', m => 'ro', d => '[ ]', },
	table   => { t => 'req', m => 'ro', d => '"filter"', },
	parse   => { t => 'opt', m => 'ro', },
	vars	=> { t => 'opt', m => 'ao', d => '[ ]', },
	error   => { t => 'req', m => 'ar', d => '[ ]' },
	 } );

1;
