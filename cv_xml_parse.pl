#!/usr/bin/env perl
# Date: 2013-07-25
# Author: Zhao
# Purpose: parse downloaded xml file in clinvar ftp site
#

use strict;
use warnings; 
use XML::Simple;
use Data::Dump qw/dump/;
use 5.012;

my $xml = shift;

my ($cv_id, $cv_acc, $title, $CITE);

split_xml($xml);
say '';

sub split_xml {
  my $file = shift;
  open(XML, $file) || die $!;
  open(OUT, '>clinvar.dump.txt') || die $!;
  open $CITE, '>', 'clinvar_citation.txt' or die $!;
  $/ = '</ClinVarSet>';
  # <XML>;<XML>;
  my $i = 1;
  while (<XML>) {
    next unless $_ =~ /ClinVarSet/;
    my $set = XMLin($_);
    $cv_id = $$set{'ID'};
    my %RCVA = %{$$set{'ReferenceClinVarAssertion'}};
    # my ($cv_acc, $title, $gene_id, $omim_id, $hgvs, $omim_av, $dbsnp, $sl_acc, $sl_ass, $sl_chr, $sl_start, $sl_stop, $type);
    $cv_acc = $RCVA{'ClinVarAccession'}{'Acc'};
    $title = $$set{'Title'};
    # next unless ($cv_acc eq 'RCV000029674');
    say "\x1b[31m$cv_acc\t",$i++,"\t",$i/629.12,"\x1b[0m";

    parse_citation0($$set{'ClinVarAssertion'});
  # bar($i++, 48971);
  # next;
    if ( is_hash($RCVA{'MeasureSet'}{'Measure'}) ) {
      parse(\%{$RCVA{'MeasureSet'}{'Measure'}});
    }
    elsif ( is_array($RCVA{'MeasureSet'}{'Measure'}) ) {
      foreach my $i (@{$RCVA{'MeasureSet'}{'Measure'}}) {
        parse(\%$i);
      }
    }

    # bar($i++, 62912);
  }
  close OUT;
}

sub parse_citation0 {
  my $od = shift;
  if (is_array($od)) {
    foreach my $i (@{$od}) {
      parse_citation1($$i{'ObservedIn'});
    }
  }
  if (is_hash($od)) {
    parse_citation1($$od{'ObservedIn'});
  }
}

sub parse_citation1 {
  my $od = shift;
  if (is_array($od)) {
    foreach my $i (@{$od}) {
      parse_citation2($$i{'ObservedData'});
    }
  }
  if (is_hash($od)) {
    parse_citation2($$od{'ObservedData'});
  }
}

sub parse_citation2 {
  my $od = shift;
  if (is_array($od)) {
    foreach my $i (@{$od}) {
      parse_citation3($$i{'Citation'});
    }
  }
  if (is_hash($od)) {
    parse_citation3($$od{'Citation'});
  }
}

sub parse_citation3 {
  my $od = shift;
  if (is_array($od)) {
    foreach my $i (@{$od}) {
      parse_citation4($$i{'ID'});
      parse_citation5($$i{'CitationText'});
    }
  }
  if (is_hash($od)) {
    parse_citation4($$od{'ID'});
    parse_citation5($$od{'CitationText'});
  }
}

sub parse_citation4 {
  my $od = shift;
  return unless defined $od;
  say $CITE join("\t",$cv_id,"$$od{'Source'}:$$od{'content'}");
  # say "\t\t\t",join("\t",$cv_id,"$$od{'Source'}:$$od{'content'}");
}

sub parse_citation5 {
  my $od = shift;
  return unless defined $od;
  say $CITE join("\t",$cv_id,$od);
  # say "\t\t\t",join("\t",$cv_id,$od);
}

sub parse {
  my $RCVA = shift;
  my %RCVA = %{$RCVA};
  if (!defined $RCVA{'MeasureRelationship'}) {
    return;
  }
  if ( is_array( $RCVA{'MeasureRelationship'} ) ) {
      foreach my $i (@{$RCVA{'MeasureRelationship'}}) {
        my %new_RCVA = %RCVA;
        $new_RCVA{'MeasureRelationship'} = \%$i;
        parse_gene(\%new_RCVA);
      }
  }
  elsif ( is_hash( $RCVA{'MeasureRelationship'} ) ) {
    parse_gene(\%RCVA);
  }
  else {
    dump $RCVA{'MeasureRelationship'};
    exit(1);
  }
}

