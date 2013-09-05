#!/usr/bin/env perl
use File::Copy;
$trim = shift;
$to = shift;
$to = '_' unless (defined $trim);
$trim = ' ' unless (defined $trim);
@names = glob '*';
foreach $name (@names) {
  if ($name ~~ /$trim/) {
    $newname = $name;
    $newname =~ s/$trim/$to/g;
    move($name,$newname) unless -e $newname;
    print $name," renamed.\n";
  }
}

