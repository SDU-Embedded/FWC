# IPTables::Chain 

package IPTables::Chain;

use strict;
use vars qw( @ISA %Tables %Chains );

use Carp;

@ISA = ( 'IPTables' );

# Standard class instance check hashes

my (%_Allowed, %_Required, %_Default);

# Package data stores

%Tables = ( );

%Chains = ( );

# Chain object comprises
#    name    -- the name of the chain
#    table   -- the table in which the chain is found

sub _init {
    my $self = shift;
    my %args = @_;

    $args{table} ||= 'filter';
    
    my $cindex = $args{name} . "@" . $args{table};
    
    if( defined $Chains{$cindex} ) {
	$self = $Chains{$cindex};
    } else {
	$Chains{$cindex} = $self;
    }

    # May need to make values accumulate rather than overwrite...
    @{$self}{keys %_Default} = values %_Default;
    @{$self}{keys %args} = values %args;
    carp "Table '$self->{table}' not recognised; valid values are '" . join("' '", keys %Tables) . "'"
	unless( defined $Tables{$self->{table}} );
    $Tables{$self->{table}}->{$self->{name}} = $self;
    return $self->_check();
}

# An initialised object must have all mandatory fields, and no unexpected fields
# Field name arguments passed to _check are permitted in the object.  Heritable.
# Return $self on success.

sub _check {
    my $self = shift;
    my %ok = ( %_Allowed );

    @ok{@_} = undef if( @_ );  # Add extra permitted field names from argument list

    my @missing = map { exists $self->{$_} ? () : $_; } keys %_Required;
    my @extra   = map { exists $ok{$_} ? () : $_; } keys %{$self};

    carp "Initialising object " . ref($self) . " without required field(s) '" . join("', '", @missing) . "'" if( @missing );
    carp "Initialising object " . ref($self) . " with unexpected field(s) '" . join("', '", @extra) . "'" if( @extra );

    return $self;
}

# Unlink the Chain descriptor from the %Table and %Chain tables

sub DESTROY {
    my $self = shift;
    my $cindex = $self->{name} . "@" . $self->{table};
    undef $Chains{$cindex};
    undef $Tables{$self->{table}}->{$self->{name}};
    return 1;
}

#----------------------------------------------------------------#

# Build the class standard components from a class field descriptor
__PACKAGE__->__class( {
    table		=> { t=> 'req', m => 'rw', d => 'filter', },
    chain		=> { t=> 'req', m => 'rw', },
    builtin		=> { t=> 'req', m => 'ro', d => 0, },
	 } );

# Set up built-in chain/table pairs provided by netfilter

my $tables = { filter   => [ qw(INPUT FORWARD OUTPUT) ],
	       nat      => [ qw(PREROUTING OUTPUT POSTROUTING) ],
	       mangle   => [ qw(PREROUTING INPUT FORWARD OUTPUT POSTROUTING) ],
	       raw      => [ qw(PREROUTING OUTPUT) ],
	       security => [ qw(INPUT FORWARD OUTPUT) ] };

for my $t ( keys %{$tables} ) {
    $Tables{$t} = {};
    for my $c ( @{$tables->{$t}} ) {
	IPTables::Chain->new( name => $c, table => $t, builtin => 1 );
    }    
}

1;

