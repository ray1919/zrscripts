#!/usr/bin/env perl
# Date: 2013-07-25
# Author: Zhao
# Purpose: parse downloaded xml file in clinvar ftp site
#
# Update: 2014-06-06
# Update: 2017-02-08
# hgvs \NNM_xxxx bug fixed.
# xml download location: ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/xml/


use strict;
use warnings; 
use XML::Simple;
use Data::Dump qw/dump/;
use 5.012;

my $xml = shift;

my ($cv_id, $cv_acc, $title, $CITE, $cli_sig, $review_sta);

split_xml($xml);
say '';

sub split_xml {
  my $file = shift;
  open(XML, $file) || die $!;
  open(OUT, ">clinvar.$file.txt") || die $!;
  open $CITE, '>', "clinvar_citation.$file.txt" or die $!;
  <XML>; <XML>; <XML>;
  $/ = '</ClinVarSet>';
  my $i = 1;
  while (<XML>) {
    next unless $_ =~ /ClinVarSet/;
    my $set = XMLin($_);
    $cv_id = $$set{'ID'};
    my %RCVA = %{$$set{'ReferenceClinVarAssertion'}};
    # my ($cv_acc, $title, $gene_id, $omim_id, $hgvs, $omim_av, $dbsnp, $cli_sig, $sl_acc, $sl_ass, $sl_chr, $sl_start, $sl_stop, $type);
    $cv_acc = $RCVA{'ClinVarAccession'}{'Acc'};

    $cli_sig = $RCVA{'ClinicalSignificance'}->{Description};
    $review_sta = $RCVA{'ClinicalSignificance'}->{ReviewStatus};

    $title = $$set{'Title'};
    # next unless ($cv_acc eq 'RCV000029674');
    local $| = 1;
    print "\r$cv_acc\t",$i++,"\t",sprintf "%.2f" => $i/10000;
    local $| = 0;

    parse_citation0($$set{'ClinVarAssertion'});
  # next;
    if ( is_hash($RCVA{'MeasureSet'}{'Measure'}) ) {
      parse(\%{$RCVA{'MeasureSet'}{'Measure'}});
    }
    elsif ( is_array($RCVA{'MeasureSet'}{'Measure'}) ) {
      foreach my $i (@{$RCVA{'MeasureSet'}{'Measure'}}) {
        parse(\%$i);
      }
    }

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
      = ('\N','\N','\N','\N','\N','\N','\N','\N','\N','\N','\N','\N','\N','\N');
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

    my (@dbsnps,@omim_avs);
    if (is_array($RCVA{'XRef'}) ) {
      foreach my $i (@{$RCVA{'XRef'}}) {
        if ($$i{'DB'} eq 'dbSNP') {
          push @dbsnps, "rs" . $$i{'ID'};
        }
        elsif ($$i{'DB'} eq 'OMIM') {
          # $omim_av = $$i{'ID'};
          # $omim_av =~ s/^\d+//;
          push @omim_avs, $i->{ID};
        }
      }
      $dbsnp = join ';', @dbsnps;
      $omim_av = join ';', @omim_avs;
    }
    elsif (is_hash($RCVA{'XRef'}) ) {
      my $hashref = $RCVA{'XRef'};
      if ($$hashref{'DB'} eq 'dbSNP') {
        $dbsnp = "rs" . $$hashref{'ID'};
        # push @dbsnps, $dbsnp;
      }
      elsif ($$hashref{'DB'} eq 'OMIM') {
        $omim_av = $$hashref{'ID'};
        # $omim_av =~ s/^\d+//;
        # push @omim_avs, $omim_av;
      }
    }
    if ($dbsnp eq '') {
      $dbsnp = '\N';
    }
    if ($omim_av eq '') {
      $omim_av = '\N';
    }

    if ( is_hash($RCVA{'SequenceLocation'})) {
      $sl_acc = $RCVA{'SequenceLocation'}{'Accession'};
      $sl_ass = $RCVA{'SequenceLocation'}{'Assembly'};
      $sl_chr = $RCVA{'SequenceLocation'}{'Chr'};
      $sl_start = $RCVA{'SequenceLocation'}{'start'};
      $sl_stop = $RCVA{'SequenceLocation'}{'stop'};
    }
    elsif (is_array($RCVA{'SequenceLocation'})) {
      foreach my $i (@{$RCVA{'SequenceLocation'}}) {
        $sl_acc = $i->{Accession};
        $sl_ass = $i->{Assembly};
        $sl_chr = $i->{Chr};
        $sl_start = $i->{start};
        $sl_stop = $i->{stop};
        last if ($sl_ass eq 'GRCh38'); # prefer to GRCh38 version
      }
    }
    else {
      ($sl_acc, $sl_ass, $sl_chr, $sl_start, $sl_stop) = ('\N') x 5;
    }
    map {$_ = '\N' unless defined $_} ($sl_acc, $sl_ass, $sl_chr, $sl_start, $sl_stop);
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
    if ($hgvs eq '') {
      $hgvs = '\N';
    }
    # dump ($hgvs);
    # dump ($cv_acc, $title, $gene_id, $omim_id, $hgvs, $omim_av, $dbsnp, $sl_acc, $sl_ass, $sl_chr, $sl_start, $sl_stop, $type);
    if ($title =~ /([ATCG]+)>([ATCG]+)/) {
      $a1 = $1;
      $a2 = $2;
    }
    if ($title =~ / AND (.*)/) {
      $phenotype = $1;
    }

    # collapse records if have multi-rs#
    if ( $#dbsnps > 0 ) {
      for my $i ( 0 .. $#dbsnps ) {
          if ($#omim_avs == $#dbsnps) {
              say OUT join("\t", ($cv_id, $cv_acc, $title, $phenotype, $gene_id,
                  $omim_id, $hgvs, $omim_avs[$i], $dbsnps[$i], $cli_sig, $sl_acc,
                  $sl_ass, $sl_chr, $sl_start, $sl_stop, $type) );
          } else {
              say OUT join("\t", ($cv_id, $cv_acc, $title, $phenotype, $gene_id,
                  $omim_id, $hgvs, $omim_av, $dbsnps[$i], $cli_sig, $sl_acc,
                  $sl_ass, $sl_chr, $sl_start, $sl_stop, $type) );
          }
      }
    } else {
        say OUT join("\t", ($cv_id, $cv_acc, $title, $phenotype, $gene_id,
            $omim_id, $hgvs, $omim_av, $dbsnp, $cli_sig, $sl_acc,
            $sl_ass, $sl_chr, $sl_start, $sl_stop, $type) );
    }
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
