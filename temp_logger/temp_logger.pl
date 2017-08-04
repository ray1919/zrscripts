#!/usr/bin/env perl

use 5.012;

my $temp = `sensors`;

my $date = `date +%F`;
my $time = `date +%H-%M`;
chomp($date);
chomp($time);

my @temps = ();
while ($temp =~ /: +\+(\d+\.\d+)°C/g ) {
  push @temps, $1;
}
open my $fh1, ">>", "/home/zhaorui/bin/temp_logger/$date.temp.log";

say $fh1 join "\t", $time, @temps;
