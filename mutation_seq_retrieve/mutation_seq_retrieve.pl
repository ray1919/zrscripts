#!/usr/bin/env perl
# Date: 2014-01-13
# Author: Zhao
# Purpose: 根据突变位置，找到对应DNA序列上下游

use 5.012;
use Data::Dump qw/dump/;
use Smart::Comments;
use Data::Table;

my $UPDOWN_LEN = 400;
my %chr_seqs;

my $gene_table_file = 'gene_table.txt';
my $mutation_file = 'mut.txt';

# mutation based on cds position might only correspond to one specific splice
# in one gene, so here we input transcricpt info manuly, not looking up all
# aplices in ucsc.
my $gt = Data::Table::fromTSV($gene_table_file);
my $mt = Data::Table::fromTSV($mutation_file);

### read gene info table
my %gene;

foreach my $r ( 0 .. $gt->lastRow ) {
  $gene{$gt->elm($r,'symbol')}{'chrom'} = $gt->elm($r,'chrom');
  $gene{$gt->elm($r,'symbol')}{'strand'} = $gt->elm($r,'strand');
  $gene{$gt->elm($r,'symbol')}{'cdsStart'} = $gt->elm($r,'cdsStart');
  $gene{$gt->elm($r,'symbol')}{'cdsEnd'} = $gt->elm($r,'cdsEnd');
  $gene{$gt->elm($r,'symbol')}{'exonStarts'} = $gt->elm($r,'exonStarts');
  $gene{$gt->elm($r,'symbol')}{'exonEnds'} = $gt->elm($r,'exonEnds');
  $gene{$gt->elm($r,'symbol')}{'transcript id'} = $gt->elm($r,'transcript id');
  $gene{$gt->elm($r,'symbol')}{'gene id'} = $gt->elm($r,'gene id');
}

foreach my $g (keys %gene) {
  $gene{$g}{'exonStarts'} = [split(',',$gene{$g}{'exonStarts'})];
  $gene{$g}{'exonEnds'} = [split(',',$gene{$g}{'exonEnds'})];
}

open my $fh1, '>', "mutation_sequence.txt" or die $!;
say $fh1 join("\t",$mt->header,"reference aa","reference nt","Sequence");
### read mutation table
foreach my $r ( 0 .. $mt->lastRow ) { ### Working===[%]                     done
  my $mut = $mt->elm($r,'Nucleotide change');
  my $gene = $mt->elm($r,'Gene');
  my ($seq_type,$mut_type,$mut_pos,$mut_seq,$mut_len);
  # detect type of mutation
  if ( $mut =~ s/(\w)\.// ) {
    $seq_type = $1;
  }
  if ( $mut =~ /^(\d+)del(\w+)/i ) {
    $mut_type = 'del';
    $mut_pos = $1;
    $mut_seq = "[$2/-]";
    $mut_len = length($2);
  }
  elsif ( $mut =~ /^(\d+)ins(\w+)/i ) {
    $mut_type = 'ins';
    $mut_pos = $1;
    $mut_seq = "[-/$2]";
    $mut_len = 0;
  }
  elsif ( $mut =~ /^(\d+)(\w+)>(\w+)/ ) {
    $mut_type = 'mut';
    $mut_pos = $1;
    $mut_seq = "[$2/$3]";
    $mut_len = length($2);
  }
  elsif ( $mut =~ /^(\d+[+-]\d+)(\w+)>(\w+)/ ) {
    # mutation in intron area
    $mut_type = 'int';
    $mut_pos = $1;
    $mut_seq = "[$2/$3]";
    $mut_len = length($2);
  }
  elsif ( $mut =~ /^(\d+)-(\d+)del/i ) {
    $mut_type = 'ldel'; # large deletion
    $mut_pos = $1;
    $mut_seq = $2;
    $mut_len = $2 - $1 + 1;
  }
  else {
    say "$mut pattern not found!";
    exit(1);
  }
  # locate mutaion in genome
  my ($seq,$sequ,$seqd,$refnt,$refaa);
  if ($seq_type eq "m") {
    $sequ = get_chr_seqs('chrm','+',$mut_pos-$UPDOWN_LEN,$mut_pos-1);
    $seqd = get_chr_seqs('chrm','+',$mut_pos+$mut_len,$mut_pos+$mut_len+$UPDOWN_LEN-1);
  }
  elsif ($seq_type eq "c") {
    my $strand = $gene{$gene}{'strand'};
    my $chrom = $gene{$gene}{'chrom'};
    my $chrpos;
    if ( $mut_type eq 'del'
        or $mut_type eq 'ins'
        or $mut_type eq 'ldel'
        or $mut_type eq 'mut' ) {
      $chrpos = cdspos_to_chrpos($mut_pos,$gene);
      if ($mut_type eq 'ldel') {
        my $chrpos2 = cdspos_to_chrpos($mut_seq,$gene);
        my $delseq = get_chr_seqs($chrom,$strand,$chrpos,$chrpos2);
        $mut_seq = "[$delseq/-]";
      }
      # get ref nt and aa in mutation position
      $refnt = get_chr_seqs($chrom,$strand,$chrpos);
      my $shift = $mut_pos % 3;
      # $shift = (4-$shift) % 3 if $strand eq '-';
      $shift = 3 if $shift == 0;
      if ($strand eq '+') {
        $refaa = get_chr_seqs($chrom,$strand,$chrpos-$shift+1,$chrpos+(3-$shift)%3);
      }
      else {
        $refaa = get_chr_seqs($chrom,$strand,$chrpos-(3-$shift)%3,$chrpos+$shift-1);
      }
      $refaa = coden($refaa,0,0);
    }
    elsif ( $mut_type eq 'int' ) {
      $mut_pos =~ /(\d+)([+-])(\d+)/;
      my $cpos = $1;
      my $apos = $3;
      $apos *= -1 if $2 eq '-';
      $chrpos = cdspos_to_chrpos($cpos,$gene) + $apos;
    }
    $sequ = get_chr_seqs($chrom,$strand,$chrpos-$UPDOWN_LEN,$chrpos-1);
    $seqd = get_chr_seqs($chrom,$strand,$chrpos+$mut_len,$chrpos+$mut_len+$UPDOWN_LEN-1);
  }
  else {
    say "unknow seq type: $mut";
    exit(2);
  }
  $seq = $sequ . $mut_seq . $seqd;
  # output result
  say $fh1 join("\t",$mt->row($r),$refaa,$refnt,$seq);
}

