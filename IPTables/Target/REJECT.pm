# IPTables::Target::REJECT

package IPTables::Target::REJECT;

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
	'reject-with=s' => \$self->{mode},
	];
    return $self;
}

# The _after_parse method checks for legal rejection modes

sub _after_parse {
    my $self = shift;

    if( $self->{mode} ) {
	if( $self->{mode} !~ m/^icmp-((host|net|port|proto)-unreachable|(host|net|admin)-prohibited)$/ ) {
	$self->error( "Unrecognised REJECTion type '$self->{mode}'" );
	}
    }

    return $self;
}

# Finalise construction

sub _finalise {
    my $self = shift;

    return $self;
}

# The argvec() method takes an object and converts it into a vector of
# iptables arguments: it emits the linkage mode and the rejection method if given

sub argvec {
    my $self = shift;
    my @argv = ( );

    return @argv if( $self->error() );

    @argv = ( "--" . $self->{type}, "REJECT", 
	      ($self->{mode}? ( '--reject-with', $self->{mode} ) : () )
	);
    return @argv;
}

#----------------------------------------------------------------#

# Build the class standard components from a class field descriptor
__PACKAGE__->__class( {
    type	=> { t => 'req', m => 'ro', },
    mode	=> { t => 'opt', m => 'ro', },
    parse	=> { t => 'opt', m => 'ro', },
    vars	=> { t => 'opt', m => 'ao', d => '[ ]', },
    error	=> { t => 'req', m => 'ar', d => '[ ]', },
		      } );

1;
