#!/usr/bin/env perl
# Author: zhao
# Date: 2013-09-26
# Purpose: use clustal o output grouped fasta format, convert to iupac code

use 5.012;
use Data::Dump qw/dump/;
use Array::Transpose;
use Array::Utils qw/:all/;

my $fas = shift || die "fasta file!";

open my $fh, '<', $fas || die $!;

my ($sid, %seqs);
while (<$fh>) {
  chomp;
  if (/^>/) {
    $sid = $_;
  }
  else {
    $seqs{$sid} .= $_;
  }
}

to_iupac(\%seqs);

sub to_iupac {
  my $s = shift;
  my %s = %$s;
  my ($l,@nt,@ntt);
  foreach my $k (keys %s) {
    if(defined $l && $l != length($s{$k})) {
      say 'length is not identical.';
      exit;
    }
    else {
      $l = length($s{$k});
    }
  }
  say ">length:$l";
  my $i = 0;
  foreach my $k (keys %s) {
    $nt[$i++] = [split(//, $s{$k})];
  }
  @ntt = transpose(\@nt);
  foreach $i ( 0 .. $#ntt) {
    print iupac_translate( $ntt[$i] );
  }
  say "";
}

sub iupac_translate {
  my $a = shift;
  my @a = @$a;
  my @b = ('-', '.');
  @a = unique(@a);
  @a = array_minus(@a, @b);
  my %code = (
    'A' => ['A'],
    'T' => ['T'],
    'G' => ['G'],
    'C' => ['C'],
    'R' => ['G','A'],
    'Y' => ['C','T'],
    'S' => ['G','C'],
    'W' => ['A','T'],
    'K' => ['G','T'],
    'M' => ['A','C'],
    'B' => ['G','C','T'],
    'D' => ['A','G','T'],
    'H' => ['A','C','T'],
    'V' => ['A','C','G'],
    'N' => ['A','C','G','T'],
  );
  foreach my $k ( keys %code ) {
    if ( !array_diff(@a,  @{$code{$k}}) ) {
      return $k;
    }
  }
  return join('', '[',@a,']');
}
