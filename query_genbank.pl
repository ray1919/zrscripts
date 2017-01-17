#!/usr/bin/env perl

use LWP::Simple;
use 5.012;
query_genbank('txid1335626[Organism:exp] AND "complete genome"[title]', 'mers.gb');

sub query_genbank {
  my ($query,$save) = @_;
  my $rettype = 'gb';

  #assemble the esearch URL
  my $base = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/';
  my $url = $base . "esearch.fcgi?db=nuccore&term=$query&usehistory=y";
  
  #post the esearch URL
  my $output = get($url);
  
  #parse WebEnv and QueryKey
  my $web = $1 if ($output =~ /<WebEnv>(\S+)<\/WebEnv>/);
  my $key = $1 if ($output =~ /<QueryKey>(\d+)<\/QueryKey>/);
  my $count = $1 if ($output =~ /<Count>(\d+)<\/Count>/);
  
  #assemble the efetch URL
  $url = $base . "efetch.fcgi?db=nuccore&query_key=$key&WebEnv=$web";
  $url .= "&rettype=$rettype&retmode=text";
  
  #post the efetch URL
  # my $fasta = get($url);

  # save fasta to file
  open my $fh1, '>', $save;
  # say $fh1 $fasta;

  # retrieve data in batches of 50
  my $retmax = 2;
  for (my $retstart = 0; $retstart < $count; $retstart += $retmax) {
        my $efetch_url = $base ."efetch.fcgi?db=nuccore&WebEnv=$web";
        $efetch_url .= "&query_key=$key&retstart=$retstart";
        $efetch_url .= "&retmax=$retmax&rettype=$rettype&retmode=text";
        my $efetch_out = get($efetch_url);
        say $fh1 $efetch_out;
        bar($retstart, $count);
  }
  close $fh1;

  return 1;
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
