# IPTables container module

package IPTables;

require IPTables::Class;

use strict;
use vars qw( @ISA );
use Carp;

use Getopt::Long qw( GetOptionsFromArray :config no_ignore_case ); 		# For parsing

@ISA = qw( IPTables::Class );

# ================================================================
# man iptables synopsis
#
# Rules
#        iptables [-t table] -A chain rule-specification
#        iptables [-t table] -I chain [rulenum] rule-specification
#        iptables [-t table] -R chain rulenum rule-specification
#
#        allow -c option and -w modifier
#
# Commands that need the Rule parser
#        iptables [-t table] {-C|-D} chain rule-specification
#
# Commands
#        iptables [-t table] -D chain rulenum
#        iptables [-t table] -S [chain [rulenum]]
#        iptables [-t table] {-F|-L|-Z} [chain [rulenum]] [options...]
#        iptables [-t table] -N chain
#        iptables [-t table] -X [chain]
#        iptables [-t table] -P chain target
#        iptables [-t table] -E old-chain-name new-chain-name
#
#        rule-specification = [matches...] [target]
#        match = -m matchname [per-match-options]
#        target = -j targetname [per-target-options]
#       
# ================================================================

# Standard class instance check hashes

use vars qw( %_Allowed %_Required %_Default );

# Generic inheritable constructor
# Note -- class-provided _init must return $self

sub new {
    my $class = shift;
    my $self  = bless( {}, $class );
    return $self->_init(@_);
}

# _init method for this class: copy in Defaults and arguments; build
# parse hash; check the object; heritable provided we use the
# _Defaults in the package of $self (which implies use of indirect
# references since the calling class is not known at compile time).

sub _init {
    my $self = shift;
    my $class = ref($self);
    my $default;
    my %args = @_;

    do { no strict 'refs';
	 $default = \%{$class . '::_Default'};
    };
    @{$self}{keys %{$default}} = map { &{$_}(); } values %{$default};
    @{$self}{keys %args} = values %args;
    $self->_finalise();
    $self->_build_parse() if( defined $self->{parse} );
    return $self->_check();
}

# Finish off any initialisation after defaults and constructor
# arguments have been copied in.

sub _finalise {
    my $self = shift;

    return $self;
}

# An initialised object must have all mandatory fields, and no
# unexpected fields Field name arguments passed to _check are
# permitted in the object.  Heritable provided we use the _Required
# and _Allowed from the package of $self.  Return $self on success.

sub _check {
    my $self = shift;
    my $class = ref($self);
    my ($allowed,$required);

    do {
	no strict 'refs';
	$allowed = \%{$class . '::_Allowed'};
	$required = \%{$class . '::_Required'};
    };
    my %ok = ( %{$allowed} );
    @ok{@_} = undef if( @_ );  # Add extra permitted field names from argument list

    my @missing = map { exists $self->{$_} ? () : $_; } keys %{$required};
    my @extra   = map { exists $ok{$_} ? () : $_; } keys %{$self};

    carp "Initialising object " . ref($self) . " without required field(s) '" . join("', '", @missing) . "'" if( @missing );
    carp "Initialising object " . ref($self) . " with unexpected field(s) '" . join("', '", @extra) . "'" if( @extra );

    return $self;
}

# Break loops via parse hash.  Heritable.

sub DESTROY {
    my $self = shift;
    
    delete $self->{parse} if( exists($self->{parse}) );
}

#----------------------------------------------------------------#

# Class-specific private methods

# Construct a parse array for an IPTables object.  The array is an input
# to Getopt::Long that will parse the ArgVec and store the results
# properly.  For IPTables objects, it's not used since the Command or
# Rule arrays are used instead.

sub _build_parse {
    my $self = shift;
    my $class = ref($self);

    croak "Calling an illegally inherited _build_parse() in package $class"
	unless( $class eq __PACKAGE__ );
    $self->{parse} = [ ];
    return $self;
}

