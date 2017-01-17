#!/usr/bin/env perl
# Date: 2014-11-05
# Author: Zhao
# Purpose: format SNP group file using dbsnp rs number
# Update: 2016-03-21
# 输出common SNP 为小写字母 或 n
# Update: 2017-01-17
# 用dnSNP的alleles列替换原observed的列的信息，更为准确。排除不常见等位基因。

use 5.014;
use Data::Dump qw/dump/;
use Smart::Comments;
use autodie;
use DBI;
use Array::Utils qw/:all/;
use Storable;
use Array::Transpose;

######## Usage:
# ./dbsnp2snpgrp.pl dbsnp.txt RAW|IUPAC|LOWER|N

my $MARK_DB = "snp144Common";
my $FLANK_LEN = 200;

my ($hashref, %assay_snpgrp);
if (-f '.dbsnp2snpgrp') {
  ### load assays
  $hashref = retrieve('.dbsnp2snpgrp') || undef;
  %assay_snpgrp = %$hashref;
}
my ($rsfile, $mode) = @ARGV;
exit unless defined $mode;

# mode:
# RAW
# IUPAC
# LOWER
# N

open my $fh1, '<', $rsfile;
my $c = 1;
my $line_cnt = 100;
my $dbh = DBI->connect('dbi:mysql:ucsc_hg38','ucsc','ucsc');
while (<$fh1>) {
  chomp;
  my $rs = $_;
  next if exists $assay_snpgrp{$rs}{$mode};
  my $sql = "select chromStart,chromEnd,chrom, strand, observed, alleles, class from snp144 where name = '$rs'";
  my $rv = $dbh->selectrow_arrayref($sql);
  my $snp_grp;
  my ($str_pos,$end_pos,$chr,$strand, $observed, $alleles,$class) = @$rv;
  if ($alleles ne '') {
    $observed = $alleles;
    $observed =~ s/,$//;
    $observed =~ s/,/\//g;
  }
  my $seq_upstream =    get_chr_seqs( $chr, $strand, $str_pos-$FLANK_LEN+1, $str_pos);
  my $seq_downstream =  get_chr_seqs( $chr, $strand, $end_pos+1, $end_pos+$FLANK_LEN);
  my $nt_left =         proximal(     $chr, $strand, $str_pos-$FLANK_LEN+1, $str_pos, $seq_upstream);
  my $nt_right =        proximal(     $chr, $strand, $end_pos+1, $end_pos+$FLANK_LEN, $seq_downstream);
  given ($strand) {
    when ('+') {
      $snp_grp = "$rs\t${nt_left}[$observed]$nt_right";
    }
    when ('-') {
      $snp_grp = "$rs\t${nt_right}[$observed]$nt_left";
    }
  }
  # dump $chr, $strand, $snp_grp, $str_pos, $end_pos,$rs;exit;
  $assay_snpgrp{$rs}{$mode} = $snp_grp;
  store \%assay_snpgrp, '.dbsnp2snpgrp';
  bar($c++, $line_cnt);
}

### output SNP group file for each snp
my $filename1 = $rsfile;
$filename1 =~ s/\.txt/.$mode.txt/;
open my $fh2, ">", $filename1;
say $fh2 "SNP_ID\tSequence";
foreach my $k (keys %assay_snpgrp) {
  say $fh2 $assay_snpgrp{$k}{$mode};
}
close $fh2;
### done