sub cdspos_to_chrpos {
  my ($cdspos,$symbol) = @_;
  my $chrpos;
    my $mrnaacc = $gene{$symbol}{'transcript id'};
    my $gi = $gene{$symbol}{'gene id'};
    my @exonStarts = @{$gene{$symbol}{'exonStarts'}};
    my @exonEnds = @{$gene{$symbol}{'exonEnds'}};
    my $strand = $gene{$symbol}{'strand'};
    my $pos = $cdspos;
    my $cdsstart = $gene{$symbol}{'cdsStart'};
    my $cdsend = $gene{$symbol}{'cdsEnd'};
    my $chrom = $gene{$symbol}{'chrom'};
    # trim exons outside cds
    for ( my $i = $#exonStarts; $i>=0; $i--) {
      # left exons
      if ( $cdsstart + 1 > $exonEnds[$i] ) {
        splice(@exonStarts, $i, 1);
        splice(@exonEnds, $i, 1);
      }
      # right exons
      elsif ( $cdsend < $exonStarts[$i] + 1 ) {
        splice(@exonStarts, $i, 1);
        splice(@exonEnds, $i, 1);
      }
      # start exon
      elsif ( $cdsstart >= $exonStarts[$i]
            && $cdsstart + 1 <= $exonEnds[$i] ) {
        $exonStarts[$i] = $cdsstart;
      }
      # end exon
      elsif ( $cdsend >= $exonStarts[$i] + 1
            && $cdsend <= $exonEnds[$i] ) {
        $exonEnds[$i] = $cdsend;
      }
    }
    if ($strand eq '+') {
      $chrpos = $cdsstart+$pos; # 1 based
      for my $i ( 1 .. $#exonStarts ) {
        my $prior_exon_len = $exonEnds[$i-1] - $exonStarts[$i-1];
        my $intron_len = $exonStarts[$i] - $exonEnds[$i-1];
        if ( $pos > $prior_exon_len ) {
          $pos -= $prior_exon_len;
          $chrpos += $intron_len;
        }
        else {
          last;
        }
      }
      # say get_chr_seqs($chrom, $strand, $chrpos)
    }
    else{
      $chrpos = $cdsend - $pos + 1;
      for ( my $i = $#exonStarts; $i>0; $i--) {
        my $prior_exon_len = $exonEnds[$i] - $exonStarts[$i];
        my $intron_len = $exonStarts[$i] - $exonEnds[$i-1];
        if ( $pos > $prior_exon_len ) {
          $pos -= $prior_exon_len;
          $chrpos -= $intron_len;
        }
        else {
          last;
        }
      }
      # say get_chr_seqs($chrom, $strand, $chrpos)
    }
  return $chrpos;
}

