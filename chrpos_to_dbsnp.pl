#!/usr/bin/env perl
# Date: 2014-01-16
# Purpose: 根据chrom和chrpos找到对应位置的rs号
# Author: Zhao

use 5.012;
use lib '/home/zhaorui/bin/lib';
use Ucsc::Schema;
use Data::Dump qw/dump/;
use Data::Table;
use DBI;
use Smart::Comments;

my $mut_file = "ori_list.txt";

my $mt = Data::Table::fromTSV($mut_file);
my $dbh = DBI->connect('dbi:mysql:ucsc_hg19','ucsc','ucsc');
my @array;
foreach my $r ( 0 .. $mt->lastRow) { ### checking [====%    ] done
  my $chr = $mt->elm($r,'Chr');
  my $pos1 = $mt->elm($r,'Pos');
  my $pos2 = $pos1 - 1;
  my $sql = "select name, strand, observed, class, alleles, alleleFreqs,
  alleleNs, valid from snp141 where chrom = '$chr' and chromStart = $pos2
    and chromEnd = $pos1";
  my $ar = $dbh->selectall_arrayref($sql);
  map {push @$_, "snp".($r+1)} @$ar;
  push @array, @$ar;
}
map {say join "\t", @$_} @array;

