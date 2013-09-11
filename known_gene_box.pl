#!/usr/bin/env perl
# Author: Zhao
# Date: 2012-12-6
# Purpose: 查询基因所有外显子、转录本、cds等

use lib 'lib';
use Ucsc::Schema;
use 5.010;
use Image::Base::Text;
my $width = 1000; # 图例基因长度

my $gene = ask_user('Gene symbol', 'TP53');

# 确定每个外显子的排序
my $schema = Ucsc::Schema->connect('dbi:mysql:ucsc_hg19', 'ucsc', 'ucsc');
my $gs = $schema->resultset('KgXref')->search({ geneSymbol => $gene });
my %exons = ();
my %exons_1 = ();
my $strand, $chrom;
while( $gs1 = $gs->next) {
  $gb = $schema->resultset('KnownGene')->search({ name => $gs1->kgid });
  # sort and name each exon
  while ($gb1 = $gb->next) {
    $strand = $gb1->strand if (!defined $strand);
    $chrom = $gb1->chrom;
    my @exonstarts = split(',',$gb1->exonstarts);
    map {$_++} @exonstarts;
    my @exonends = split(',',$gb1->exonends);
    foreach my $i ( 0 .. $#exonstarts ) {
      $exons{"$exonstarts[$i] - $exonends[$i]"} = $strand eq '+' ?
                                                  $exonstarts[$i] :
                                                  $exonends[$i];
      $exons_1{"$exonstarts[$i] - $exonends[$i]"} = [$exonstarts[$i],$exonends[$i]];
    }
  }
}
if ($gs > 0) {
  mkdir($gene);
}
else {
  say "gene $gene not found.";
  exit;
}

# 输出基因外显子的相关信息
open(GS, ">$gene/$gene.exon");
say GS 'gene: '.$gene.' exon: '.(scalar keys %exons).' strand: '.
        $strand.' chromesome: '.$chrom;
my $s = 1;

if ($strand eq '+') {
  my $min_start = -1;
  foreach my $i ( sort {$exons{$a} <=> $exons{$b}} keys %exons ) {
    $min_start = $exons{$i} if ($min_start < 0);
    $exons{$i} = $s++;
    say GS "$i\t$exons{$i}\t",chr($exons{$i} + 64);
  }
  say GS '';
  foreach my $i ( sort {$exons{$a} <=> $exons{$b}} keys %exons ) {
    say GS ($exons_1{$i}[0] + 1 - $min_start), ' - ',
            ($exons_1{$i}[1] + 1 - $min_start), "\t",
            ($exons_1{$i}[1] - $exons_1{$i}[0] + 1), "\t",
            $exons{$i}, "\t",chr($exons{$i} + 64);
  }
} else {
  my $min_start = -1;
  foreach my $i ( sort {$exons{$b} <=> $exons{$a}} keys %exons ) {
    $min_start = $exons{$i} if ($min_start < 0);
    $exons{$i} = $s++;
    say GS "$i\t$exons{$i}\t",chr($exons{$i} + 64);
  }
  say GS '';
  foreach my $i ( sort {$exons{$a} <=> $exons{$b}} keys %exons ) {
    say GS ($min_start - $exons_1{$i}[1] + 1), ' - ',
            ($min_start - $exons_1{$i}[0] + 1), "\t",
            ($exons_1{$i}[1] - $exons_1{$i}[0] + 1), "\t",
            $exons{$i}, "\t",chr($exons{$i} + 64);
  }
}