sub get_chr_seqs {
  my $chr = shift;
  my $strand = shift;
  my $pos1 = shift;               # 1 based to 0 based
  my $pos2 = shift || $pos1;        # 1 based
  if ($pos1 > $pos2) {
    my $tmp = $pos1;
    $pos1 = $pos2;
    $pos2 = $tmp;
  }
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

sub get_chr_seq {
  my $chr = shift;
  my $pos1 = shift; # 0 based
  my $pos2 = shift; # 1 based
  my $path = '/home/zhaorui/ct208/db/genome/ucsc/hg19/'; # hg19 genome seq dir
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

sub coden {
  my ($text,$s1,$s2) = @_;
  my %convertor = (
    'TCA' => 'S',    # Serine
    'TCC' => 'S',    # Serine
    'TCG' => 'S',    # Serine
    'TCT' => 'S',    # Serine
    'TTC' => 'F',    # Phenylalanine
    'TTT' => 'F',    # Phenylalanine
    'TTA' => 'L',    # Leucine
    'TTG' => 'L',    # Leucine
    'TAC' => 'Y',    # Tyrosine
    'TAT' => 'Y',    # Tyrosine
    'TAA' => '*',    # Stop
    'TAG' => '*',    # Stop
    'TGC' => 'C',    # Cysteine
    'TGT' => 'C',    # Cysteine
    'TGA' => '*',    # Stop
    'TGG' => 'W',    # Tryptophan
    'CTA' => 'L',    # Leucine
    'CTC' => 'L',    # Leucine
    'CTG' => 'L',    # Leucine
    'CTT' => 'L',    # Leucine
    'CCA' => 'P',    # Proline
    'CCC' => 'P',    # Proline
    'CCG' => 'P',    # Proline
    'CCT' => 'P',    # Proline
    'CAC' => 'H',    # Histidine
    'CAT' => 'H',    # Histidine
    'CAA' => 'Q',    # Glutamine
    'CAG' => 'Q',    # Glutamine
    'CGA' => 'R',    # Arginine
    'CGC' => 'R',    # Arginine
    'CGG' => 'R',    # Arginine
    'CGT' => 'R',    # Arginine
    'ATA' => 'I',    # Isoleucine
    'ATC' => 'I',    # Isoleucine
    'ATT' => 'I',    # Isoleucine
    'ATG' => 'M',    # Methionine
    'ACA' => 'T',    # Threonine
    'ACC' => 'T',    # Threonine
    'ACG' => 'T',    # Threonine
    'ACT' => 'T',    # Threonine
    'AAC' => 'N',    # Asparagine
    'AAT' => 'N',    # Asparagine
    'AAA' => 'K',    # Lysine
    'AAG' => 'K',    # Lysine
    'AGC' => 'S',    # Serine
    'AGT' => 'S',    # Serine
    'AGA' => 'R',    # Arginine
    'AGG' => 'R',    # Arginine
    'GTA' => 'V',    # Valine
    'GTC' => 'V',    # Valine
    'GTG' => 'V',    # Valine
    'GTT' => 'V',    # Valine
    'GCA' => 'A',    # Alanine
    'GCC' => 'A',    # Alanine
    'GCG' => 'A',    # Alanine
    'GCT' => 'A',    # Alanine
    'GAC' => 'D',    # Aspartic Acid
    'GAT' => 'D',    # Aspartic Acid
    'GAA' => 'E',    # Glutamic Acid
    'GAG' => 'E',    # Glutamic Acid
    'GGA' => 'G',    # Glycine
    'GGC' => 'G',    # Glycine
    'GGG' => 'G',    # Glycine
    'GGT' => 'G',    # Glycine
    );
  $text =~ s/\W//sg;
  my $aa = substr($text,$s1,length($text)-$s1-$s2);
  # say substr($text,$s1,length($text)-$s1-$s2);
  $aa =~ s/(...)/"$convertor{uc $1}" || "?"/eg;
  return $aa;
}
