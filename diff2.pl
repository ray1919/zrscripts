#!/usr/bin/env perl
$file1 = shift;
$file2 = shift;

if ( !defined $file1 || !defined $file2 ) {
    print "Usage: diff2.pl <file1> <file2>\n";
    exit;
}

$| = 1;
if ( -e $file1 && -e $file2 ) {
    $l1 = &get_line($file1);
    $l2 = &get_line($file2);
    print "\rComputing ...";
    `sort $file1 > /tmp/1.sort`;
    print "\rStep 1 / 7";
    `sort $file2 > /tmp/2.sort`;
    print "\rStep 2 / 7";
    `uniq /tmp/1.sort > /tmp/1.sort.uniq`;
    print "\rStep 3 / 7";
    `uniq /tmp/2.sort > /tmp/2.sort.uniq`;
    print "\rStep 4 / 7";
    $l1uniq = &get_line("/tmp/1.sort.uniq");
    $l2uniq = &get_line("/tmp/2.sort.uniq");
    `cat /tmp/1.sort.uniq /tmp/2.sort.uniq > /tmp/12`;
    print "\rStep 5 / 7";
    `sort /tmp/12 > /tmp/12.sort`;
    print "\rStep 6 / 7";
    `uniq -d /tmp/12.sort > /tmp/12.dup`;
    $dup = &get_line("/tmp/12.dup");
    print "\r$file1            \n";
    $s1 =
        "$l1 ($l1uniq)  |"
      . ( $l1uniq - $dup )
      . "|$dup|"
      . ( $l2uniq - $dup ) . "|  ";
    $s2 = "$l2 ($l2uniq)\n";
    print $s1, $s2;
    print " " x length($s1), "$file2\n";
    unlink("/tmp/1.sort");
    unlink("/tmp/2.sort");
    unlink("/tmp/1.sort.uniq");
    unlink("/tmp/2.sort.uniq");
    unlink("/tmp/12");
    unlink("/tmp/12.sort");
    unlink("/tmp/12.dup");
}

sub get_line {
    my $file = shift;
    `wc -l $file` =~ m/(\d+)\s$file/;
    return $1;
}
