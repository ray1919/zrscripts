#!/usr/bin/env perl
# Author: Zhao
# Date: 2013-06-25
# Purpose: lookup lincRNA info by chromosome position
# 根据Agilent探针注释信息probe_name.ann查找基因组(hg19,37.p10)上对应探针位置的RNA
# 信息，并给出上下游序列。RNA信息来自NCBI人基因组Refseq feature table。

use warnings;
use strict;
use 5.010;
use Data::Table;
use Smart::Comments;
use Data::Dump qw(dump);
use Data::Swap;

# 1 based cordinate
my $srcdir = 'hs.GRCh37.p10.chr.feature_table'; # feature table dir
my %ftfiles;
my $info = Data::Table::fromTSV("$srcdir/info.txt");
foreach my $i ( 0 .. $info->lastRow) {
  $ftfiles{$info->elm($i,'Type') . $info->elm($i,'Name')} = $info->elm($i,'RefSeq');
}

my (%misc,@gene_info,@title_line);

### load misc_RNA info
# split into records and parse rna positions
foreach my $chr ( keys %ftfiles ) { ### [===|                           ] % done
  open(FT, "$srcdir/$ftfiles{$chr}.feature_table") || die $!;
  # File : "$srcdir/$ftfiles{$chr}.feature_table"
  my $is_misc = 0;
  my $is_new = 0;
  my $record = '';
  while( <FT> ) {
    if ( /\d+[\t<>]+\d+\tgene/ ) {
      my ($gepos1, $gepos2, $gestrand);
      if( $record =~ /(\d+)[\t<>]+(\d+)\tgene/ ) {
        ($gepos1, $gepos2) = ($1,$2);
        $gestrand = $gepos1 < $gepos2 ? '+' : '-';
      }
      while ($record =~ /(\d+[\t<>]+\d+\t\S+RNA.*?)\t\t\t.*?\t\t\ttranscript_id\tref\|(\S+)\|.\t\t\tgene\t(\S+)/sg) {
        # new record
        my ($s,$ti,$ge) = ($1,$2,$3);
        push(@gene_info,[$ge,$ti,"$chr:$gepos1-$gepos2",$gestrand,'','']);
        while ( $s =~ /(\d+).*?(\d+)/g ) {
          my ($pos1, $pos2) = ($1, $2);
          swap(\$pos1, \$pos2) if ( $pos1 > $pos2 );
          push(@{$misc{lc($chr)}}, [$pos1,$pos2,$#gene_info]);
          $gene_info[$#gene_info][4] .= "$pos1,";
          $gene_info[$#gene_info][5] .= "$pos2,";
          # dump([$ge,$ti,$pos1,$pos2]) if ($ge eq 'NFE2');
        }
        # dump(%misc);
        # dump(@gene_info);
        # <STDIN>;
      }
      $record = '';
    }
    $record .= $_;
  }
  close(FT);
}

### check misc_RNA info by position
open(POS,"lincRNAs_transcripts.gtf") || die $!;
open(P2G,">lincRNAs_transcripts.pos2gene") || die $!;
push(@title_line,
  'lincRNA chromosome coordinate',
  'gene','transcript id','gene position','strand',#'exon starts','exon ends',
  'reporter exon position',
  );
  say P2G join("\t", @title_line);
while ( <POS> ) { ### Progressing...   done
  chomp;
  my @line = split("\t", $_);
  my ($chr,$pos1,$pos2) = ($line[0],$line[3],$line[4]);
  next if (!exists $misc{lc($chr)});
  my @rnas = check_misc($chr,$pos1,$pos2);
  dump($chr,$pos1,$pos2);
  foreach my $i ( 0 .. $#rnas ) {
    say P2G join("\t", "$line[0]:$line[3]-$line[4]", @{$rnas[$i]});
  }
}
close(POS);
close(P2G);
### Job done
exit;

sub check_misc {
  my ($chr,$pos1,$pos2) = @_;
  my @re;
  swap(\$pos1, \$pos2) if ( $pos1 > $pos2 );
  # dump(($chr,$pos1,$pos2));
  foreach my $i ( sort {$$a[0] <=> $$b[0]} @{$misc{lc($chr)}} ) {
    if ( $pos1 >= $$i[0] && $pos2 <= $$i[1] ) {
#      my @seqpos = updownpos(
#        ${$gene_info[$$i[2]]}[4],
#        ${$gene_info[$$i[2]]}[5],
#        int($pos1/2+$pos2/2),
#        200
#      );
      my $strand = ${$gene_info[$$i[2]]}[3];
      push(@re, [@{$gene_info[$$i[2]]}[0..3], "$chr:$$i[0]-$$i[1]",
          # get_chr_seqs($chr, $strand, $$i[0], $$i[1]),
#          get_chr_seqs(
#            $chr,
#            $strand,
#            join(',', @seqpos[map {$_*2} (0 .. (@seqpos/2 - 1))]),   # start poss
#            join(',', @seqpos[map {$_*2+1} (0 .. (@seqpos/2 - 1))])  # end poss
#          )
        ]);
    }
  }
  return @re;
}

sub get_chr_seqs {
  my $chr = shift;
  my $strand = shift;
  my $pos1 = shift;               # 1 based to 0 based
  my $pos2 = shift || $pos1;        # 1 based
  my $seq = '';
  $chr =~ tr/Cxy/cXY/;
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
  return $seq;
}

sub get_chr_seq {
  my $chr = shift;
  my $pos1 = shift; # 0 based
  my $pos2 = shift; # 1 based
  my $path = '/home/zhaorui/ct208/db/genome/ucsc/chromFa/'; # hg19 genome seq dir
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

sub updownpos {
  # updownpos('2001,1601,1001,','2400,1800,1500,',1451,400);
  my ($spos,$epos,$pos,$len) = @_;
  my @spos = split(/\D+/,$spos);
  my @epos = split(/\D+/,$epos);
  my @pos = ($pos-$len, $pos+$len);
  @spos = sort @spos;
  @epos = sort @epos;
  for (my $i=$#spos-1;$i>=0;$i--) {
    my ($ins, $ine) = ($epos[$i]+1, $spos[$i+1] - 1);
    if ( $pos[0] >= $ins && $pos[0] <= $ine ) {
      $pos[0] -= $ine - $ins + 1;
      @pos = ($pos[0],$ins-1,$ine+1,@pos[1..$#pos]);
    }
    elsif ( $pos[0] < $ins && $pos[$#pos] > $ine && $pos > $ine ) {
      $pos[0] -= $ine - $ins + 1;
      @pos = ($pos[0],$ins-1,$ine+1,@pos[1..$#pos]);
    }
  }
  for (my $i=0;$i<$#spos;$i++) {
    my ($ins, $ine) = ($epos[$i]+1, $spos[$i+1] - 1);
    if ( $pos[$#pos] >= $ins && $pos[$#pos] <= $ine ) {
      $pos[$#pos] += $ine - $ins + 1;
      @pos = (@pos[0..$#pos-1],$ins-1,$ine+1,$pos[$#pos]);
    }
    elsif ( $pos[0] < $ins && $pos[$#pos] > $ine && $pos < $ins ) {
      $pos[$#pos] += $ine - $ins + 1;
      @pos = (@pos[0..$#pos-1],$ins-1,$ine+1,$pos[$#pos]);
    }
  }
  if ( $pos[0] < $spos[0] ) {
    $pos[0] = $spos[0];
  }
  if ( $pos[$#pos] > $epos[$#epos] ) {
    $pos[$#pos] = $epos[$#epos];
  }
  return @pos;
}