# Actually parse an ArgVec to fill out a return object.   Heritable.
#
# The procedure is as follows:  
# 1.  locate the parse array for the object;
# 2.  call Getopt::Long parser with ArgVec and parse array
# 3.  handle any errors generated during the parse
#
# An 'error' may represent a termination of the parse in order to load
# a new component; this is signalled by a '##RELOAD##' message
# and results in a new call to the parser.  At the end of the parse,
# all of the arguments should have been consumed.

use vars qw($parsing);

sub _do_parse {
    my $self = shift;
    my $argvec = \@_;
    my $opts = $self->{parse};

    unless( ref($opts) ) {
	$self->error( "Unparseable object" );
	return $self;
    }

    # Keep a globally-accessible note of which object is executing
    # this parse so that extensions can be loaded into its parse
    # array by sub-object options using the _add_to_parse() method.
    local $IPTables::parsing = $self;

    my $res = 0;
    while( !$res ) {
	local $@;

	eval{
	    local $SIG{__WARN__} = sub { die @_; };
	    $res = GetOptionsFromArray( $argvec, @{$self->parse()} )
	};
	chomp $@, $self->error( $@ ) unless( $res || $@ =~ m/##RELOAD##/ );
	unless( $res ) {
	    #print STDERR "Remaining args: '", join("' '", @{$argvec}), "'\n";
	}
    }

    $self->error( "Unconsumed arguments '" . join("' '", @_) . "'" ) if( @_ );
    #print STDERR "Parse result $res\n";
    return $self;
}

# Takes an option list and appends it to the parse array of the
# appropriate object.  The relevant object is $self unless
# $IPTables::parsing is defined, in which case it is that object.
# This can be called in _build_parse() to embed a contained object's
# parsing options or during a _do_parse() action to embed an
# extension.  In the former case, it uses $self whereas in the latter
# the dynamically bound $IPTables::parsing variable refers to the
# object actually parsing arguments in this execution thread.
#
# Watch for _build_parse calls that occur during a _do_parse and want
# to embed objects...  the above won't work in that case; so for the
# latter use call as a class method?

sub _add_to_parser {
    my $self = shift;
    my $parsing = ref($self) ? $self : $IPTables::parsing;

    unless( defined $parsing && defined $parsing->{parse} && ref($parsing->{parse}) ) {
	croak "Attempting to add parsing options to non-parsing object";
	return;
    }
    if( ref( $_[0] ) ) {
	push @{$parsing->{parse}}, @{$_[0]};
    } else {
	push @{$parsing->{parse}}, @_;
    }
    return $self;
}

# If called during a parse, results in a reload of the options array
# by exiting from GetOptions and iterating the loop on _do_parse().
# If not parsing, this is a no-op.
sub _reload_parser {
    my $self = shift;

    die "##RELOAD##" if( defined( $IPTables::parsing ) );
    return $self;
}

#Clean up after parsing using an object
sub _after_parse {
    my $self = shift;

    return $self;
}

# Class-specific public methods

# Parse() class method, takes an argvec and returns a suitable object.
# Calls _do_parse on the object of class $class.  Heritable method.
#
# For IPTables we in fact return either an IPTables::Command or
# IPTables::Rule object depending on the vector being parsed -- this
# is where we decide.  A Rule contains one of the following four
# arguments, o/w Command:
#
#  -A or --append
#  -I or --insert
#  -R or --replace
#  -C or --check
#
#  -D or --delete is traeted as a rule if it is the long form
#
# We also do some pre-processing of the arguments to deal with the
# single '!' characters for negation that iptables sometimes uses.

sub parser {
    my $class = shift;
    my @Args = ();

    return undef if( ref($class) );

    for( my $a = undef ; $a = shift @_; push @Args, $a ) {	# Munge the arguments

	# Deal with ! arguments
	if( $a eq '!' ) {
	    $a = shift @_;
	    return undef unless( defined($a) ); # Can't have ! without something following
	    $a =~ s/^--?/--no-/;		# Change -x to --no-x and --xlong to --no-xlong
	    next;
	}
	
    }    

##print STDERR "Parsing $class with argvec qw( ", join(' ', @Args), ")\n";
    
    if( $class eq 'IPTables' ) {	# Must choose Rule or Command...
	my $n = 0;

	$class = 'IPTables::Command';
	for my $a ( @_ ) {
	    $n++;
	    #print STDERR "Checking arg $n = $a\n";
	    # Identify rules vs. commands
	    if( $a =~ m/^--(?:append|insert|replace|check)$/ ) {
		$class = 'IPTables::Rule';
		last;
	    }
	    if( $a =~ m/^-[AIRC]$/ ) {
		$class = 'IPTables::Rule';
		last;
	    }
	    if( $a eq '--delete' || $a eq '-D' ) {	 # Then check for which form
		$class = 'IPTables::Rule' if( $n+2 == @_ );
		last;
	    }
	}
    }
    my $obj = $class->new( parse => 1 );
    $obj->_do_parse( @Args );	 # Stores parse errors in $obj
    return $obj->_after_parse(); # Returns $obj.
}

# Here we convert the calling object to an argvec, do any substitutions, and reparse the result.

sub clone1 {
    my $self = shift;
    my $class = ref($self);
    my @av = $self->argvec();

    # Handle any substitutions
    if( @_ ) {
	my %subs;

	%subs = (@_ == 1 ? %{$_[0]} : @_);
	@av = map { 
	    IPTables::Class->subst( \%subs, $_ );
	} @av;
    }
    return $class->parser(@av);
}

#----------------------------------------------------------------#

# Debugging:  dump an IPTables object, recursively.

sub __dump {
    my $self = $_[0];
    my $class = ref($self);
    my $indent = $_[1] || 0;
    my $nl = "\n" . (" " x $indent);
    
    sub dumpit {
	my $it = $_[0];
	my $c = ref($_[0]);
	my $indent = $_[1] || 0;
	my $nl = "\n" . (" " x $indent);

	if($c =~ m/^ARRAY/) {
	    return "[" . dumparrayref($it, $indent+5) . $nl . ']';
	} elsif($c =~ m/^HASH/) {
	    return "{" . dumphashref($it, $indent+5) . $nl . '}';
	} elsif($c =~ m/^IPTables/) {
	    return $it->__dump($indent);
	} else {
	    return "$it";
	}
    }
    
    sub dumphashref {
	my $href = shift;
	my $indent = (shift @_) || 0;
	my $nl = "\n" . (" " x $indent);
	my $result = '';
	
	my @keys = @_? ( @_ ) : ( sort keys %{$href} );
	for my $k ( @keys ) {
	    $result .= $nl . $k . $nl . "  => " . dumpit($href->{$k}, $indent+2);
	}
	return $result;
    }

    sub dumparrayref {
	my $aref = $_[0];
	my $indent = $_[1] || 0;
	my $nl = "\n" . (" " x $indent);
	my $result = '';

	for my $i ( @{$aref} ) {
	    $result .= $nl . dumpit($i, $indent);
	}
	return $result;
    }

    if($class !~ m/^IPTables/) {
	carp "__dump method called on non-IPTables object";
	return "";
    }

    # List the object keys in alpha sorted order, _Required then _Allowed
    my $_req;
    do {
	no strict 'refs';
	$_req = \%{$class . "::_Required"};
    };

    my @keys = sort {
	return -1 if( $_req->{$a} && not($_req->{$b}) );
	return  1 if( $_req->{$b} && not($_req->{$a}) );
	return $a cmp $b;
    } keys %{$self};

#    #print STDERR join(" ", map { ($_, $self->{$_}); } @keys), "\n";
    
    return $self . " {" . dumphashref($self, $indent+1, @keys) . $nl . "}";;    
}

# Process the class field descriptor
__PACKAGE__->__class( {
    table		=> { t => 'req', m => 'ro', d => '"filter"' },
    verbose		=> { t => 'opt', m => 'rw', },
    parse		=> { t => 'opt', m => 'ro', },
    error		=> { t => 'req', m => 'ar', d => '[ ]' },
		   } );

# Now require necessary sub-classes...

require IPTables::Rule;

1;

