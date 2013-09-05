#!/usr/bin/env perl

$file = shift;
$file =~ s/ /\\ /g;
print "for i in `ls $file`;do ln -s \$i;done\n";
system("for i in `ls $file`;do ln -s \$i;done");
