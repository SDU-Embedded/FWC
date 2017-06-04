# IPTables::Match::ip

package IPTables::Match::ip;

use NetAddr::IP;
use NetAddr::IP::Lite qw( :nofqdn );

my $ANY = NetAddr::IP->new( '0.0.0.0/0' );

require IPTables::Match;

use Carp;

@ISA = qw( IPTables::Class IPTables::Match );

use vars qw( %_Allowed %_Required %_Default %_Variable );

# The _build_parse() method constructs an options list for parsing this object from an
# argument vector.

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
	    $self->{neg}->{$1} = 1 if( $name =~ m/^no-([sdf])/ );
	};
    }

    $self->{parse} = [ 
	's|source=s'		=> make_handler( \$self->{s} ),
	'no-s|no-source=s'	=> make_handler( \$self->{s} ),
	'd|destination=s'	=> make_handler( \$self->{d} ),
	'no-d|no-destination=s'	=> make_handler( \$self->{d} ),
	'f|fragment'		=> make_handler( \$self->{f} ),
	'no-f|no-fragment'	=> make_handler( \$self->{f} ),
	];
    return $self;
}

# Clean up / finish off after parsing an object from an argument vector.

sub _after_parse {
    my $self = shift;

##print STDERR "AfterParse called for $self\n";

    # Do the generic variable-fields processing:  identify which potentially variable fields actually are
    my %has_var = $self->_vars();
    push @{$self->{vars}}, map { @{$_}; } values %has_var; 

    # Do the variable-specific processing for each field
    unless( $has_var{s} ) {
	$self->{s} = NetAddr::IP->new( $self->{s}? $self->{s} : $ANY );
    }
    unless( $has_var{d} ) {
	$self->{d} = NetAddr::IP->new( $self->{d}? $self->{d} : $ANY );
    }
    
    return $self;
}

# The argvec() method takes an object and converts it into a vector of
# iptables arguments: in this case, the -s, -d and -f arguments with
# prefix ! if appropriate.

# TODO:  ! -[sd] ANY will not be correctly converted, but illogical anyway

sub argvec {
    my $self = shift;
    my @argv = ( );

    return @argv if( $self->error() );

    @argv = map {
	my @val = ( );
	if( $_ eq 'f' ) {	# Singleton option 
	    @val = ( '-f' ) if( defined( $self->{f} ) && $self->{f} );
	} elsif( $self->{$_} == $ANY ) {
	    @val = ( );
	} else {		# Option with argument
	    @val = ( '-' . $_, $self->{$_} ) if( defined $self->{$_} );
	}
	defined( $self->{neg}->{$_} ) ? ( '!', @val ) : ( @val );
    } qw( s d f );
    return @argv;
}

#----------------------------------------------------------------#

# Implicit match descriptor for iptables -s, -d and -f argments

# Build the class standard components from a class field descriptor
__PACKAGE__->__class( {
    match	=> { t => 'req', m => 'ro', d => '"ip"' },
    type	=> { t => 'req', m => 'ro', d => '"match"' },
    s		=> { t => 'req', m => 'rw', v => 1, },
    d		=> { t => 'req', m => 'rw', v => 1, },
    f		=> { t => 'req', m => 'rw', },
    neg		=> { t => 'req', m => 'rw', d => '{ }', },
    parse	=> { t => 'opt', m => 'ro', },
    vars	=> { t => 'opt', m => 'ao', d => '[ ]', },
    error	=> { t => 'req', m => 'ar', d => '[ ]', },
		      } );

1;
