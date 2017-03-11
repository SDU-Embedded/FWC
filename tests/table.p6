use Text::Table::Simple;

my $str1 = "lsd";
my $str2 = "lds";

my @headers = ['func','start','end','diff','avg'];
my @rows    = ((1,2,3,4,5),(1,2,3,4,5),(6,7,8,9,10));
my @table   = lol2table(@headers,@rows);

.say for @table;
