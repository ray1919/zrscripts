#!/usr/bin/env perl
# Date: 2014-11-05
# Author: Zhao
# Purpose: format SNP group file using dbsnp rs number

use 5.012;
use Data::Dump qw/dump/;
use Smart::Comments;
use autodie;
use DBI;
use Array::Utils qw/:all/;
use Storable;
use Array::Transpose;

my ($hashref, %assay_snpgrp);
if (-f '.dbsnp2snpgrp') {
  ### load assays
  $hashref = retrieve('.dbsnp2snpgrp') || undef;
  %assay_snpgrp = %$hashref;
}
my $rsfile = shift || 'kaipu_beta_rsno.txt';
open my $fh1, '<', $rsfile;
my $c = 1;
my $line_cnt = 77;
my $dbh = DBI->connect('dbi:mysql:ucsc_hg38','ucsc','ucsc');
while (<$fh1>) {
  chomp;
  my $rs = $_;
  next if exists $assay_snpgrp{$rs};
  my $sql = "select chromStart,chromEnd + 1,chrom, strand, observed, class from snp141 where name = '$rs'";
  my $rv = $dbh->selectrow_arrayref($sql);
  my ($nt_a1,$snp_grp,$nt_a2);
  my $assay_catalog;
  my ($str_pos,$end_pos,$chr,$strand,$observed,$class) = @$rv;
  my $nt_left = get_chr_seqs($chr,$strand,$str_pos-99, $str_pos);
  my $nt_left = proximal_snp($chr,$strand,$str_pos-99, $str_pos,$nt_left);
  my $nt_right = get_chr_seqs($chr,$strand,$end_pos, $end_pos+99);
  my $nt_right = proximal_snp($chr,$strand,$end_pos, $end_pos+99,$nt_right);
  given ($strand) {
    when ('+') {
      $snp_grp = "$rs\t${nt_left}[$observed]$nt_right";
    }
    when ('-') {
      $snp_grp = "$rs\t${nt_right}[$observed]$nt_left";
    }
  }
  # dump $chr, $strand, $snp_grp, $str_pos, $end_pos,$rs;exit;
  $assay_snpgrp{$rs} = $snp_grp;
  store \%assay_snpgrp, '.dbsnp2snpgrp';
  bar($c++, $line_cnt);
}

### output SNP group file for each snp
my $filename1 = "$rsfile.snpgrp";
open my $fh2, ">", $filename1;
say $fh2 "SNP_ID\tSequence";
foreach my $k (keys %assay_snpgrp) {
  say $fh2 $assay_snpgrp{$k};
}
close $fh2;
### done

sub proximal_snp {
  my ($chr,$strand,$str_pos,$end_pos,$seq) = @_;
  my $dbh = DBI->connect('dbi:mysql:ucsc_hg38','ucsc','ucsc');
  # label proximal snp in a piece of sequence
  my $sql = "select chromEnd,observed,strand,alleles from snp141Common where class = 'single'
    and chromEnd >= $str_pos and chromEnd <= $end_pos and chrom = '$chr'";
  my $rv = $dbh->selectall_arrayref($sql);
  $seq = lc $seq;
  foreach my $i (@$rv) {
    my $pos = $i->[0];
    #my $observed = uc $i->[1];
    my $snp_strand = $i->[2];
    my $alleles = $i->[3];
    #$observed =~ tr/ATCG/TAGC/ if $snp_strand ne $strand;
    $alleles =~ tr/ATCG/TAGC/ if $snp_strand ne $strand;
    my @alleles = split /\W+/, $alleles;
    my $code = iupac_translate(@alleles);
    substr $seq, $pos - $str_pos, 1, $code if $strand eq '+';
    substr $seq, $end_pos - $pos, 1, $code if $strand eq '-';
  }
  return $seq;
}

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
  my $path = '/home/zhaorui/ct208/db/genome/ucsc/hg38/'; # hg38 genome seq dir
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


sub iupac_translate {
  my @a = @_;
  my @b = ('-', '.');
  my %code = (
    'A' => ['A'],
    'T' => ['T'],
    'G' => ['G'],
    'C' => ['C'],
    'R' => ['G','A'],
    'Y' => ['C','T'],
    'S' => ['G','C'],
    'W' => ['A','T'],
    'K' => ['G','T'],
    'M' => ['A','C'],
    'B' => ['G','C','T'],
    'D' => ['A','G','T'],
    'H' => ['A','C','T'],
    'V' => ['A','C','G'],
    'N' => ['A','C','G','T'],
  );

  @a = unique(@a);
  @a = map {@{$code{$_}}} @a;
  @a = unique(@a);
  @a = array_minus(@a, @b);
  foreach my $k ( keys %code ) {
    if ( !array_diff(@a,  @{$code{$k}}) ) {
      return $k;
    }
  }
  return join('', '[',@a,']');
}

sub bar {
  local $| = 1;
  my $i = $_[0] || return 0;
  my $n = $_[1] || return 0;
  print "\r["
    . ( "#" x int( ( $i / $n ) * 50 ) )
    . ( " " x ( 50 - int( ( $i / $n ) * 50 ) ) ) . "]";
  printf( "%2.1f%%", $i / $n * 100 );
  local $| = 0;
}