# 每个mRNA结构图+序列
my $gs = $schema->resultset('KgXref')->search({ geneSymbol => $gene });
while( $gs1 = $gs->next) {
  my $image = Image::Base::Text->new (-width  => $width,-height => 10);
  $gb = $schema->resultset('KnownGene')->search({ name => $gs1->kgid });
  while ($gb1 = $gb->next) {
    my @exonstarts = split(',',$gb1->exonstarts);
    map {$_++} @exonstarts;
    my @exonends = split(',',$gb1->exonends);
    my $length = $gb1->txend - $gb1->txstart;
    my $exs = '';
    foreach my $i ( 0 .. $#exonstarts ) {
      $image->rectangle( (($exonstarts[$i] - $gb1->txstart) / $length * ($width - 1)), 5,
                        (($exonends[$i] - $gb1->txstart) / $length * ($width - 1)), 9, '*' );
      $image->xy( (($exonstarts[$i] - $gb1->txstart) / $length * ($width - 1)),
                  2 + $i % 3, chr(64 + $exons{"$exonstarts[$i] - $exonends[$i]"}));
      $image->xy( (($exonends[$i] - $gb1->txstart) / $length * ($width - 1)),
                  2 + $i % 3, chr(64 + $exons{"$exonstarts[$i] - $exonends[$i]"}));
      $exs .= chr(64 + $exons{"$exonstarts[$i] - $exonends[$i]"});
    }
    say GS '';
    $exs = reverse($exs) if ($strand eq '-');
    say GS $gs1->mrna,"\t$exs\t",$gb1->strand;

    $image->line(0,7,$width-1,7); # transcript
    $image->line( (($gb1->cdsstart - $gb1->txstart) / $length * ($width - 1)),1,
                  (($gb1->cdsend - $gb1->txstart) / $length * ($width - 1)),1,'#'); # cds
    $image->save("$gene/" . $gs1->mrna . '.gst');
    # gene information
    open(GST, ">>$gene/" . $gs1->mrna . '.gst') || die $!;
    $gm = $schema->resultset('KnownGeneTxMrna')->search({ name => $gs1->kgid });
    $gm1 = $gm->first;
    $txseq = $gm1->seq;
    say GST '>gene:'.$gs1->genesymbol.'_mrna:'.$gs1->mrna.'_exon:'.
        $gb1->exoncount.'_strand:'.$gb1->strand.'_chromesome:'.$gb1->chrom,
        "_txlength:".length($txseq);
    $cdsseq = cds_seq($gb1->cdsstart,$gb1->cdsend,$gb1->exonstarts,
                      $gb1->exonends,$txseq,$gb1->strand);
    $txseq =~ s/(.{50})/$1\n/g;
    say GST $txseq;
    say GST '';
    say GST '>gene:'.$gs1->genesymbol.'_mrna:'.$gs1->mrna.'_exon:'.
        $gb1->exoncount.'_strand:'.$gb1->strand.'_chromesome:'.$gb1->chrom,
        "_cdslength:".length($cdsseq);
    $cdsseq =~ s/(.{50})/$1\n/g;
    say GST $cdsseq;
  }
}

sub cds_seq {
  # 获取转录本cds序列
  my $cdsstart = shift;
  my $cdsend = shift;
  my $exonstarts = shift;
  my $exonends = shift;
  my $txseq = shift;
  my $strand = shift;
  my @exs = split(",", $exonstarts);
  my @exe = split(",", $exonends);
  $cdsstart -= $exs[0];
  $cdsend -= $exs[0];
  my $start = $exs[0];
  map {$_ -= $start} @exe;
  map {$_ -= $start} @exs;
  $cdslen = $cdsend - $cdsstart;
  foreach my $i ( 0 .. $#exs - 1 ) {
    $intron = $exs[$i+1] - $exe[$i];
    if ($cdsstart >= $exs[$i + 1]) {
      $cdsstart -= $intron;
    }
    if ($cdsend >= $exs[$i + 1] + 1) {
      $cdsend -= $intron;
    }
    foreach my $j ( ($i + 1) .. $#exs ) {
      $exs[$j] -= $intron;
      $exe[$j] -= $intron;
    }
  }
  if ($strand eq '+') {
    return substr($txseq,$cdsstart,$cdsend-$cdsstart);
  }
  else {
    return substr($txseq,($exe[$#exe] - $cdsend),$cdsend-$cdsstart);
  }
}

sub ask_user {
  print "$_[0] [$_[1]]: ";
  my $rc = <>;
  chomp $rc;
  if($rc eq "") { $rc = $_[1]; }
  return $rc;
}
