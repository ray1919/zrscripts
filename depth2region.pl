#!/usr/bin/env perl
# Author: Zhao
# Date: 2018-09-18
# Purpose: convert continues positions in samtools depth output into regions


use 5.012;

my ($chr, $pos1, $pos2);

# parse first line

my $line = <STDIN>;
my @fields = split "\t", $line;
$chr = $fields[0];
$pos1 = $fields[1];
$pos2 = $fields[1];

while(<STDIN>) {
    my @fields = split "\t", $_;
    if ( $chr eq $fields[0] and $pos2 == $fields[1] - 1 ) {
        $pos2 = $fields[1];
    } else {
        say "$chr:$pos1-$pos2";
        $chr = $fields[0];
        $pos1 = $fields[1];
        $pos2 = $fields[1];
    }
}
say "$chr:$pos1-$pos2";
