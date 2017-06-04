# IPTables::CED

package IPTables::CED;

require IPTables;

use strict;
use vars qw( @ISA );

use Carp;

@ISA = qw( IPTables::Class IPTables );

use vars qw( %_Allowed %_Required %_Default %_Variable );

# The _build_parse() method constructs an options list for parsing this object from an
# argument vector.  For CED, this deals with the following options:
#
# -A|--append <chain>
# -I|--insert <chain> [<ruleno>]
# -R|--replace <chain> <ruleno>
# -D|--delete <chain> [rulenum]
# -C|--check <chain>
#
# -c|--set-counters <p> <b>

sub _build_parse {
    my $self = shift;
    my $class = ref($self);

    croak "Calling an illegally inherited _build_parse() in package $class"
	unless( $class eq __PACKAGE__ );
    ( $self->{command}, $self->{chain} ) = undef; # Will be needed by _after_parse
    $self->{parse} = [
	'append|A=s'             => sub { push @{$self->{ptmp}->{append}}, $_[1];
	},
	'insert|I=s{1,2}'        => sub { push @{$self->{ptmp}->{insert}}, $_[1];
	},
	'replace|R=s{2,2}'       => sub { push @{$self->{ptmp}->{replace}}, $_[1];
	},
	'delete|D=s{1,2}'        => sub { push @{$self->{ptmp}->{delete}}, $_[1];
	},
	'check|C=s'              => sub { push @{$self->{ptmp}->{check}}, $_[1];
	},
	'c|set-counters=o{2,2}'  => sub { push @{$self->{knt}}, $_[1];
	},
	];
    return $self;
}

# Do object-specific processing;  allow processing of variable-containing fields to be deferred

sub _after_parse {
    my $self = shift;

    ##print STDERR "AfterParse called for $self\n";

    do  {
	my @k;

	@k = keys %{$self->{ptmp}} if( defined $self->{ptmp} );
	unless( @k ) {
	    push @{$self->{error}}, "IPTables::CED object without defined command";
	    return $self;
	}
	if( @k > 1 ) {
	    push @{$self->{error}}, "IPTables::CED object with multiple commands: '" . join("', '", @k) . "'";
	    return $self;
	}
	$self->{command} = $k[0];
	( $self->{chain}, $self->{ruleno} ) = ( @{$self->{ptmp}->{$k[0]}} );
	delete $self->{ptmp};
	delete $self->{ruleno} unless( $self->{ruleno} );
    };

    # Do the generic variable-fields processing:  identify which potentially variable fields actually are
    my %has_var = $self->_vars();
    push @{$self->{vars}}, map { @{$_}; } values %has_var;
    
    # Process the chain's name
    unless( $has_var{chain} ) {
		# Do it now
    }
    
    return $self;
}

# The argvec() method takes a CED object and converts it into a vector of iptables arguments

sub argvec {
    my $self = shift;
    my @argv = ( );

    return @argv if( $self->error() );

    push @argv, "--" . $self->{command}, $self->{chain};
    push @argv, $self->{ruleno} if( $self->{ruleno} );
    push @argv, "-c", @{$self->{knt}} if( @{$self->{knt}} );
    return @argv;
}

#----------------------------------------------------------------#

# An IPTables::CED (chain edit descriptor) object comprises
#
#	-- 
#	-- 
#	-- 

# Build the class standard components from a class field descriptor
__PACKAGE__->__class( {
    table		=> { t => 'req', m => 'rw', d => '"filter"' },
    chain		=> { t => 'req', m => 'rw', v => 1, },
    ruleno		=> { t => 'opt', m => 'rw', },
    knt		        => { t => 'opt', m => 'ar', d => '[ ]' },
    command		=> { t => 'req', m => 'rw', },
    parse		=> { t => 'opt', m => 'ro', },
    vars		=> { t => 'opt', m => 'ao', d => '[ ]', },
    error		=> { t => 'req', m => 'ar', d => '[ ]' },
	 } );

1;
