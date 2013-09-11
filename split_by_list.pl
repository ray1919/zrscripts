#!/usr/bin/env perl
# Author: Zhao
# Date: 2013-09-11
# Purpose: add pathway annotation to a list of mirna

use 5.010;
use Data::Table;
use POSIX qw(ceil);
# R packages: GOstats, EMA, fdrtool, org.Pt.eg.db, KEGG.db

my $f1 = shift || "mirna_list.txt";
my $f2 = shift || "mirna_target.txt";

# grep -f mirna_list.txt -w ~/ct208/db/mirna/target_db/validated/mirtarbase/hsa_MTI_4.3.txt > mirna_target.txt
# split_by_list($f1, $f2);
# perl genesetenrichment-KEGG.pl splits/ entrez_gi.txt 0.05 0.2
table_splits();


sub table_splits {
  my @files = glob "splits/*";
  open $fh2, '>', 'mirna_pathway.txt' || die $!;
  foreach my $f (@files) {
    next if ($f =~ /\.\w+$/);
    my $mirna = $f;
    $mirna =~ s/splits\///;
    if ( -f "$f.ENR") {
      $t = Data::Table::fromTSV("$f.ENR");
      say $fh2 "$mirna\t",join(', ',$t->col('Term'));
    }
    elsif ( line_count($f) < 7 && line_count($f) > 0) {
      my $path = kg_path_from_gi($f);
      say $fh2 "$mirna\t$path";
    }
    else {
      say $fh2 "$mirna\t";
    }
  }
}

sub line_count {
  my $file = shift;
  open my $fh, '<', $file || die $!;
  return scalar(()=<$fh>);
}

sub split_by_list {
open $fh1, '<', $f1 || die $1;
my @file1 = <$fh1>;
map {chomp} @file1;
mkdir('splits');

foreach my $key (@file1) {
  print "$key\n";
  system("grep $key $f2 -w -i|awk -F \"\\t\" '{print \$5;}' > splits/$key");
}
}

sub kg_path_from_gi {
  my $file = shift || die "Input a gi file name";
  my $og = 'hsa';
  my $dir = '.dl';
  my $each = 10;
  exit unless -f $file;
  open $fh, '<', $file || die $!;
  
  my @gl = ();
  while ( <$fh> ) {
    chomp;
    push(@gl, "$og:$_");
  }
  
  $i = 1;
  my $n = ceil(scalar @gl / $each);
  my @return;
  # retrieve 10 records a time (max limit)
  while ( my @g10 = splice(@gl, 0, $each) ) {
    $link = join('+',@g10);
    $url = "http://rest.kegg.jp/get/$link";
    $of = crypt($link,$link);
    $of =~ s/\W//g;
    unless (-f "$dir/$of") {system("wget $url -O $dir/$of -q")};

    my %genes = read_kg_entry("$dir/$of");
    
    my (%pathways,%p_genes);
    foreach my $gi (keys %genes) {
      map {$pathways{$_}++;push(@{$p_genes{$_}},$genes{$gi}{'NAME'}[0]);} @{$genes{$gi}{'PATHWAY'}};
    }
    foreach my $k (sort {$pathways{$b} <=> $pathways{$a}} keys %pathways) {
      push(@return, $k);
    }
  }
  map {s/$og\d+\s+//g} @return;
  return join(', ', @return);
}

sub read_kg_entry {
  my $file = shift;
  open $kg, '<', $file || die $!;
  my @entry = <$kg>;
  my %entry;
    my ($gi,$key,@value);
  foreach my $c ( @entry ) {
    if ($c =~ /^([A-Z_]+)\s+(.*)/) {
      if ($1 eq 'ENTRY') {
        $2 =~ /(\S+)/;
        $gi = $1;
        @value = ();
        $key = '';
      }
      else {
        $key = $1;
        $value[0] = $2;
        $entry{$gi}{$key} = [@value];
      }
    }
    elsif ($c =~ /^\/\/\//) {
      my @names = split(', ', $entry{$gi}{'NAME'}[0]);
      map {$_ = [split('  ',$_)] } @{$entry{$gi}{'GENE'}};
      # dump @{$entry{$gi}{'GENE'}};
      # exit;
      $entry{$gi}{'NAME'} = [@names];
      # dump %entry;
    }
    elsif ($key =~ /SEQ/) {
      next;
    }
    elsif ($c =~ /\s+(.*)/) {
      push(@{$entry{$gi}{$key}}, $1);
    }
    else {
      die $gi;
    }
  }
  return %entry;
}
