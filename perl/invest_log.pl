use strict;
use warnings;

#read from log file
my $file = "send.log";
open my $fh,'<',$file or die qq{Can't open file $file: $!};

#put result here
my $result_table = [];

my $send_info;

while (my $line = <$fh>) {

	chomp $line;

	if($line =~ /^(\d{2}:\d{2}:\d{2})/) {
		#each record
        $send_info = {};
		$send_info->{time} = $1;
	} elsif ($line =~ /^send:(\d{2})/) {
		$send_info->{send} = $1;
	} elsif ($line =~ /^loss:(\d{2})/) {
		$send_info->{loss} = $1;
		push @$result_table, $send_info;
	}

}

close $fh;

my @header = qw(time send loss);
print join("\t", @header) . "\n";

foreach my $result (@$result_table) {
	my @rec = ($result->{time}, $result->{send}, $result->{loss});
	print join("\t", @rec) . "\n";
}

