#!/usr/bin/env perl
# Ahthor: Zhao
# Date: 2013-08-07
# Purpose: query omim and clinvar db for gene variation data

use 5.012;
use Data::Dump qw(dump);
use Smart::Comments;
use lib '/home/zhaorui/bin/lib';
use Ucsc::Schema;
use Excel::Writer::XLSX;
my %chr_seqs;

my $ucsc = Ucsc::Schema->connect('dbi:mysql:ucsc_hg19', 'ucsc', 'ucsc');
load_tx_from_gi('gi.txt');
exit;

sub load_tx_from_gi {
  use Data::Table;
  my $gifile = shift;

  open my $GI, '<', $gifile || die $!;
  # open my $OUT, '>', 'gene_tx_seq.html' || die $!;
  my $wb = Excel::Writer::XLSX->new( 'gene_table.xlsx' );
  my $s1 = $wb->add_worksheet("gene list");
  my $ht = new Data::Table ( [], ['gene id', 'symbol', 'transcript id', 'chrom',
    'strand', 'tx start', 'tx end', 'cdsStart',  'cdsEnd', 'exon count', 'exon starts', 'exon ends'],
    0);
  while (<$GI>) {
    chomp;
    my $gi = $_;
    ### gene id : $gi;
    my $link = $ucsc->resultset('RefLink')->search({locuslinkid => $gi});
    if ($link == 0) {
      # say $OUT $gi;
      $ht->addRow([$gi, '','','','','','','','','']);
    }
    else {
      my $l1 = $link->next;
      my $symbol = $l1->name;
      my $tx = $ucsc->resultset('RefGene')->search(
        { name2 => $l1->name },
        { order_by => 'txend - txstart desc, exoncount desc'},
      );
      while ( my $tx = $tx->next ) {
      # exit(1) if $tx == 0;
      # $tx = $tx->first;
      $ht->addRow([$gi, $symbol, $tx->name, $tx->chrom,$tx->strand,
          $tx->txstart, $tx->txend,$tx->cdsstart, $tx->cdsend,
          $tx->exoncount, $tx->exonstarts, $tx->exonends]);
      }
    }
  }
  $ht->addCol(undef,'tx lenth');
  $ht->colsMap(sub {$_->[12] = $_->[6] - $_->[5]});
  $ht->colMap('tx start',sub{$_ + 1;}); # 1 based

  # dump $$ht{'data'};
  my $format = $wb->add_format();
  $format->set_font('Courier New');
  $format->set_align("left");
  $format->set_size(10);

  my $url_format = $wb->add_format();
  $url_format->set_font('Courier New');
  $url_format->set_align("left");
  $url_format->set_size(10);
  $url_format->set_underline();
  $url_format->set_italic();
  $url_format->set_color('blue');

  foreach my $r ( 0 .. $ht->lastRow ) { # saving [===|            ] % done
    my $txid = $ht->elm($r,'transcript id');
    next if $txid eq '';
    open my $fh, '>', "${txid}_txseq.html" or die $!;
    my $sg = $wb->add_worksheet($ht->elm($r,'symbol') . " - $txid");
    my @exs = split(',', $ht->elm($r,'exon starts')); # 0 based
    my @exe = split(',', $ht->elm($r,'exon ends'));
    # dump @exs;
    # dump @exe;
    my @exl = map {$exe[$_] - $exs[$_]} 0 .. $#exs; # exon lengths
    my @inl = map {$exs[$_] - $exe[$_-1]} 1 .. $#exs; # intron lengths

    # sequences
    my $flanklen = 200;
    # my $intronlen = 200;
    my $linelen = 100; # bp displayed per line
    my $strand = $ht->elm($r,'strand');
    my $chrom = $ht->elm($r,'chrom');
    my $txstart = $ht->elm($r,'tx start') - 1; # 0 based
    my $txend = $ht->elm($r,'tx end');
    my $cdsstart = $ht->elm($r,'cdsStart'); # 0 based
    my $cdsend = $ht->elm($r,'cdsEnd');
    my ($sequence,$seq_5,$seq_3,@color,$shift,$len0,$aa_len);
    my $slen = 0;
    my $aa_num = 1;
    my $junction_seq = '';
    my @exon_order = 0 .. $#exs;
    if ($strand eq '-') {
      @exon_order = reverse @exon_order;
    }
      foreach my $i ( @exon_order ) { ### retriving |===[%]           |
        $sequence = get_chr_seqs($chrom,$strand,
          $exs[$i]-$flanklen+1, $exe[$i]+$flanklen);
        $seq_5 = substr($sequence, 0, $flanklen);
        $seq_3 = substr($sequence, -$flanklen);
        ($seq_5,$seq_3) = flank_seq($seq_5,$seq_3,
          $i-1 < 0 ? 2*$flanklen : $inl[$i-1],
          $i > $#inl ? 2*$flanklen : $inl[$i],
          $flanklen, $i);
        my $exon_seq = substr($sequence, $flanklen, -$flanklen);
        push @color, 'black'; # exon no
        push @color, $strand eq '+' ? "Exon".($i+1).":\t"
                                    : "Exon".($#exs - $i+1).":\t";

        # 5' flunk sequence
        push @color, 'yellow'; # up stream
        # push @color, get_chr_seqs($chrom,$strand,$exs[$i]-$flanklen+1, $exs[$i]);
        $seq_5 =~ s/(.{$linelen})/$1\n\t/g;
        $seq_5 =~ s/\n\t$//; # flunklen 是 linelen 整倍数会多一个tab
        push @color, "$seq_5\n";
        push @color, 'red'; # exon

        # exon sequence
        # my $exon_seq = get_chr_seqs($chrom,$strand,$exs[$i]+1, $exe[$i]);
        my $exon = $exon_seq;
        $exon =~ s/(.{$linelen})/$1\n\t/g;
        push @color, "\t$exon\n";
        if ($strand eq '+') {
          if (between($cdsstart+1, $exs[$i]+1, $exe[$i]) ) {
            my $len1 = $exe[$i] - $cdsstart;
            $len0 = $cdsstart - $exs[$i];
            $slen = $len1 % 3;
            if ($slen != 0) {
              $junction_seq = substr($exon_seq,-$slen);
            }
            $shift = $cdsstart - $exs[$i];
          }
          elsif ( between($cdsend, $exs[$i]+1, $exe[$i]) ) {
            my $len1 = $cdsend - $exs[$i];
            $len0 = (3 - $slen) % 3;
            if ($len0 != 0) {
              $junction_seq .= substr($exon_seq,0,$len0);
              my $taa = coden($junction_seq,0,0);
              $color[$#color-8] =~ s/\n$/$taa\n/;
            }
            $slen = $exe[$i] - $cdsend;
            $shift = $len0;
          }
          elsif ( between($exs[$i]+1, $cdsstart+1, $cdsend) ) {
            my $len1 = $exe[$i] - $exs[$i];
            $len0 = (3 - $slen) % 3;
            if ($len0 != 0) {
              $junction_seq .= substr($exon_seq,0,$len0);
              my $taa = coden($junction_seq,0,0);
              $color[$#color-8] =~ s/\n$/$taa\n/; # 添加上段末尾不对称氨基酸密码子
            }
            $slen = ($len1 - $len0) % 3;
            if ($slen != 0) {
              $junction_seq = substr($exon_seq,-$slen);
            }
            $shift = $len0;
          }
        }
        else { # minus strand
          if (between($cdsend, $exs[$i]+1, $exe[$i]) ) { # start exon
            my $len1 = $cdsend - $exs[$i];
            $len0 = $exe[$i] - $cdsend;
            $slen = $len1 % 3;
            if ($slen != 0) {
              $junction_seq = substr($exon_seq,-$slen);
            }
            $shift = $len0;
          }
          elsif ( between($cdsstart+1, $exs[$i]+1, $exe[$i]) ) { # end exon
            my $len1 = $exe[$i] - $cdsstart;
            $len0 = (3 - $slen) % 3;
            if ($len0 != 0) {
              $junction_seq .= substr($exon_seq,0,$len0);
              my $taa = coden($junction_seq,0,0);
              $color[$#color-8] =~ s/\n$/$taa\n/;
            }
            $slen = $cdsstart - $exs[$i];
            $shift = $len0;
          }
          elsif ( between($exs[$i]+1, $cdsstart+1, $cdsend) ) {
            my $len1 = $exe[$i] - $exs[$i];
            $len0 = (3 - $slen) % 3;
            if ($len0 != 0) {
              $junction_seq .= substr($exon_seq,0,$len0);
              my $taa = coden($junction_seq,0,0);
              $color[$#color-8] =~ s/\n$/$taa\n/; # 添加上段末尾不对称氨基酸密码子
            }
            $slen = ($len1 - $len0) % 3;
            if ($slen != 0) {
              $junction_seq = substr($exon_seq,-$slen);
            }
            $shift = $len0;
          }
        }
        my $aa = coden($exon_seq, $shift,$slen);
        $aa_len = length($aa);
        if ($slen != 0) {
          $aa_len += 1;
        }
        $aa =~ s/(.)/$1  /g;
        # $aa = ' ' x (200 + $len0) . $aa;
        $aa = ' ' x ($len0) . $aa;
        my $aa_seq = $aa;
        $aa_seq =~ s/(.{$linelen})/$1\n\t/g;
        push @color, 'blue'; # exon no
        push @color, add_aa_num($aa_seq, $aa_num)."\n";
        # push @color, "$aa_num\t$aa_seq\n";
        $aa_num += $aa_len;

        # 3' flunk sequence
        push @color, 'yellow'; # down stream
        # push @color, get_chr_seqs($chrom,$strand,$exe[$i]+1, $exe[$i]+$flanklen)
        $seq_3 =~ s/(.{$linelen})/$1\n\t/g;
        $seq_3 =~ s/\n\t$//; # flunklen 是 linelen 整倍数会多一个tab
        push @color, "\t$seq_3\n"; # new line
      }
#    if ($strand eq '+') {
#      push @color, 'blue'; # 5' flank
#      push @color, get_chr_seqs($chrom,$strand,
#        $txstart-$flanklen+1, $txstart);
#      foreach my $i ( 0 .. $#exs ) { ### retriving |===[%]           |
#        push @color, 'red'; # exons
#        push @color, get_chr_seqs($chrom,$strand,
#          $exs[$i]+1, $exe[$i]);
#        if ( $i != $#exs ) {
#          push @color, 'yellow'; # introns
#          push @color, format_intron(get_chr_seqs($chrom,$strand,
#            $exe[$i]+1, $exs[$i+1]), $intronlen);
#        }
#      }
#      push @color, 'blue'; # 3' flank
#      push @color, get_chr_seqs($chrom,$strand,
#        $txend+1, $txend + $flanklen);
#    }
#    else { # minus strand
#      push @color, 'blue'; # 5' flank
#      push @color, get_chr_seqs($chrom,$strand,
#        $txend+1, $txend+$flanklen);
#      foreach my $j ( 0 .. $#exs ) { ### retriving |===[%]           |
#        my $i = $#exs - $j;
#        push @color, 'red'; # exons
#        push @color, get_chr_seqs($chrom,$strand,
#          $exs[$i]+1, $exe[$i]);
#        if ( $i != 0 ) {
#          push @color, 'yellow'; # introns
#          push @color, format_intron(get_chr_seqs($chrom,$strand,
#            $exe[$i-1]+1, $exs[$i]), $intronlen);
#        }
#      }
#      push @color, 'blue'; # 3' flank
#      push @color, get_chr_seqs($chrom,$strand,
#        $txstart-$flanklen, $txstart);
#    }
    my $colorseq = text_colorize(\@color, 'HTML');
    say $fh $colorseq;
    say $fh '<br>';

    # gene structure
    @exs = map {$_ + 1} @exs;
    my $extl = sum(@exl);
    $sg->write_row('A1',[$ht->header],$format);
    $sg->write_row('A2',[$ht->row($r)],$format);
    $sg->write_url('A3',"external:${txid}_txseq.html",$url_format);
    $sg->write('A4','no',$format);
    $sg->write('B4','exon start',$format);
    $sg->write('C4','exon end',$format);
    $sg->write('D4','exon lenth',$format);
    $sg->write('E4','intro lenth',$format);
    $sg->write('F4','total exon lenth',$format);
    $sg->write_col('A5', [1 .. @exs], $format);
    $sg->write_col('B5', [@exs], $format);
    $sg->write_col('C5', [@exe], $format);
    $sg->write_col('D5', [@exl], $format);
    $sg->write_col('E5', [@inl], $format);
    $sg->write('F5',$extl,$format);
  }

  $ht->delCols(['exon starts', 'exon ends']);
  $s1->write_row('A1',[$ht->header],$format);
  $s1->write_row('A2',$$ht{'data'},$format);

  $wb->close() or die "Error closing file: $!";
}

sub sum {
  my $sum = 0;
  map { $sum += $_} @_;
  return $sum;
}

sub add_aa_num {
  my ($a, $n) = @_;
  my ($a1,$l);
  my @aa = split("\t",$a);
  foreach my $i (0 .. $#aa) {
    $a1 = $aa[$i];
    $a1 =~ s/\W//g;
    $l = length($a1);
    if ($l > 0) {
      $aa[$i] = "$n\t$aa[$i]";
      $n += $l;
    }
    else {
      $aa[$i] = "\t$aa[$i]";
    }
  }
  return join('', @aa);
}

sub between {
  my ($a, $b, $c) = @_;
  if ( $a >= $b && $a <= $c ) {
    return 1;
  }
  return 0;
}

sub flank_seq {
  my ($s5,$s3,$il5,$il3,$flanklen,$i) = @_;
  if ( $il5 < 2* $flanklen) {
    $s5 = substr($s5, -(($il5 + $i % 2) / 2));
  }
  else {
    $s5 =~ s/^\w{2}/../;
  }
  if ( $il3 < 2* $flanklen) {
    $s3 = substr($s3, 0, (($il3 + $i % 2) / 2));
  }
  else {
    $s3 =~ s/\w{2}$/../;
  }
  return ($s5,$s3);
}

sub format_intron{
  my ($intron,$len) = @_;
  my $l = length($intron);
  if ( $l > $len ) {
    return substr($intron,0,$len) . "\n\n" . substr($intron,-$len,$len);
  }
  else{
    return $intron . "\n\n" . $intron;
  }
}

sub text_colorize {
  use Text::Colorizer  qw();
  my ($chunks,$format) = @_;
  my $c= Text::Colorizer->new(
    DEFAULT_COLOR => {ANSI => 'bright_white', HTML => ''},
    FORMAT => defined $format ? $format : 'HTML', # 'ANSI'
  );
  return $c->color(@$chunks);
}

sub get_chr_seqs {
  my $chr = shift;
  my $strand = shift;
  my $pos1 = shift;               # 1 based to 0 based
  my $pos2 = shift || $pos1;        # 1 based
  if (defined $chr_seqs{"$chr$strand$pos1$pos2"}) {
    return $chr_seqs{"$chr$strand$pos1$pos2"};
  }
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
  $chr_seqs{"$chr$strand$pos1$pos2"} = $seq;
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
