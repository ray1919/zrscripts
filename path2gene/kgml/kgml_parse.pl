#!/usr/bin/env perl
# Author: Zhao
# Date: 2016-05-10
# Purpose: 解析KGML文件，选择节点基因，优化挑选88个基因

use 5.014;
use XML::Dataset;
use Data::Printer;
use LWP::Simple;

my @gene_rank = kgmap_gene_rank('hsa04020');

sub kgmap_gene_rank {
  my $map_id = shift;
  my $xml_data = kgml_download4read($map_id);
  
  my $profile = qq(
    pathway
      entry
        id     = external_dataset:entry
        name   = external_dataset:entry,name:kid
        type   = external_dataset:entry
        graphics
          name = dataset:entry
          __EXTERNAL_VALUE__ = entry:id:entry entry:kid:entry entry:type:entry
        component
          id   = dataset:group,name:component
          __EXTERNAL_VALUE__ = entry:id:group
      relation
        entry1 = external_dataset:relation dataset:cpd_relation
        entry2 = external_dataset:relation dataset:cpd_relation
        type   = external_dataset:relation dataset:cpd_relation
        subtype
          name = dataset:relation
          value= dataset:relation
          __EXTERNAL_VALUE__ = relation:entry1:relation relation:entry2:relation relation:type:relation
  );
  
  my $kgml_data = parse_using_profile( $xml_data, $profile ); 
  
  my %all_gene_ids;
  my %first_gene_ids; # genes in first position of each node
  my %else_gene_ids;
  my %entry2gene; # mapping entry to genes
  foreach my $i ( @{$$kgml_data{'entry'}} ) {
    if ( $$i{'type'} eq 'gene' ) {
      my @gene_ids = split ' ', $$i{'kid'};
      map {s/hsa://} @gene_ids;
      foreach my $g ( @gene_ids ) {
        $all_gene_ids{$g}++;
        $entry2gene{$$i{'id'}}{$g}=0;
      }
      # map {$all_gene_ids{$_}++} @gene_ids;
      $first_gene_ids{$gene_ids[0]}++;
      shift @gene_ids;
      map {$else_gene_ids{$_}++} @gene_ids;
      # my @gene_names = split ', ', $$i{'name'};
    }
  }
  # add group mapping relation
  foreach my $i ( @{$$kgml_data{'group'}} ) {
    foreach my $j ( keys %{$entry2gene{$$i{'component'}}} ) {
      $entry2gene{$$i{'id'}}{$j} = 0;
    }
  }
  
  my %relation_names;
  foreach my $i ( @{$$kgml_data{'relation'}} ) {
    $relation_names{$$i{'name'}}++;
  }
  my %w_matrix; # relation type weight matrix
  foreach my $i (keys %relation_names) {
    $w_matrix{$i} = 1/log($relation_names{$i} + 1);
  }
  
  foreach my $i ( @{$$kgml_data{'relation'}} ) {
    my $weight = $w_matrix{$$i{'name'}};
    foreach my $j ( $$i{'entry1'}, $$i{'entry2'} ) {
      foreach my $k (keys %{$entry2gene{$j}} ) {
        $entry2gene{$j}{$k} += $weight;
      }
    }
  }
  foreach my $i ( @{$$kgml_data{'cpd_relation'}} ) {
    next if $$i{'type'} ne "PCrel"; # protein - compound relation
    my $weight = 0.2;
    foreach my $j ( $$i{'entry1'}, $$i{'entry2'} ) {
      foreach my $k (keys %{$entry2gene{$j}} ) {
        $entry2gene{$j}{$k} += $weight;
      }
    }
  }
  # sum score for each gene
  my %gene_score;
  foreach my $i (keys %entry2gene) {
    foreach my $j (keys %{$entry2gene{$i}}) {
      $gene_score{$j} += $entry2gene{$i}{$j};
    }
  }

  # ranking gene from high to low
  my @gene_rank = sort {$gene_score{$b} <=> $gene_score{$a}} keys %gene_score;
  return @gene_rank;
}

sub kgml_download4read {
  my $id = shift || exit(1);
  my $xml_data;
  my $file = "kgml/$id.xml";
  if (-f $file) {
    open my $fh1, '<', $file;
    my @file = <$fh1>;
    $xml_data = join '', @file;
    close $fh1;
  }
  else {
    my $link = "http://rest.kegg.jp/get/$id/kgml";
    $xml_data = get($link);
    open my $fh2, '>', $file;
    print $fh2 $xml_data;
    close $fh2;
  }
  return $xml_data;
}

