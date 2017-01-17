#!/usr/bin/env perl
# Date: 2016-05-13
# Author: Zhao
# Purpose: retrive gene list in each pathway in KEGG, using kegg api

use 5.014;
use Data::Printer;
use LWP::Simple;
use Smart::Comments;

# get list of kegg pathways , human

open my $fh1, '>', "KEGG-PATH.txt";
my $url1 = "http://rest.kegg.jp/list/pathway/mmu";
my $con1 = get($url1);
foreach my $l ( split "\n", $con1 ) { ### retriving [====%       ] done
  my @f = split /\t|:| - /, $l;
  my ($path_id, $path_name) = @f[1,2];
  # get gene list in each path
  my $url2 = "http://rest.kegg.jp/link/mmu/$path_id";
  my $con2 = get($url2);
  foreach my $m ( split "\n", $con2 ) {
    my @g = split /\t|:/, $m;
    say $fh1 join "\t", $path_id, $g[3];
  }
}
### done
