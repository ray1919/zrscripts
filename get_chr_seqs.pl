#!/usr/bin/env perl
# Date: 2014-11-05
# Author: Zhao
# Purpose: get subseq from human genome sequence , hg38

use 5.012;
use Data::Dump qw/dump/;

say get_chr_seqs(shift, shift, shift, shift);

{
  my %chr_seqs;
  sub get_chr_seqs {
    my $chr = shift;
    my $strand = shift;
    my $pos1 = shift;               # 1 based to 0 based
    my $pos2 = shift || $pos1;        # 1 based
    if (defined $chr_seqs{"$chr$strand$pos1$pos2"}) {
      return $chr_seqs{"$chr$strand$pos1$pos2"};
    }
    my $seq = '';
    $chr =~ tr/Cxym/cXYM/;
    my @pos1s = map {$_-1} split(/\D+/,$pos1);
    my @pos2s = split(/\D+/,$pos2);
    return -1 if ($#pos1s != $#pos2s);
    foreach my $i ( 0 .. $#pos1s ) {
      $seq .= get_chr_seq($chr, $pos1s[$i], $pos2s[$i]);
    }
    if ($strand eq '-') {
      $seq = reverse($seq);
      $seq =~ tr/atcgATCG/tagcTAGC/;
    }
    $chr_seqs{"$chr$strand$pos1$pos2"} = $seq;
    return $seq;
  }
}

sub get_chr_seq {
  my $chr = shift;
  my $pos1 = shift; # 0 based
  my $pos2 = shift; # 1 based
  my $path = '/home/zhaorui/ct208/db/genome/ucsc/hg19/'; # hg19 genome seq dir
  # my $path = '/home/zhaorui/ct208/db/genome/ucsc/hg38/'; # hg38 genome seq dir
  return '' if (!-f "$path$chr.fa");
  open(SEQ, "$path$chr.fa") || die $!;
  my $label = <SEQ>;
  my $length = 0;
  my $seq = '';
  while(<SEQ>) {
    chomp;
    $length = length($_);
    if ($pos1 > $length) {
      $pos1 -= $length;
      $pos2 -= $length;
      next;
    }
    elsif ($pos2 < 0) {
      last;
    }
    elsif ($pos1 >= 0 && $pos1 < $length) {
      $seq = substr($_, $pos1, $length - $pos1);
    }
    elsif ($pos2 > 0 && $pos1 < 0) {
      $seq .= $_;
    }
    $pos1 -= $length;
    $pos2 -= $length;
  }

  $seq = substr($seq,0,$pos2 - $pos1);
  return $seq;
}

