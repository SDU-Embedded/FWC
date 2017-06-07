# IPTables::Target

package IPTables::Target;

require IPTables;
require IPTables::Target::User;

use strict;
use vars qw( @ISA );

use Carp;

@ISA = qw( IPTables::Class IPTables );

use vars qw( %_Allowed %_Required %_Default %_Variable );

# The target parser expects an argument vector that begins with -g or
# -j.  The match parser dispatches the parse to the appropriate module
# sub-parser for -j, and stores the chain for -g.

sub _build_parse {
    my $self = shift;
    my $class = ref($self);

    croak "Calling an illegally inherited _build_parse() in package $class"
	unless( $class eq __PACKAGE__ );

    sub load_target_extn {
	my $self = shift;
	my $target = shift;
	my $class = 'IPTables::Target::' . $target;

	do {
	    local $@ = undef;
	    unless( eval "require $class" ) {
		die("Failed to load 'IPTables::Target::$target'" . ($@? ": " . $@ : ''));
	    }
	};
	
	# Make new parseable match extension object
	my $obj = $class->new( type => $self->{type}, parse => 1 );
	$self->{target} = $obj;
	IPTables::Target->_add_to_parser( $obj->parse() );
	$self->_reload_parser();
    }

    $self->{target} ||= undef;	# Create the field entry for check
    $self->{parse} = [
	'j|jump=s'	=> sub {
	    my ($name,$tgt) = @_;

	    $self->{type} = 'jump';
	    if( $tgt eq uc($tgt) ) { # Upper case is a target or extension
		##print STDERR "Parsing: loading target extension $tgt\n";
		load_target_extn($self, $tgt);
		# Think about special cases for e.g. DROP, ACCEPT that have no options...
	    } else {	# Lower case is a user chain
		$self->{target} = IPTables::Target::User->new(table => $self->{table}, chain => $tgt, type => 'jump');
	    }
	},
	'g|goto=s'	=> sub {
	    my ($name,$tgt) = @_;

	    $self->{type} = 'goto';
	    $self->{target} = IPTables::Target::User->new(table => $self->{table}, chain => $tgt, type => 'goto');
	},
	];
    return $self;
}

# Handle parse post-processing of the target sub-object
sub _after_parse {
    my $self = shift;

    if( $self->{target} ) {
	$self->{target}->_after_parse();
	push @{$self->{vars}}, $self->{target}->vars();
    }
    return $self;
}

sub argvec {
    my $self = shift;
    my @argv = ( );

    return @argv if( $self->error() );

#    return @argv if not (defined ($self->{target})); # hack

    @argv = ( $self->{target}->argvec() );
    
    return @argv;    
}

#----------------------------------------------------------------#

# A Target object describes the target of an iptables rule.
#
# At most one such object is constructed for each rule.  It parses the
# -g or -j option.

# Build the class standard components from a class field descriptor
__PACKAGE__->__class( {
    parse	=> { t => 'opt', m => 'ro', },
    vars	=> { t => 'opt', m => 'ao', d => '[ ]', },
    target	=> { t => 'req', m => 'rw',  }, # req -> opt
    table	=> { t => 'req', m => 'ro', d => '"filter"' },
    type	=> { t => 'req', m => 'rw', d => '"jump"' },
    error	=> { t => 'req', m => 'ar', d => '[ ]' },
	 } );

1;