sub proximal {
  my ($chr,$strand,$str_pos,$end_pos,$seq) = @_;
  my $dbh = DBI->connect('dbi:mysql:ucsc_hg38','ucsc','ucsc');
  # label proximal snp in a piece of sequence
  my $sql = "select chromEnd,observed,strand,alleles from $MARK_DB where class = 'single'
    and chromEnd >= $str_pos and chromEnd <= $end_pos and chrom = '$chr'";
  my $rv = $dbh->selectall_arrayref($sql);
  $seq = uc $seq;
  foreach my $i (@$rv) {
    my $pos = $i->[0];  # 1 based
    my $observed = uc $i->[1];
    my $snp_strand = $i->[2];
    my $alleles = $i->[3];
    if ($alleles eq '') {
      $alleles = $observed;
    }
    my $code;
    if ($strand eq '+') {
      $code = substr $seq, $pos - $str_pos, 1;
    } else {
      $code = substr $seq, $end_pos - $pos, 1;
    }
    given ($mode) {
      when ('RAW') {
      }
      when ('LOWER') {
        $code = lc($code);
      }
      when ('N') {
        $code = 'N';
      }
      when ('IUPAC') {
        $alleles =~ tr/ATCG/TAGC/ if $snp_strand ne $strand;
        my @alleles = split /\W+/, $alleles;
        $code = lc iupac_translate(@alleles);
      }
      default {
        say "$mode not recognized.";
        exit;
      }
    }
    substr $seq, $pos - $str_pos, 1, $code if $strand eq '+';
    substr $seq, $end_pos - $pos, 1, $code if $strand eq '-';
  }
  return $seq;
}

sub proximal_snp {
  my ($chr,$strand,$str_pos,$end_pos,$seq) = @_;
  my $dbh = DBI->connect('dbi:mysql:ucsc_hg38','ucsc','ucsc');
  # label proximal snp in a piece of sequence
  my $sql = "select chromEnd,observed,strand,alleles from $MARK_DB where class = 'single'
    and chromEnd >= $str_pos and chromEnd <= $end_pos and chrom = '$chr'";
  my $rv = $dbh->selectall_arrayref($sql);
  $seq = lc $seq;
  foreach my $i (@$rv) {
    my $pos = $i->[0];
    my $observed = uc $i->[1];
    my $snp_strand = $i->[2];
    my $alleles = $i->[3];
    if ($alleles eq '') {
      $alleles = $observed;
    }
    #$observed =~ tr/ATCG/TAGC/ if $snp_strand ne $strand;
    $alleles =~ tr/ATCG/TAGC/ if $snp_strand ne $strand;
    my @alleles = split /\W+/, $alleles;
    my $code = iupac_translate(@alleles);
    substr $seq, $pos - $str_pos, 1, $code if $strand eq '+';
    substr $seq, $end_pos - $pos, 1, $code if $strand eq '-';
  }
  return $seq;
}

sub proximal_pos {
  my ($chr,$strand,$str_pos,$end_pos,$seq) = @_;
  # str_pos 0 based, end_pos 1 based
  $str_pos++;
  my $dbh = DBI->connect('dbi:mysql:ucsc_hg19','ucsc','ucsc');
  # label proximal snp in a piece of sequence
  my $sql = "select chromEnd,observed,strand,alleles from snp144Common where class = 'single'
    and chromEnd >= $str_pos and chromEnd <= $end_pos and chrom = '$chr'";
  my $rv = $dbh->selectall_arrayref($sql);
  $seq = uc $seq;
  foreach my $i (@$rv) {
    my $pos = $i->[0];
    #my $observed = uc $i->[1];
    #my $snp_strand = $i->[2];
    #my $alleles = $i->[3];
    #$observed =~ tr/ATCG/TAGC/ if $snp_strand ne $strand;
    #$alleles =~ tr/ATCG/TAGC/ if $snp_strand ne $strand;
    #my @alleles = split /\W+/, $alleles;
    if ($strand eq '+') {
      my $code = lc substr $seq, $pos - $str_pos, 1;
      substr $seq, $pos - $str_pos, 1, $code;
    } else {
      my $code = lc substr $seq, $end_pos - $pos, 1;
      substr $seq, $end_pos - $pos, 1, $code if $strand eq '-';
    }
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
  my @b = ('-', '.', 0);
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

  my @c = array_minus(@a, @b);
  @c = unique(@c);
  @c = map {@{$code{$_}}} @c;
  @c = unique(@c);
  foreach my $k ( keys %code ) {
    if ( !array_diff(@c,  @{$code{$k}}) ) {
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

