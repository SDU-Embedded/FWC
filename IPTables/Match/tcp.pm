# IPTables::Match::tcp

package IPTables::Match::tcp;

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
	    $self->{neg}->{$1} = 1 if( $name =~ m/^no-([sd])/ );
	};
    }

    $self->{parse} = [ 
	'sport|source-port=s'			=> make_handler( \$self->{sport} ),
	'no-sport|no-source-port=s'		=> make_handler( \$self->{sport} ),
	'dport|destination-port=s'		=> make_handler( \$self->{dport} ),
	'no-dport|no-destination-port=s'	=> make_handler( \$self->{dport} ),
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
    unless( $has_var{sport} ) {

    }
    unless( $has_var{dport} ) {

    }
    
    return $self;
}

# The argvec() method takes an object and converts it into a vector of
# iptables arguments: in this case, the --sport and --dport arguments with
# prefix ! if appropriate.

sub argvec {
    my $self = shift;
    my @argv = ( );

    return @argv if( $self->error() );

    @argv = ('-p', 'tcp',
	     map {
		 my @val = ( );
		 @val = ( '--' . $_, $self->{$_} ) if( defined $self->{$_} );
		 defined( $self->{neg}->{$_} ) ? ( '!', @val ) : ( @val );
	     } qw( sport dport )
	);
    return @argv;
}

#----------------------------------------------------------------#

# Implicit match descriptor for iptables -s, -d and -f argments

# Build the class standard components from a class field descriptor
__PACKAGE__->__class( {
    match	=> { t => 'req', m => 'ro', d => '"tcp"' },
    type	=> { t => 'req', m => 'ro', d => '"proto"' },
    sport	=> { t => 'req', m => 'rw', v => 1, },
    dport	=> { t => 'req', m => 'rw', v => 1, },
    neg		=> { t => 'req', m => 'rw', d => '{ }', },
    parse	=> { t => 'opt', m => 'ro', },
    vars	=> { t => 'opt', m => 'ao', d => '[ ]', },
    error	=> { t => 'req', m => 'ar', d => '[ ]', },
		      } );

1;
