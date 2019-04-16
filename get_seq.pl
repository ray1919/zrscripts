#!/usr/bin/env perl
# Author: Zhao
# Date: 2012-12-3
# Note: 0 based position
use 5.010;

$a = get_chr_seqs('chr20','+','61747568','61750559');
say $a;

sub get_chr_seqs {
  my $chr = shift;
  my $strand = shift;
  my $pos1 = shift; # 0 based
  my $pos2 = shift || $pos1 + 1; # 1 based
  my $seq = '';
  my @pos1s = split(',',$pos1);
  my @pos2s = split(',',$pos2);
  return -1 if ($#pos1s != $#pos2s);
  foreach my $i ( 0 .. $#pos1s ) {
    $seq .= get_chr_seq($chr, $pos1s[$i], $pos2s[$i]);
  }
  if ($strand eq '-') {
    $seq = reverse($seq);
    $seq =~ tr/atcgATCG/tagcTAGC/;
  }
  return $seq;
}

sub get_chr_seq {
  my $chr = shift;
  my $pos1 = shift; # 0 based
  my $pos2 = shift; # 1 based
  my $path = '/home/zhaorui/ct208/db/genome/ucsc/chromFa/';
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

