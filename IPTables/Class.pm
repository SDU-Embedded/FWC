package IPTables::Class;

use strict;

use Carp;

#----------------------------------------------------------------#

# Build the class standard components from a class field descriptor
#
# A class field descriptor is a hash where each field name of the
# object is a key whose value is an anonymous hash comprising:
#  t(ype)      - req or not, for whether the field is required
#  m(utator)   - access/update: ro for read-only, wr/rw for read-write, no for none
#  d(efault)   - an optional default initial value
#  v(ariable)  - may contain substitution-variable values
#
# This is called as a class method, so it can be inherited by subclasses.

sub __class {
    my $pkg = shift;
    my $cfd = shift;

    croak "Class establishment method __class() called on an instance!" if( ref($pkg) );

    # Do the code for variable-field processing
    my $code = '';
    $code .= qq{
	package $pkg;
        our \%_Variable = ();
        sub _vars {
	    my \$self = shift;
	    return map {
		my \@v = \$self->__isvar(\$_);
		\@v ? (\$_, \\\@v) : ();
	    } keys \%_Variable;
        }
    };
    eval $code;
    croak "Class establishment method __class code fails for prefix: $@\nCode is:\n$code\n" if( $@ );

    for my $f ( keys %{$cfd} ) {
	my $fd = $cfd->{$f};
	local $@;
	
	$code = '';
	$code = "package $pkg; ";
	$code .= "\$_Allowed{$f} = 1; ";
	$code .= "\$_Required{$f} = 1; " if( $fd->{t} eq 'req' );
	$code .= "\$_Variable{$f} = 1; " if( $fd->{v} );
	$code .= "\$_Default{$f} = sub { return $fd->{d}; }; " if( $fd->{d} );

	# Build an accessor/updater function for this field unless no.
	# If ro, just accessor;  if wr/rw, updater returns new/old value
	unless( $fd->{m} eq 'no') {
	    $code .= "sub $f { my \$self = shift; ";
	    if( $fd->{m} eq 'ro' ) {				# Read-only scalar field, accessor only
		$code .= "carp \"Attempt to write '\$_[0]' to read-only field '$f'\" if(\$_[0]); ";
		$code .= "my \$v = \$self->{$f}; ";
		$code .= "return \$v; }";
	    } elsif( $fd->{m} eq 'wr' ) {			# Write-then-read scalar field
		$code .= "my \$v = \$self->{$f}; ";
		$code .= "\$self->{$f} = \$_[0] if(\$_[0]); return \$_[0] || \$v; }";
	    } elsif( $fd->{m} eq 'rw' ) {			# Read-then-write scalar field
		$code .= "my \$v = \$self->{$f}; ";
		$code .= "\$self->{$f} = \$_[0] if(\$_[0]); return \$v; }";
	    } elsif( $fd->{m} eq 'ar' ) {			# Push-then-read vector field
		$code .= "push \@{\$self->{$f}}, \@_; ";
		$code .= "return \@{\$self->{$f}}; }";
	    } elsif( $fd->{m} eq 'ra' ) {			# Read-then-push vector field
		$code .= "my \@v = \@{\$self->{$f}}; ";
		$code .= "push \@{\$self->{$f}}, \@_; ";
		$code .= "return \@v; }"
	    } elsif( $fd->{m} eq 'ao' ) {			# Read-only vector field
		$code .= "return \@{\$self->{$f}}; ";
		$code .= "}"
	    } else {
		$code .= "carp \"Attempt to write '\$_[0]' to read-only field '$f'\" if(\$_[0]); ";
		$code .= "return \$v; }";
	    }
	}
	# Build a private routine to get a reference to an object field
	# for use by the _build_parse method when storing values.
	$code .= " sub _REF_$f { my \$self = shift; return \\\$self->{$f}; }";

	# Now evaluate the assembled code (in the namespace of the calling class, $pkg).
	eval $code;
	croak "Class establishment method __class code fails for field $f: $@\nCode is:\n$code\n" if( $@ );
    }
}

# Variable substitution delimiters -- pre and pst.

my ($pre,$pst) = qw( %% %% );

# Check whether the field, whose name is provided, contains a substitutable variable;  returns the list of such variables found, if any

sub __isvar {
    my $self = shift;
    my $field = shift;
    local $_ = $self->{$field} || '';
    my @vars = ();

    push @vars, $1 while( m/$pre(\w+)$pst/g );
    return @vars;
}

# Perform variable substitution, given a hash of substituends and a string.

sub subst {
    my $self = shift;
    my $vars = shift;
    local $_ = shift;
    
    s/$pre(\w+)$pst/ defined $vars->{$1} ? $vars->{$1} : "$pre$1$pst" /ge;
    return $_;
}

1;