sub parse_gene {
  my $RCVA = shift;
  my %RCVA = %{$RCVA};
  my ($gene_id, $omim_id, $hgvs, $omim_av, $dbsnp, $sl_acc, $sl_ass, $sl_chr,
      $sl_start, $sl_stop, $type, $a1, $a2, $phenotype )
      = ('','','','','','','','','','','','','','');
    # if ( is_hash( $RCVA{'MeasureRelationship'} ) ) {
    # dump $RCVA{'MeasureRelationship'};
    #  if ( $cv_acc eq 'RCV000009535') {
    #     dump $RCVA{'MeasureRelationship'}{'XRef'};
    #     dump @{$RCVA{'MeasureRelationship'}{'XRef'}};
    # }
    if ( is_hash( $RCVA{'MeasureRelationship'}{'XRef'} ) ) {
      if ( $RCVA{'MeasureRelationship'}{'XRef'}{'DB'} eq 'Gene' ) {
        $gene_id = $RCVA{'MeasureRelationship'}{'XRef'}{'ID'};
      }
      if ( $RCVA{'MeasureRelationship'}{'XRef'}{'DB'} eq 'OMIM' ) {
        $omim_id = $RCVA{'MeasureRelationship'}{'XRef'}{'ID'};
      }
    }
    else {
    foreach my $i (@{$RCVA{'MeasureRelationship'}{'XRef'}}) {
      if ($$i{'DB'} eq 'Gene') {
        $gene_id = $$i{'ID'};
      }
      elsif ($$i{'DB'} eq 'OMIM') {
        $omim_id = $$i{'ID'};
      }
    }
    }
    # }

    if (is_array($RCVA{'XRef'}) ) {
      foreach my $i (@{$RCVA{'XRef'}}) {
        if ($$i{'DB'} eq 'dbSNP') {
          $dbsnp = $$i{'ID'};
        }
        elsif ($$i{'DB'} eq 'OMIM') {
          $omim_av = $$i{'ID'};
          $omim_av =~ s/^\d+//;
        }
      }
    }
    elsif (is_hash($RCVA{'XRef'}) ) {
      my $hashref = $RCVA{'XRef'};
      if ($$hashref{'DB'} eq 'dbSNP') {
        $dbsnp = $$hashref{'ID'};
      }
      elsif ($$hashref{'DB'} eq 'OMIM') {
        $omim_av = $$hashref{'ID'};
        $omim_av =~ s/^\d+//;
      }
    }
    # dump ($omim_av,$dbsnp);

    if ( is_hash($RCVA{'SequenceLocation'})) {
      $sl_acc = $RCVA{'SequenceLocation'}{'Accession'};
      $sl_ass = $RCVA{'SequenceLocation'}{'Assembly'};
      $sl_chr = $RCVA{'SequenceLocation'}{'Chr'};
      $sl_start = $RCVA{'SequenceLocation'}{'start'};
      $sl_stop = $RCVA{'SequenceLocation'}{'stop'};
    }
    else {
      return 1;
    }
    # dump ($sl_acc, $sl_ass, $sl_chr, $sl_start, $sl_stop);

    $type = $RCVA{'Type'};

    $hgvs = '';
    if (is_array($RCVA{'AttributeSet'})) {
    foreach my $i (@{$RCVA{'AttributeSet'}}) {
      if ($$i{'Attribute'}{'Type'} =~ /^HGVS/) {
        $hgvs .= $$i{'Attribute'}{'content'} . ';'
      }
    }
    }
    # dump ($hgvs);
    # dump ($cv_acc, $title, $gene_id, $omim_id, $hgvs, $omim_av, $dbsnp, $sl_acc, $sl_ass, $sl_chr, $sl_start, $sl_stop, $type);
    $omim_av =~ s/^\.//;
    if ($title =~ /([ATCG]+)>([ATCG]+)/) {
      $a1 = $1;
      $a2 = $2;
    }
    if ($title =~ / AND (.*)/) {
      $phenotype = $1;
    }
    $sl_start = '' unless defined $sl_start;
    $sl_stop = '' unless defined $sl_stop;
    $sl_acc = '' unless defined $sl_acc;
    $sl_ass = '' unless defined $sl_ass;
    $sl_chr = '' unless defined $sl_chr;
    say OUT join("\t", ($cv_id, $cv_acc, $title, $a1, $a2, $phenotype, $gene_id, $omim_id, $hgvs, $omim_av, $dbsnp, $sl_acc, $sl_ass, $sl_chr, $sl_start, $sl_stop, $type) );
    return 0;
}


# **************************************************************
# This function check if the reference is an ARRAY.
#
#  @see: http://affy.blogspot.com/p5be/ch08.htm
#  @example: print "ERROR: A ARRAY is needed\n" if ( !is_array(\@$array) );
 
sub is_array {
 
my $ref = shift;
return 0 unless ref $ref;
if ( ref($ref) eq "ARRAY" ) { return 1; } else { return 0; }
}

# **************************************************************
# This function check if the reference is a HASH.
#
#  @example: print "ERROR: A HASH is needed\n" if ( !is_hash(\%$hash) );
 
sub is_hash {
 
my $ref = shift;
return 0 unless ref $ref;
if ( $ref =~ /^HASH/ ) { return 1; } else { return 0; }
 
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
