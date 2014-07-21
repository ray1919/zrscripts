#!/usr/bin/env perl
# Ahthor: Zhao
# Date: 2013-08-07
# Purpose: query omim and clinvar db for gene variation data

use 5.012;
use Data::Dump qw(dump);
use Smart::Comments;
use lib '/home/zhaorui/bin/lib';
use Ucsc::Schema;
use Ncbi::Schema;

my $ncbi = Ncbi::Schema->connect('dbi:mysql:ncbi', 'ncbi', 'ncbi');
my $ucsc = Ucsc::Schema->connect('dbi:mysql:ucsc_hg19', 'ucsc', 'ucsc');

my $file_save = "clinvar_omim_info.txt";
unlink $file_save if (-f $file_save);
load_mutation_from_query(shift);
exit;

sub load_mutation_from_query {
  my $file = shift;
  open my $fin, '<', $file or die $!;
  # open my $name, '>', 'mutation_name.txt' || die $!;
  <$fin>;
  while(<$fin>) {
    chomp;
    my @line = split("\t", $_);
    ### phenotype: $line[1]
    # OMIM phenotype
    my $keyword = keyword($line[1]);
    # $line[1] =~ s/\(.*\)//g;
    print "keyword: $keyword";
    my ($clin,$omim);
    if (good_or_not()) {
       $clin = $ncbi->resultset('Clinvar')->search({
        -or => [
        phenotype => { 'like', "%$line[1]%" },
        phenotype => { 'like', "%$keyword%" }
        ]},
        {
          columns => [ 'phenotype' ],
          distinct => 1
        }
      );
       $omim = $ncbi->resultset('OmimAvsnp')->search({
        -or => [
        av_name => { 'like', "%$line[1]%" },
        av_name => { 'like', "%$keyword%" }
        ]},
        {
          columns => [ 'av_name' ],
          distinct => 1
        }
      );
    }
    else {
       $clin = $ncbi->resultset('Clinvar')->search({
        phenotype => { 'like', "%$line[1]%" }},
        {
          columns => [ 'phenotype' ],
          distinct => 1
        }
      );
       $omim = $ncbi->resultset('OmimAvsnp')->search({
        av_name => { 'like', "%$line[1]%" }},
        {
          columns => [ 'av_name' ],
          distinct => 1
        }
      );
    }
    my $i = 0;
    my @records = ();
    while ( my $cv = $clin->next ) {
      say $i++, ' C ', highlight($cv->phenotype,split(/\W/, $line[1]));
      push(@records, [@line,'ClinVar',$cv->phenotype]);
    }
    while ( my $av = $omim->next ) {
      say $i++, ' O ', highlight($av->av_name,split(/\W/, $line[1]));
      push(@records, [@line,'OMIM',$av->av_name]);
    }
    my $type = <STDIN>;
    chomp($type);
    my @num = split(/\D/, $type);
    if ($#num == -1) {
      @num = 0 .. ($i - 1);
      say join(' ', @num);
    }
    # say $name join("\n",@records[@num]);
    foreach my $r (@records[@num]) {
      get_mutation(@$r);
    }
  }
}

sub get_mutation {
  my ($acmg,$condition,$db,$phenotype) = @_;
  open my $fo, '>>', $file_save or die $!;
  given ($db) {
    when ('ClinVar') {
      my $cv = $ncbi->resultset('Clinvar')->search({
        phenotype => $phenotype});
      while ( my $c = $cv->next ) {
        say $fo join("\t",$acmg,$condition,$db,$phenotype,
          $c->gene_id, $c->gene->symbol, $c->omim_id, $c->omim_av,
          $c->dbsnp, $c->hgvs, $c->sl_acc, $c->sl_chr,$c->sl_start, $c->sl_stop);
      }
    }
    when ('OMIM') {
      my $omim = $ncbi->resultset('OmimAvsnp')->search({
        av_name => $phenotype});
      while ( my $o = $omim->next ) {
        say $fo join("\t",$acmg,$condition,$db,$phenotype,
          $o->locus_id, $o->locus_symbol, $o->omim_id, $o->av_id,
          $o->dbsnp, $o->mutation, '', '', '', '');
      }
    }
  }
  close $fo;
}

sub good_or_not {
  print '  [Y/n]:';
  my $re = <STDIN>;
  if ($re =~ /n/i) {
    return 0;
  }
  else {
    return 1;
  }
}

sub highlight {
  my ($str, @keys) = @_;
  foreach my $key ( @keys ) {
    next if length($key) < 3;
    $str =~ s/$key/\x1b[0;33m$key\x1b[0m/i;
  }
  return $str;
}

sub keyword {
  my @words = split(/\W/, shift);
  my $maxlen = 0;
  my $word = '';
  foreach my $i ( @words ) {
    next if ($i ~~ [qw/disease mutation/]);
    my $len = length($i);
    if ( $len > $maxlen ) {
      $maxlen = $len;
      $word = $i;
    }
  }
  return $word;
}

sub load_mutation_from_gi {
  my $gifile = shift;

  open my $GI, '<', $gifile || die $!;
  open my $OUT, '>', 'gene_clinvars.txt' || die $!;
  while (<$GI>) {
    chomp;
    my $gi = $_;
    my $gene = $ncbi->resultset('GeneInfo')->search({geneid => $gi});
    my $symbol = $gene->first->symbol;

    say $gi;
    my $link = $ncbi->resultset('Clinvar')->search({gene_id => $gi});
    if ($link == 0) {
      say $OUT join("\t",$gi,$symbol);
    }
    else {
      while ( my $cv = $link->next ) {
        # OMIM phenotype
        my $omim = $ncbi->resultset('OmimAvsnp')->search({});


        my @title = split(' AND ', $cv->title);
        $title[1] = join('; ', @title[1 .. $#title]);
        if ($title[0] =~ /(NM_\d+)/) {
          my $ti = $1;
          my $tx = $ucsc->resultset('RefGene')->search({name => $ti})->first;
          say $OUT join("\t",$gi,$symbol,@title[0,1],$cv->omim_id,$cv->omim_av,
            $cv->dbsnp,$tx->name,$tx->chrom,$tx->strand,$tx->txstart,$tx->txend,
            $tx->cdsstart,$tx->cdsend,$tx->exonstarts,$tx->exonends,
            $cv->sl_start,$cv->sl_stop,
            get_chr_seqs($tx->chrom,$tx->strand,
              $cv->sl_start-200,$cv->sl_stop+200));
        }
        else {
          say $OUT join("\t",$gi,$symbol,@title[0,1],$cv->omim_id,$cv->omim_av,
            $cv->dbsnp,'','','','','','','','','',
            $cv->sl_start,$cv->sl_stop,
            get_chr_seqs('chr'.$cv->sl_chr,'+',
              $cv->sl_start-200,$cv->sl_stop+200));
        }
      }
    }
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
