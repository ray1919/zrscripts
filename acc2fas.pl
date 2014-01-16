#!/usr/bin/env perl
# Date: 2013-10-30
# Source: http://www.ncbi.nlm.nih.gov/books/NBK25498/

use Data::Dump qw/dump/;
use LWP::Simple;
use 5.010;
$acc_list = 'NM_009417,NM_000547';
@acc_array = split(/,/, $acc_list);
open $fh1, '<', 'consensus.txt' or $!;
open $fh2, '>', 'all.fasta' or $!;
@acc_array = <$fh1>;
map {chomp} @acc_array;

$each = 10;
while ( my @a10 = splice(@acc_array, 0, $each) ) {
  say $fh2 acc2fasta(@a10);
  say $#acc_array;
}

sub acc2fasta {
  my @acc_array = @_;
  #append [accn] field to each accession
  for ($i=0; $i < @acc_array; $i++) {
     $acc_array[$i] .= "[accn]";
  }
  
  #join the accessions with OR
  $query = join('+OR+',@acc_array);
  
  #assemble the esearch URL
  $base = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/';
  $url = $base . "esearch.fcgi?db=nucleotide&term=$query&usehistory=y";
  
  #post the esearch URL
  $output = get($url);
  
  #parse WebEnv and QueryKey
  $web = $1 if ($output =~ /<WebEnv>(\S+)<\/WebEnv>/);
  $key = $1 if ($output =~ /<QueryKey>(\d+)<\/QueryKey>/);
  
  #assemble the efetch URL
  $url = $base . "efetch.fcgi?db=nuccore&query_key=$key&WebEnv=$web";
  $url .= "&rettype=fasta&retmode=text";
  
  #post the efetch URL
  $fasta = get($url);
  return $fasta;
}
