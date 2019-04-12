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

my ($fq_file, $out_dir) = @ARGV;
mkdir $out_dir;

my $index_seq = Data::Table::fromCSV("../180120_ST-E00318_0504_AHHWTYCCXY/SampleSheet.csv", 1, undef, {skip_lines=>19});
my (%i2s, %fastq_out, %idx_ori, %idx_res);

foreach my $i (0 .. $index_seq->lastRow) {
  my $name = $index_seq->elm($i, 'Sample_ID');
  my $seq1 = $index_seq->elm($i, 'index');
  my $seq2 = $index_seq->elm($i, 'index2');
  $i2s{$seq1}{$seq2} = $name;
  $idx_ori{$seq1} = $seq1;
  $idx_ori{$seq2} = $seq2;
  $idx_res{$seq1} = $seq1;
  $idx_res{$seq2} = $seq2;
  $fastq_out{$name} = Bio::SeqIO->new(-format    => 'fastq',
                                      -file      => ">$out_dir/${name}.fq");
}

  # grabs the FASTQ parser, specifies the Illumina variant
  open my $zcat, "zcat $fq_file |" or die $!;
  my $in = Bio::SeqIO->new(-format    => 'fastq',
                           -fh        => $zcat);

# $seq is a Bio::Seq::Quality object
while (my $seq = $in->next_seq) {
    my $desc = $seq->desc;
    my $index1 = substr($desc, 6, 8);
    my $index2 = substr($desc, 15, 8);
    my $sample;
    if ( defined $i2s{$index1}{$index2} ) {
        $sample = $i2s{$index1}{$index2};
        $fastq_out{$sample}->write_seq($seq);  # convert Illumina 1.3 to Sanger format
        next;
    } else {
        my $seq1 = match_sample($index1);
        my $seq2 = match_sample($index2);
        $sample = $i2s{$seq1}{$seq2};
    }
    if (defined $sample) {
        $i2s{$index1}{$index2} = $sample;
        $fastq_out{$sample}->write_seq($seq);  # convert Illumina 1.3 to Sanger format
    }

}

sub match_sample {
    my ($s) = @_;
    if (defined $idx_res{$s} ) {
        return $idx_res{$s};
    } else {
        my $return = 'NA';
        # match exactly Ns
        foreach my $i (keys %idx_ori) {
            my $Ns = Ns($s, 'N');
            my $hd = hd($s, $i);
            if ( $Ns == $hd ) {
                $idx_res{$s} = $i;
                return $i;
            }
            # one more mismatch
            if ( $Ns + 1 == $hd & $return ne 'null' ) {
                if ( $return eq 'NA' ) {
                    $return = $i;
                } else {
                    $return = 'null';
                }
            }
        }
        $idx_res{$s} = $return;
        return $return;
    }
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
