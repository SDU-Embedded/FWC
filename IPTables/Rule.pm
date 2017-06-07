# IPTables::Rule

package IPTables::Rule;

require IPTables;
require IPTables::CED;
require IPTables::Match;
require IPTables::Target;

use strict;
use vars qw( @ISA );

use Carp;

@ISA = qw( IPTables::Class IPTables );

# Standard class instance check hashes

use vars qw( %_Allowed %_Required %_Default %_Variable );

# The finaliser makes sure that the Rule object contains a CED, Match
# and Target when a parseable object is being constructed.  These
# components are the responsibility of the programmer if not parsing.

sub _finalise {
    my $self = shift;

    if( $self->{parse} ) {
	$self->{ced}    = IPTables::CED->new( parse => 1 );
	$self->{match}  = IPTables::Match->new( parse => 1 );
	$self->{target} = IPTables::Target->new( parse => 1 );
    }
    return $self;
}

# The _build_parse() method constructs an options list for parsing this object from an
# argument vector.  The parser for Rule handles the -t argument so that the specified table
# can be correctly copied into the CED and Target sub-objects.

sub _build_parse {
    my $self = shift;
    my $class = ref($self);

    croak "Calling an illegally inherited _build_parse() in package $class"
	unless( $class eq __PACKAGE__ );
    $self->{parse} = [
	't|table=s'	=> \$self->{table},
	];

    # Add in the option parser data from the sub-objects
    for my $o ( $self->{ced}, $self->{match}, $self->{target} ) {
	$self->_add_to_parser( $o->parse() );
    }
    return $self;
}

# The _after_parse() method copies the table data where needed and then recusrively calls the
# _after_parse method for each sub-object

sub _after_parse {
    my $self = shift;

    for my $o ( $self->{ced}, $self->{match}, $self->{target} ) {
	${ $o->_REF_table() } = $self->{table};
	$o->_after_parse();
	push @{$self->{vars}}, $o->vars();
    }

    return $self;
}

# The argvec() method takes a Rule object and converts it into a vector of iptables arguments

sub argvec {
    my $self = shift;
    my @argv = ( );
    my $scalar = shift;
    $scalar = defined($scalar) ? $scalar:0;

    return @argv if( $self->error() );

    @argv = map { $_ ? $_->argvec() : (); } ( $self->{ced}, $self->{match}, $self->{target} );
    unshift(@argv, "--table ".$self->{table} );

    if(wantarray and not $scalar){ # If called in list context
        return @argv;
    } else {
        return "iptables ".join(" ", @argv);
    }
}

#----------------------------------------------------------------#

# An IPTables::Rule object comprises
#
#	-- a chain-edit descriptor
#	-- a match object containing at least an ip and a dev
#	-- a target object containing the optional target

# Build the class standard components from a class field descriptor
__PACKAGE__->__class( {
    table		=> { t => 'req', m => 'ro', d => '"filter"', },
    ced			=> { t => 'req', m => 'ro', },
    match		=> { t => 'req', m => 'ro', },
    target		=> { t => 'req', m => 'ro', },
    error		=> { t => 'req', m => 'ar', d => '[ ]' },
    parse		=> { t => 'opt', m => 'ro', },
    vars		=> { t => 'opt', m => 'ao', d => '[ ]', },
	 } );

1;
