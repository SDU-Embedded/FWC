# IPTables::Rule

package IPTables::Command;

use IPTables;

use strict;
use vars qw( @ISA );

use Carp;

@ISA = ( 'IPTables' );

use vars qw( %_Allowed %_Required %_Default %_Variable )

# The parse() method constructs an options list for parsing this object from an argument
# vector.

sub _build_parse {
    my $self = shift;
    
    return $self;
}

# The argvec() method takes a Rule object and converts it into a vector of iptables arguments

sub argvec {
    my $self = shift;
    my @argv = ( );

    return @argv;
}

#----------------------------------------------------------------#

# An IPTables::Command object comprises
#
#	-- an optional chain-edit descriptor
#	-- command
#	-- command parameters

# Build the class standard components from a class field descriptor
__PACKAGE__->__class( {
    command		=> { t => 'req', m => 'rw', },
    chain		=> { t => 'opt', m => 'rw', },
    error		=> { t => 'req', m => 'ar', d => '[ ]' },
    parse		=> { t => 'opt', m => 'ro', },
    vars		=> { t => 'opt', m => 'ao', d => '[ ]', },
		      } );

1;
