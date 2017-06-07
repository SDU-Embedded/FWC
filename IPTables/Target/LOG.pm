# IPTables::Target::LOG

package IPTables::Target::LOG;

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
	'log-prefix=s' => \$self->{prefix},
	'log-level=s' => \$self->{level},
	];
    return $self;
}

# The _after_parse method checks for legal rejection prefixs

sub _after_parse {
    my $self = shift;

#    if( $self->{prefix} ) {
	# log-prefix, log-level
	# icmp-((host|net|port|proto)-unreachable|(host|net|admin)-prohibited)
#	if( $self->{prefix} !~ m/^log-(prefix|level)$/ ) {
#	$self->error( "Unrecognised LOG type '$self->{prefix}'" );
#	}
#    }

    return $self;
}

# Finalise construction

sub _finalise {
    my $self = shift;

    return $self;
}

# The argvec() method takes an object and converts it into a vector of
# iptables arguments: it emits the linkage prefix and the rejection method if given

sub argvec {
    my $self = shift;
    my @argv = ( );

    return @argv if( $self->error() );

    @argv = ( "--" . $self->{type}, "LOG", ($self->{prefix}? ( '--log-prefix', $self->{prefix} ) : () ) );
    push @argv, ( "--" . $self->{type}, "LOG", ($self->{level}? ( '--log-level', $self->{level} ) : () ) );
    return @argv;
}

#----------------------------------------------------------------#

# Build the class standard components from a class field descriptor
__PACKAGE__->__class( {
    type	=> { t => 'req', m => 'ro', },
    prefix	=> { t => 'opt', m => 'ro', },
    level	=> { t => 'opt', m => 'ro', },
    parse	=> { t => 'opt', m => 'ro', },
    vars	=> { t => 'opt', m => 'ao', d => '[ ]', },
    error	=> { t => 'req', m => 'ar', d => '[ ]', },
		      } );

1;
