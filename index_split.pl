#!/usr/bin/env perl
# Author: Zhao
# Date: 2017 1 19
# Purpose: split fastq file using index seq info

use Bio::SeqIO::fastq;
use 5.014;
use Data::Dump qw/dump/;
use Smart::Comments;
use Data::Table;
use Bio::Seq::Quality;

my $index_seq = Data::Table::fromTSV("index_seq.txt");
my (%i2s, %fastq_out);
foreach my $i (0 .. $index_seq->lastRow) {
  my $name = $index_seq->elm($i, 'Name');
  my $seq = $index_seq->elm($i, 'Seq');
  $i2s{$seq} = $name;
  $fastq_out{$name} = Bio::SeqIO->new(-format    => 'fastq',
                                      -file      => ">r1/$name.fq");
}

  # grabs the FASTQ parser, specifies the Illumina variant
  my $in = Bio::SeqIO->new(-format    => 'fastq',
                           -file      => '../../data/lane1_combined_clean_R1.fastq');

  # $seq is a Bio::Seq::Quality object
  while (my $seq = $in->next_seq) {
    my $desc = $seq->desc;
    my $index = right($desc, 16);
    my $sample = match_sample($index);
    $fastq_out{$sample}->write_seq($seq);  # convert Illumina 1.3 to Sanger format

  }

sub match_sample {
  my ($s) = @_;
  if (defined $i2s{$s} ) {
    return $i2s{$s};
  } else {
    foreach my $i (0 .. $index_seq->lastRow) {
      if (Ns($s, 'N') == hd($s, $index_seq->elm($i, 'Seq')) ) {
        return $index_seq->elm($i, 'Name');
      }
    }
  }
  return 'NA';
}

sub right {
  my ($s, $n) = @_;
  return substr $s, -$n, $n;
}

sub hd { # hamming distance http://www.perlmonks.org/?node_id=500235
  return ($_[0] ^ $_[1]) =~ tr/\001-\255//;
}

sub Ns {
  my ($x, $n) = @_;
  $x =~ s/[^$n]//g;
  return length($x);
}
