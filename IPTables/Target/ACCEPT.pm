# IPTables::Target::ACCEPT

package IPTables::Target::ACCEPT;

require IPTables::Target;

use Carp;

@ISA = qw( IPTables::Class IPTables::Target );

use vars qw( %_Allowed %_Required %_Default %_Variable );

# The _build_parse() method constructs an options list for parsing this object from an
# argument vector.

sub _build_parse {
    my $self = shift;
    my $class = ref($self);

    croak "Calling an illegally inherited _build_parse() in package $class"
	unless( $class eq __PACKAGE__ );

    $self->{parse} = [ 
	];
    return $self;
}

# The _after_parse method 

sub _after_parse {
    my $self = shift;

    return $self;
}

# Finalise construction

sub _finalise {
    my $self = shift;

    return $self;
}

# The argvec() method takes an object and converts it into a vector of
# iptables arguments.

sub argvec {
    my $self = shift;
    my @argv = ( );

    return @argv if( $self->error() );

    @argv = ( "--" . $self->{type}, "ACCEPT" );
    return @argv;
}

#----------------------------------------------------------------#

# Build the class standard components from a class field descriptor
__PACKAGE__->__class( {
    type	=> { t => 'req', m => 'ro', },
    parse	=> { t => 'opt', m => 'ro', },
    vars	=> { t => 'opt', m => 'ao', d => '[ ]', },
    error	=> { t => 'req', m => 'ar', d => '[ ]', },
		      } );

1;
