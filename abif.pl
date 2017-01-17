#!/usr/bin/env perl
# Date: 2014-10-31
# Author: Zhao
# Purpose: 根据基因及RS编号分析测序结果中的突变
use Bio::Trace::ABIF;
use Data::Dump qw/dump/;
use 5.012;
use Smart::Comments;
use autodie;
use DBI;
# BUG: adjacent SNP cause bug

open my $fh1, '<', 'mutation.txt';
open my $fh2, '>', 'report1.txt';
open my $fh3, '>', 'report2.txt';
while (<$fh1>) {
  chomp;
  my @fds = split "\t", $_;
  my @abif = glob "$fds[0]/*ab1";
  foreach my $file (@abif) {
    my $genotype = abi_gmap_rs($file,$fds[2],$fds[1]);
    say $fh2 join "\t", $file, $fds[2],$fds[1], $genotype;
  }
}

sub abi_gmap_rs {
  my ($file, $rsno,$gene) = @_;
  my $dbh = DBI->connect("dbi:mysql:ucsc_hg38","ucsc","ucsc");
  return unless -f $file;
  my $abif = Bio::Trace::ABIF->new();
  $abif->open_abif($file);

  my $sn = $abif->sample_name(), "\n";
  my @quality_values = $abif->quality_values();
  my $sequence = $abif->sequence();
  my @gmaprv = `echo $sequence |gmap -d hg38 -v snpmap -A -n 0`;
  my @grep = grep {/chr\d+:\d+ +[ATCG]\W+/} @gmaprv;
  return "未检测到SNP位点" if $#grep != 0; # more than one(or no one) line have SNP label
  $grep[0] =~ /chr\d+:(\d+) +([ATCG])/;
  my $pos = $1;
  my $base = $2;
  my $rspos = index($grep[0], $base) - index($grep[0], $pos) - length($pos);
  my $align = join '', @gmaprv;
  if ( $align =~ /$pos .+?\|+ *\n +(\d+)/s) {
    $rspos += $1 - 1;
  }
  system("abiview -infile '$file' -outseq '$sn.seq' -graph png -startbase " .
    ($rspos -3) . " -endbase " . ($rspos + 2) .
    " -gtitle \"pos$rspos $rsno\" -goutfile '$sn' -gxtitle '$sn' > 1");
  $abif->close_abif();
  say $fh3 "测序：$sn";
  say $fh3 "基因：$gene";
  say $fh3 "dbSNP：$rsno";

  my $sql = "select chrom,chromEnd,observed,class,strand
    from snp141 where name = '$rsno'";
  my $rv = $dbh->selectrow_arrayref($sql);
  say $fh3 "位置：$rv->[4]$rv->[0]:$rv->[1]";
  say $fh3 "突变：$rv->[2]";
  say $fh3 "类型：$rv->[3]";
  my $snpbase = substr $sequence, $rspos - 1, 1;
  my $phred_qs = $quality_values[$rspos-1];
  say $fh3 "检测位点质量分数(Phred quality score)：$phred_qs";
  my $genotype;
  if ($phred_qs >= 18) {
    $genotype = "$snpbase$snpbase";
  }
  else {
    $genotype = "测序结果质量太低,无法判断";
  }
  say $fh3 "检测结果：$genotype";
  say $fh3 "测序峰图：";
  say $fh3 "";
  say $fh3 "拼接序列及比对：";
  $align =~ s/.*Alignment for path 1:\n\n//s;
  $align =~ s/(chr\d+:$pos +)$base/$1$rsno/;
  say $fh3 $align;
  return $genotype;
}
