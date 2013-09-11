#!/usr/bin/env perl
# Author: Zhao Rui
# Date: 2013-07-23
# Purpose: extract gene mutation ALLELIC VARIANTS table from download data

use 5.012;
use Data::Dump qw/dump/;
use lib 'lib';
use Ncbi::Schema;
use Smart::Comments;
my $schema = Ncbi::Schema->connect('dbi:mysql:ncbi', 'ncbi', 'ncbi');

my $file1 = 'mim2gene.txt';
my $file2 = 'omim.txt';
my %mim2gene;

open(F1, $file1) || die $!;
while (<F1>) {
  chomp;
  my @line = split("\t", $_);
  if ( $line[1] =~ /gene/ ) {
    say $line[0] if (exists $mim2gene{$line[0]});
    $mim2gene{$line[0]} = [@line[2,3]];
  }
}
close(F1);
say scalar keys %mim2gene, " records.";

open(F2, $file2) || die $!;
open(F3, '>omim_av.txt') || die $!;
my $record = '';
my $i = 1;
while (<F2>) {
  if (/\*RECORD\*/) {
    parse_omim($record);
    $record = '';
  }
  $record .= $_;
  bar($i++, 3902151);
}

sub parse_omim {
  my $record = shift;
  if ( $record =~ /\*FIELD\* AV/) {
    $record =~ /\*FIELD\* NO\n(\d+)/;
    my $omim_id = $1;
    while ($record =~ /\n\.(0\d{3})\n(.*?)\n\n/sg) {
      my $omimvar_id = $1;
      my @phenotype = split("\n", $2);
      if ($2 =~ /\n\.(0\d{3})\n(.*)/s) {
        $omimvar_id = $1;
        @phenotype = split("\n", $2);
      }
      $phenotype[$#phenotype] =~ s/ \(dbSNP.*//;
      my $dbsnp = '';
      my $snp = $schema->resultset('OmimVarLocusIdSnp')->search({
          omim_id => $omim_id,
          omimvar_id => $omimvar_id
        });
      if ($snp != 0) {
        $dbsnp = $snp->first->snp_id;
      }
      my $mutation = splice(@phenotype, -1, 1);
      my $av_name = join(' ', @phenotype);
      # if ($omim_id == 607102 ) {
      # if ($snp != 0) {
      say F3 join("\t",$omim_id, @{$mim2gene{$omim_id}},$omimvar_id,$av_name,$mutation,$dbsnp);
      # }
    }
    # <STDIN>;
  }
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
