#!/usr/bin/env perl
# Author: Zhao
# Date: 2013-10-25
# Purpose: get refseq sequence to each gi

use lib '/home/zhaorui/bin/lib';
use Ncbi::Schema;
use Ucsc::Schema;
use 5.010;
use LWP::Simple;
my %unknow;
my $schema = Ncbi::Schema->connect('dbi:mysql:ncbi', 'ncbi', 'ncbi');
my $ucsc = Ucsc::Schema->connect('dbi:mysql:ucsc_hg19', 'ucsc', 'ucsc');
$file = shift || die 'no file';
my %mrna = load_refmrna() if -f 'refMrna.fa';
open(GS,$file) || die $!;
open(GI,">$file.txt") || die $!;
while (<GS>) {
  chomp;
  my @line = split("\t", $_);
  # say GI join("\t", $line[0], get_gn($line[0]), @line[1 .. $#line]);
  # get_refseq($line[0]);
  gene2refseq($line[0]);
}

sub get_refseq {
  my $gid = shift;
  my $gi= $ucsc->resultset('RefLink')->search({locuslinkid => $gid});
  while (my $rna = $gi->next) {
    if (defined $mrna{$rna->mrnaacc}) {
      say GI join("\t", $rna->name, $gid, $rna->product, $rna->mrnaacc,
        $mrna{$rna->mrnaacc} );
    }
    else {
      say GI join("\t", $rna->name, $gid, $rna->product, $rna->mrnaacc );
    }
  }
}

sub load_refmrna {
  open $fh1, '<', "refMrna.fa" or die $!;
my ($sid, %seqs);
while (<$fh1>) {
  chomp;
  if (/^>(\S+)/) {
    $sid = $1;
  }
  else {
    $seqs{$sid} .= $_;
  }
}
  return %seqs;
}

sub gene2refseq {
  my $gid = shift;
  my $gi= $schema->resultset('Gene2refseq')->search(
    {geneid => $gid},
    {
      columns   => [ qw/tax_id geneid rna_acc rna_gi symbol/ ],
      distinct  => 1,
    }
  );
  # if ($gi >= 1) {
  while (my $rna = $gi->next) {
    my $gi = $rna->rna_gi;
    my $url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=$gi&rettype=fasta&retmode=text";
    my $fasta = get($url);
    if ($fasta =~ s/.*$gi.*//) {
      $fasta =~ s/\n//g;
      $fasta =~ s/\s//g;
    }
    else {
      say "could not get fasta for $gid: ",$rna->rna_acc;
      exit;
    }
    say GI join("\t", $rna->symbol, $gid, $rna->rna_acc, $rna->tax_id, $fasta );
  }
}

sub get_gn {
  my $gid = shift;
  my $gi= $schema->resultset('GeneInfo')->search({geneid => $gid});
  if ($gi == 1) {
    $gi1 = $gi->first;
    return join("\t",$gi1->symbol, $gi1->description, $gi1->synonyms);
  }
  else {
    return 'NULL';
  }
}

sub get_gi {
  my $gs = shift;
  my $og = shift;
  my $gi= $schema->resultset('GeneInfo')->search({symbol => $gs,
    tax_id => $og});
  if ($gi == 1) {
    $gi1 = $gi->first;
    return $gi1->geneid;
  }
  else {
    my $gi= $schema->resultset('GeneInfo')->search({
      -or => [
        synonyms => {'like', "$gs|%"},
        synonyms => {'like', "%|$gs|%"},
        synonyms => {'like', "%|$gs"},
        synonyms => {'like', "$gs"},
        ],
      # type_of_gene => 'protein-coding',
      tax_id => 9606});
    if ($gi == 1) {
      $gi1 = $gi->first;
      return $gi1->geneid;
    }
    else {
      if (!exists $unknow{$gs}) {
        print " $gs: ";
        my $gid = <STDIN>;
        chomp($gid);
        $unknow{$gs} = $gid;
      }
      return $unknow{$gs};
    }
  }
}

sub ask_user {
  print "$_[0] [$_[1]]: ";
  my $rc = <>;
  chomp $rc;
  if($rc eq "") { $rc = $_[1]; }
  return $rc;
}

