use strict;
use warnings;

while (my $line = <>) {
    next if $line =~ /^\n/;
    print $line;
}
