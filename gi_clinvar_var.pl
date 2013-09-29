#!/usr/bin/env perl
# Ahthor: Zhao
# Date: 2013-07-17
# Purpose: locate chromosome position using sequence variation label

use strict;
use 5.010;
use Data::Table;
use Data::Dump qw(dump);
use Smart::Comments;
use Data::Swap;
use lib '/home/zhaorui/bin/lib';
use Ncbi::Schema;
use Ucsc::Schema;
my $udlen = 200;

my $ncbi = Ncbi::Schema->connect('dbi:mysql:ncbi', 'ncbi', 'ncbi');
my $ucsc = Ucsc::Schema->connect('dbi:mysql:ucsc_hg19', 'ucsc', 'ucsc');

my (%misc,@gene_info);
# load_refgene();
load_mutation_from_gi('gi.txt');
exit;

sub load_mutation_from_gi {
  my $gifile = shift;
  
  open(GI, $gifile) || die $!;
  open my $RS, '>', 'gi_clinvar_rs.txt' || die $!;
  open my $GP, '>', 'gi_clinvar_sng_group.txt' || die $!;
  open my $IF, '>', 'gi_clinvar_var.txt' || die $!;
  say $GP "SNP_ID\tSequence";
  my $n = 1;
  while (<GI>) {
    chomp;
    my $gi = $_;
    my $gene = $ncbi->resultset('GeneInfo')->search({geneid => $gi});
    my $symbol = $gene->first->symbol;
    #my $link = $ucsc->resultset('RefLink')->search({locusLinkId => $gi});
    #if ( $link == 0 ){ # 此基因数据库中没有转录本，如tRNA
    #  say "\ngi: $gi has no transcript records in db.";
    #  next;
    #}

    # say $gi;
    my $link = $ncbi->resultset('Clinvar')->search({gene_id => $gi});
    if ($link == 0) {
      say OUT join("\t",$gi,$symbol);
    }
    else {
      while ( my $cv = $link->next ) {
        my @title = split(' AND ', $cv->title);
        $title[1] = join('; ', @title[1 .. $#title]);
        if ($title[0] =~ /(NM_\d+)/) {
          my $ti = $1;
          my $tx = $ucsc->resultset('RefGene')->search({name => $ti})->first;
          my $seq = get_chr_seqs($tx->chrom,$tx->strand,
            $cv->sl_start-$udlen,$cv->sl_stop+$udlen);
          $seq = replace_mid($seq,'[' . $cv->a1 . '/' . $cv->a2 . ']', $udlen);
          if ( $cv->dbsnp !~ /\d+/ ) {
            say $GP join("\t","rs$gi-".$cv->clinvar_id,$seq);
          say $n++, ' + ';
          }
          else {
            say $RS 'rs' . $cv->dbsnp;
          say $n++, ' - ';
          }
          say $IF join("\t",$cv->clinvar_id,
            $gi,$symbol,@title[0,1],$cv->omim_id,$cv->omim_av,
            $cv->dbsnp,$tx->name,$tx->chrom,$tx->strand,$tx->txstart,$tx->txend,
            $tx->cdsstart,$tx->cdsend,$tx->exonstarts,$tx->exonends,
            $cv->sl_start,$cv->sl_stop);
        }
        else {
          my $seq = get_chr_seqs('chr'.$cv->sl_chr,'+',
            $cv->sl_start-$udlen,$cv->sl_stop+$udlen);
          $seq = replace_mid($seq,'[' . $cv->a1 . '/' . $cv->a2 . ']', $udlen);
          if ( $cv->dbsnp !~ /\d+/ ) {
            say $GP join("\t","rs$gi-".$cv->clinvar_id,$seq);
          say $n++, ' + ';
          }
          else {
            say $RS 'rs' . $cv->dbsnp;
          say $n++, ' - ';
          }
          say $IF join("\t",$cv->clinvar_id,
            $gi,$symbol,@title[0,1],$cv->omim_id,$cv->omim_av,
            $cv->dbsnp,'','','','','','','','','',
            $cv->sl_start,$cv->sl_stop);
        }
        next;
      }
    }
  }
}

sub replace_mid {
  my ($s1,$s2,$len) = @_;
  return substr($s1,0,$len) . $s2 . substr($s1,-$len,$len);
}

sub load_mutation {
  my $t1 = Data::Table::fromTSV("table1.tsv");
  # open(OUT,">mutation_info.txt") || die $!;
  # say OUT join("\t",'gene id', 'symbol', 'phenotype', 'dbSNP', 'chromPos', 'strand', 'up- & downstream seq');
  
  foreach my $r ( 0 .. $t1->lastRow ) {
    next if $t1->elm($r,'gene ID') eq '';
    my $link = $ucsc->resultset('RefLink')->search({locusLinkId => $t1->elm($r,'gene ID')});
    next if ( $link == 0 ); # 此基因数据库中没有转录本，如tRNA
    if ($t1->elm($r,'dbSNP') =~ /rs\d+/) {
      dump(mutation_to_chrpos($t1->elm($r,'dbSNP'), $t1->elm($r,'gene ID')));
    }
    else {
      dump(mutation_to_chrpos($t1->elm($r,'Mutation'), $t1->elm($r,'gene ID')));
    }
  }
}

sub mutation_to_chrpos {
  # return chromosome position for each input
  my ($mutation, $gi) = @_;
  given ($mutation) {
    when (/(rs\d+)/) {
      my $rs = $1;
      my $snp = $ucsc->resultset('Snp135')->search({name => $rs});
      if ( $snp == 0 ) {
        say "snp $rs not found in ucsc db";
      }
      else {
        return ($snp->first->chromstart + 1, $snp->first->chromend);
      }
    }
    when (/^\S+, (\d+)([ATCG])-([ATCG])$/i) {
      die 'bug !!!'; # need further work
      return "1: $1,$2,$3";
    }
    when (/^\S+, \d+-BP (\w+), (\d+)([ATCG]*)$/i) {
      say "2: $1,$2,$3";
      return cdspos_to_chrpos($2,$gi);
    }
    when (/^\S+, (\w)(\d+)(\w)$/) {
      return "3: $1,$2,$3";
    }
    when (/^\S+, (\w{3})(\d+)(\w{3})$/) {
      return "4: $1,$2,$3";
    }
    default {
      # say "\033[36m",$t1->elm($r, 'Mutation'),"\033[0m";
      return $mutation;
    }
  }
}

sub cdspos_to_chrpos {
  my ($cdspos,$gi) = @_;
  my $link = $ucsc->resultset('RefLink')->search({locusLinkId => $gi});
  my @chrposs;
  while(my $tx = $link->next ) {
    my $mrnaacc = $tx->mrnaacc;
    my $symbol = $tx->name;
    my $refgene = $ucsc->resultset('RefGene')->search({name => $mrnaacc })->first;
    my @exonStarts = split(',', $refgene->exonstarts);
    my @exonEnds = split(',', $refgene->exonends);
    my $strand = $refgene->strand;
    my $pos = $cdspos;
    # trim exons outside cds
    for ( my $i = $#exonStarts; $i>=0; $i--) {
      # left exons
      if ( $refgene->cdsstart + 1 > $exonEnds[$i] ) {
        splice(@exonStarts, $i, 1);
        splice(@exonEnds, $i, 1);
      }
      # right exons
      elsif ( $refgene->cdsend < $exonStarts[$i] + 1 ) {
        splice(@exonStarts, $i, 1);
        splice(@exonEnds, $i, 1);
      }
      # start exon
      elsif ( $refgene->cdsstart >= $exonStarts[$i]
            && $refgene->cdsstart + 1 <= $exonEnds[$i] ) {
        $exonStarts[$i] = $refgene->cdsstart;
      }
      # end exon
      elsif ( $refgene->cdsend >= $exonStarts[$i] + 1
            && $refgene->cdsend <= $exonEnds[$i] ) {
        $exonEnds[$i] = $refgene->cdsend;
      }
    }
    if ($strand eq '+') {
      my $chrpos = $refgene->cdsstart+$pos;
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
      push(@chrposs,[$mrnaacc, $chrpos]);
      # say get_chr_seqs($refgene->chrom, $strand, $chrpos)
    }
    else{
      my $chrpos = $refgene->cdsend - $pos + 1;
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
      push(@chrposs,[$mrnaacc, $chrpos]);
      # say get_chr_seqs($refgene->chrom, $strand, $chrpos)
    }
  }
  return @chrposs;
}

sub mrnapos_to_chrpos {
  my ($mrnapos,$gi) = @_;
  my $link = $ucsc->resultset('RefLink')->search({locusLinkId => $gi});
  my @chrposs;
  while(my $tx = $link->next ) {
    my $mrnaacc = $tx->mrnaacc;
    my $symbol = $tx->name;
    my $refgene = $ucsc->resultset('RefGene')->search({name => $mrnaacc })->first;
    my @exonStarts = split(',', $refgene->exonstarts);
    my @exonEnds = split(',', $refgene->exonends);
    my $strand = $refgene->strand;
    my $pos = $mrnapos;
    if ($strand eq '+') {
      my $chrpos = $refgene->txstart+$pos;
      for my $i ( 1 .. @exonStarts ) {
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
      push(@chrposs,[$mrnaacc, $chrpos]);
      say get_chr_seqs($refgene->chrom,$strand,$chrpos);
    }
    else{
      my $chrpos = $refgene->txend - $pos + 1;
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
      push(@chrposs,[$mrnaacc, $chrpos]);
      say get_chr_seqs($refgene->chrom,$strand,$chrpos);
    }
  }
  return @chrposs;
}

sub gene_strand {
  my $gs = shift || return '';
  my $kx = $ucsc->resultset('KgXref')->search_like({ geneSymbol => $gs,
    mRNA => 'NM%' });
  if ($kx !=0) {
      my $kx1 = $kx->next;
      my $kg = $ucsc->resultset('KnownGene')->search_like({name => $kx1->kgid })->first;
      return $kg->strand;
  }
  return '';
}

sub load_refgene {
  ### load refGene info from ucsc table refGene
  # 1 based cordinate
  my $srcdir = 'hs.GRCh37.p10.chr.feature_table'; # feature table dir
  my %ftfiles;
  my $info = Data::Table::fromTSV("$srcdir/info.txt");
  foreach my $i ( 0 .. $info->lastRow) {
    $ftfiles{$info->elm($i,'Type') . $info->elm($i,'Name')} = $info->elm($i,'RefSeq');
  }
  
  # split into records and parse rna positions
  foreach my $chr ( keys %ftfiles ) { ### [===|                           ] % done
    open(FT, "$srcdir/$ftfiles{$chr}.feature_table") || die $!;
    # File : "$srcdir/$ftfiles{$chr}.feature_table"
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
  # exonStarts, exonEnds, midPosition, up- down- length
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
  return (
    join(',', @pos[map {$_*2} (0 .. (@pos/2 - 1))]),   # start poss
    join(',', @pos[map {$_*2+1} (0 .. (@pos/2 - 1))])  # end poss
  );
}

sub chrpos_to_txseq {
  my ($chr,$pos1,$pos2) = @_;
  my @re;
  swap(\$pos1, \$pos2) if ( $pos1 > $pos2 );
  # dump(($chr,$pos1,$pos2));
  foreach my $i ( sort {$$a[0] <=> $$b[0]} @{$misc{lc($chr)}} ) {
    if ( $pos1 >= $$i[0] && $pos2 <= $$i[1] ) { # 找到包含此段位置的外显子
      my @seqpos = updownpos(
        ${$gene_info[$$i[2]]}[4],
        ${$gene_info[$$i[2]]}[5],
        int($pos1/2+$pos2/2),
        200
      );
      my $strand = ${$gene_info[$$i[2]]}[3];
      push(@re, [@{$gene_info[$$i[2]]}, "$chr:$$i[0]-$$i[1]",
          # get_chr_seqs($chr, $strand, $$i[0], $$i[1]),
          get_chr_seqs(
            $chr,
            $strand,
            join(',', @seqpos[map {$_*2} (0 .. (@seqpos/2 - 1))]),   # start poss
            join(',', @seqpos[map {$_*2+1} (0 .. (@seqpos/2 - 1))])  # end poss
          )
        ]);
    }
  }
  return @re;
}
