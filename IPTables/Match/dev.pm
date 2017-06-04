# IPTables::Match::dev

package IPTables::Match::dev;

require IPTables::Match;

use Carp;

@ISA = qw( IPTables::Class IPTables::Match );

use vars qw( %_Allowed %_Required %_Default %_Variable );

# The _build_parse() method constructs an options list for parsing this object from an
# argument vector.
#
# Handle the -i and -o arguments, their long forms and their --no-
# prefixes.  The anonymous handler routine sets the neg{} field for a
# negated option.

sub _build_parse {
    my $self = shift;
    my $class = ref($self);

    croak "Calling an illegally inherited _build_parse() in package $class"
	unless( $class eq __PACKAGE__ );

    # Store option values in the object
    sub make_handler {
	my $loc = shift;

	return sub {
	    my ($name,$val) = @_;

	    ${$loc} = $val;
	    $self->{neg}->{$1} = 1 if( $name =~ m/^no-([io])/ );
	};
    }

    $self->{parse} = [
	'i|in-interface=s'	      => make_handler( \$self->{i} ),
	'no-i||no-in-interface=s'     => make_handler( \$self->{i} ),
	'o|out-interface=s'	      => make_handler( \$self->{o} ),
	'no-o|no-out-interface=s'     => make_handler( \$self->{o} ),
	];
    return $self;
}

# The _after_parse method just handles variable substitutions

sub _after_parse {
    my $self = shift;

    # Do the generic variable-fields processing:  identify which potentially variable fields actually are
    my %has_var = $self->_vars();
    push @{$self->{vars}}, map { @{$_}; } values %has_var;
    
    # Do the variable-specific processing for each field -- there is no specific work to

    # Process the input iface's name
    unless( $has_var{i} ) {
	# Defer the processing until after substitution
    } 

    unless( $has_var{o} ) {
	# Defer the processing until after substitution
    } 

    return $self;
}

# The argvec() method takes an object and converts it into a vector of
# iptables arguments.  Here it outputs the in and out interfaces with
# !prefix as appropriate.

sub argvec {
    my $self = shift;
    my @argv = ( );

    return @argv if( $self->error() );

    @argv = map {
	my @val = ( );
	@val = ( '-' . $_, $self->{$_} ) if( defined $self->{$_} );
	defined( $self->{neg}->{$_} ) ? ( '!', @val ) : ( @val );
    } qw( i o );
    return @argv;
}

#----------------------------------------------------------------#

# Implicit match descriptor for iptables -i and -o argments

# Build the class standard components from a class field descriptor
__PACKAGE__->__class( {
    match	=> { t => 'req', m => 'ro', d => '"dev"' },
    type	=> { t => 'req', m => 'ro', d => '"match"' },
    i		=> { t => 'req', m => 'rw', v => 1, },
    o		=> { t => 'req', m => 'rw', v => 1, },
    neg		=> { t => 'req', m => 'rw', d => '{ }' },
    parse	=> { t => 'opt', m => 'ro', },
    vars	=> { t => 'opt', m => 'ao', d => '[ ]' },
    error	=> { t => 'req', m => 'ar', d => '[ ]' },
	 } );

1;
