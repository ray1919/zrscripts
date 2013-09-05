#!/usr/bin/env perl
# Author: Zhao
# Date: 2011-11-22 11:24
# Purpose: Statistics of uniq records in one file

$file = shift;
$has_header = shift;
$cols = shift;

unless (defined $file && -e $file) {
  die "\tUsage: diff1.pl <file> <has_header(0/1)> <cols>\n";
}
$has_header = 0 unless (defined $has_header);

if (defined $cols) {
  # get specifiled cols
  `cut -f$cols $file > /tmp/$file.0`;
}
else{
  `cp $file /tmp/$file.0`;
}

# delete header line
if ($has_header == 1) {
  `sed '1d' /tmp/$file.0 > /tmp/$file.1`;
}
else{
  `cp /tmp/$file.0 /tmp/$file.1`;
}

# delete blank line
`grep ^\$ /tmp/$file.1 -v > /tmp/$file.2`;

# sort the file
`sort /tmp/$file.2 > /tmp/$file.3`;

# count the lines
`uniq -c /tmp/$file.3 > /tmp/$file.4`;

# list duplicated lines
`grep '      1 ' /tmp/$file.4 -v > /tmp/$file.5`;

# statistics
`wc -l /tmp/$file.0` =~ /^(\d+) /;
print "Total lines: $1\n";
`wc -l /tmp/$file.1` =~ /^(\d+) /;
print "Total records: $1\n";
`wc -l /tmp/$file.2` =~ /^(\d+) /;
print "Total records (skip blank lines): $1\n";
`wc -l /tmp/$file.5` =~ /^(\d+) /;
print "duplicated records: $1\n";
`mv /tmp/$file.5 $file.dup.cnt`;
`rm -f /tmp/$file.?`;
