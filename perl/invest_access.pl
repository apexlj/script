use strict;
use warnings;

my $file = "access.log";

my $info = {};

open my $fh,'<',$file;
while (my $line = <$fh>) {
	
	next if ($. == 1);

	chomp $line;
	my ($time, $url, $response_time) = split('\s+',$line);
	if ($response_time =~ /(\d+)s$/) {
		$response_time = $1;
	}
	$info->{$time}{count}++;
	$info->{$time}{response_time} += $response_time;
}

close($fh);
my @header = qw/time count response_time_average/;
print join("\t", @header) . "\n";

foreach my $time (keys %$info) {
	my @result = ();
	push @result, $time;
	push @result, $info->{$time}{count};
	push @result, ($info->{$time}{response_time})/($info->{$time}{count});
	print join("\t",@result) . "\n";
}

