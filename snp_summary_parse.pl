#!/usr/bin/env perl
# Author: Zhao
# Date: 2012-12-26
# Purpose:  parse the summary formated result of ncbi snp result

use 5.010;

$file = 'snp_result.txt';
open(IN,$file);
open(O1,">$file.tsv");
open(O2,">$file.fcs");
$/ = "\n\n";
my @selected = (
  'frameshift-variant',
  'upstream-variant-2KB',
  'stop-gained',
  'utr-variant-3-prime',
  'utr-variant-5-prime',
  'splice-donor-variant',
  'missense',
);
while (<IN>) {
  $rc = $_;
  if ($rc =~ /(rs\d+)\s+\[(.+?)\]/) {
    $rs = $1;
    $og = $2;
  } else {
    say 'error 1';
    exit;
  }

  if ($rc =~ /GENE=(\S+)/) {
    $gn = $1;
  } else {
    say 'error 2';
    exit;
  }

  if ($rc =~ /CHR=(\S+)/) {
    $chr= $1;
  } else {
    say 'error 3';
    exit;
  }

  if ($rc =~ /FXN_CLASS=(.*)/) {
    $fc = $1;
  } else {
    say 'error 5';
    exit;
  }

  if ($rc =~ /ALLELE=(.*)/) {
    $al = $1;
  } else {
    say 'error 6';
    exit;
  }

  if ($rc =~ /SNP_CLASS=(.*)/) {
    $sc = $1;
  } else {
    say 'error 7';
    exit;
  }

  if ($rc =~ /CHROMOSOME BASE POSITION=.*:(.*)/) {
    $pos = $1;
  } else {
    say 'error 8';
    exit;
  }

  $f = 0;
  map {$fcs{$_} = defined $fcs{$_} ? $fcs{$_}+1 : 1;$f = 1 if ($_ ~~ @selected);} split(',',$fc);
  say O1 "$rs\t$og\t$gn\t$chr\t$fc\t$al\t$sc\t$pos" if ($f == 1);
}
map {say O2 "$_\t$fcs{$_}"} keys %fcs;
