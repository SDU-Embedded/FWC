# IPTables::Target::User

package IPTables::Target::User;

require IPTables::Target;

use Carp;

@ISA = qw( IPTables::Class IPTables::Target );

use vars qw( %_Allowed %_Required %_Default %_Variable );

# The _build_parse() method constructs an options list for parsing this object from an
# argument vector.  The Target::User object is never parsed.

sub _build_parse {
    my $self = shift;
    my $class = ref($self);

    croak "Calling an illegally inherited _build_parse() in package $class"
	unless( $class eq __PACKAGE__ );

    $self->{parse} = [ 
	];
    return $self;
}

# The _after_parse method creates a Chain object for the specified chain

sub _after_parse {
    my $self = shift;

    # Do the generic variable-fields processing:  identify which potentially variable fields actually are
    my %has_var = $self->_vars();
    push @{$self->{vars}}, map { @{$_}; } values %has_var;
    
    # Do the variable-specific processing for each field
    unless( $has_var{chain} ) {
	#    $self->{chain} = IPTables::Chain->new(table => $self->{table}, name => $self->{chain} );
    }
    
    return $self;
}

# Finalise construction

sub _finalise {
    my $self = shift;

    return $self;
}

# The argvec() method takes an object and converts it into a vector of
# iptables arguments: it emits the linkage type (jump/goto) and the chain

sub argvec {
    my $self = shift;
    my @argv = ( );

    return @argv if( $self->error() );

    @argv = ( "--" . $self->{type}, "$self->{chain}" );
    return @argv;
}

#----------------------------------------------------------------#

# Build the class standard components from a class field descriptor
__PACKAGE__->__class( {
    table	=> { t => 'req', m => 'ro', },
    chain	=> { t => 'req', m => 'ro', v => 1, },
    type	=> { t => 'req', m => 'ro', },
    parse	=> { t => 'opt', m => 'ro', },
    vars	=> { t => 'opt', m => 'ao', d => '[ ]', },
    error	=> { t => 'req', m => 'ar', d => '[ ]', },
		      } );

1;
