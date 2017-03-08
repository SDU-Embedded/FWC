use Text::Table;

my @rows = (); #[qw/1.00 Complete/];

push(@rows, [qw/FTP Internet Gateway/]);
push(@rows, [qw/SSH Zone1 Zone2/]);

print make_table(
    [qw/Protocol Zone_In Zone_Out/],
    \@rows,
);

sub make_table {
    my ( $headers, $rows ) = @_;

    my @rule      = qw(- +);
    my @headers   = \'| ';
    push @headers => map { $_ => \' | ' } @$headers;
    pop  @headers;
    push @headers => \' |';

    unless ('ARRAY' eq ref $rows
        && 'ARRAY' eq ref $rows->[0]
        && @$headers == @{ $rows->[0] }) {
        croak(
            "make_table() rows must be an AoA with rows being same size as headers"
        );
    }
    my $table = Text::Table->new(@headers);
    $table->rule(@rule);
    $table->body_rule(@rule);
    $table->load(@$rows);

    return $table->rule(@rule),
           $table->title,
           $table->rule(@rule),
           map({ $table->body($_) } 0 .. @$rows),
           $table->rule(@rule);
}
