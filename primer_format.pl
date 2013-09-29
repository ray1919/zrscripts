#!/usr/bin/env perl
# Date: 2012-12-24
# Author: Zhao
# Purpose: parse data from primer tables, insert into ctnet
# Update: 2013-08-21
# Note: update primer db using text
# Update: 2013-09-22
# Note: add systhetic name to primer

use lib '/home/zhaorui/bin/lib';
use Ctnet::Schema;
use Data::Table;
use POSIX qw(strftime);
use 5.010;
my $schema = Ctnet::Schema->connect('dbi:mysql:ctnet', 'ctnet', 'ctnet', { mysql_enable_utf8 => 1 });
my $date = strftime "%Y-%m-%d", localtime;

my $file1 = shift || die "primer_format.txt not found!";
my $t1 = fromTSV($file1);

foreach my $r ( 0 .. $t1->lastRow) {
  # insert primer
  my $gene_fk;
  my $mirna_fk;
  my $type = $t1->elm($r,'type');
  my $gene_name = $t1->elm($r,'gene_name');
  my $gene_id = $t1->elm($r,'gene_id');
  my $tax_id = $t1->elm($r,'organism');
  if ($type eq 'gene') {
    if ($gene_id =~ /^\d+$/) {
      $rs = $schema->resultset('Gene')->search(
        {gene_id => $gene_id});
          #tax_id => $t1->elm($r,'organism')});
      if ($rs == 1) {
        $gene_fk = $gene_id;
        my $rs1 = $rs->first;
        $tax_id = $rs1->tax_id;
      }
    }
    elsif ($gene_name ne '') {
      $rs = $schema->resultset('Gene')->search(
        {gene_symbol => $gene_name});
      if ($rs == 1) {
        my $rs1 = $rs->first;
        $gene_fk = $rs1->gene_id;
        $tax_id = $rs1->tax_id;
      }
      else {
        #say $gene_name,"\t|",$t1->elm($r,'gene_id'),"\t|$gene_fk\t|$mirna_fk";
        my $gi= $schema->resultset('Gene')->search({
          -or => [
            synonyms => {'like', "$gs|%"},
            synonyms => {'like', "%|$gs|%"},
            synonyms => {'like', "%|$gs"},
            synonyms => {'like', "$gs"},
            ],
          type_of_gene => 'protein-coding',
          tax_id => $tax_id});
        if ($gi == 1) {
          my $gi1 = $gi->first;
          $gene_fk = $gi1->geneid;
        }
      }
    }
  }
  else {
      $rs = $schema->resultset('Mirna')->search({
          -or => [
            # 'binary mirna_id' => $gene_name,
            'mirna_id' => $gene_name,
            accession => $t1->elm($r,'primer_id'),
          ]});
      if ($rs == 1) {
        my $rs1 = $rs->first;
        $mirna_fk = $rs1->id;
        $tax_id = $rs1->tax_id;
      }
  }

  # say $gene_name,"\t|",$t1->elm($r,'gene_id'),"\t|$gene_fk\t|$mirna_fk";
  $rs = $schema->resultset('Primer')->find_or_new(
    { # gene_id => $gene_id,
      primer_id => $t1->elm($r,'primer_id'),
      # gene_symbol => $gene_name,
      tax_id => $tax_id,
      type_of_primer => $type,
      gene_fk => $gene_fk,
      mirna_fk => $mirna_fk,
      # barcode => $t1->elm($r,'barcode'),
      # comment => $t1->elm($r,'comment'),
    });
  unless ($rs->in_storage) {
    $rs->insert;
    $rs->create_date($date);
    $rs->update;
  }
  if ($t1->elm($r,'comment') ne '') {
    $rs->comment($t1->elm($r,'comment') . ';');
    $rs->update;
  }
  # if ($gene_fk ne '' && $rs->gene_fk eq '') {
  #  $rs->gene_fk($gene_fk);
  #  $rs->update;
  # }
  if (defined $mirna_fk && $rs->mirna_fk eq '') {
    $rs->mirna_fk($mirna_fk);
    $rs->update;
  }
  if ($gene_id ne '' && $rs->gene_id eq '') {
    $rs->gene_id($gene_id);
    $rs->update;
  }
  if ($gene_name ne '' && $rs->gene_symbol eq '') {
    $rs->gene_symbol($gene_name);
    $rs->update;
  }
  if ($t1->elm($r,'barcode') ne '' && $rs->barcode eq '') {
    $rs->barcode($t1->elm($r,'barcode'));
    $rs->update;
  }
  # if ($t1->elm($r,'QC') ne '' && $rs->qc eq '') {
  if ($t1->elm($r,'QC') ne '') {
    $rs->qc($t1->elm($r,'QC'));
    $rs->update;
  }
  $rs->update_date($date);
  $rs->update;
  $primerid = $rs->id;

  # insert plate & well use
  # type of primer
  $top = $type eq 'gene' ? 5 : 8;
  insert_entry('use_plate','use_well',$top,$r);

  # insert plate & well F 100
  $top = $type eq 'gene' ? 3 : 7;
  insert_entry('100um_f','POSf',$top,$r);
  # insert plate & well R 100
  $top = $type eq 'gene' ? 4 : 7;
  insert_entry('100um_r','POSr',$top,$r);

  # insert plate & well F dry
  $top = $type eq 'gene' ? 1 : 6;
  insert_entry('dryf','IDf1',$top,$r);
  insert_entry('dryf','IDf2',$top,$r);

  # insert plate & well R dry
  $top = $type eq 'gene' ? 2 : 6;
  insert_entry('dryr','IDr1',$top,$r);
  insert_entry('dryr','IDr2',$top,$r);

  bar($r, $t1->lastRow);
}
say '';

sub insert_entry{
  my $plcol = shift;
  my $wellcol = shift;
  my $st_id = shift;
  my $r = shift;
  my $pl = $t1->elm($r,$plcol);
  $pl =~ s/-F$//;
  $pl =~ s/-R$//;
  my $well = $t1->elm($r,$wellcol);

  if ($pl eq '' || $well eq '') {
    return 0;
  }
  my $rs = $schema->resultset('Plate')->find_or_new(
    { name => $pl});
  unless ($rs->in_storage) {
    $rs->insert;
    # say "Insert new plate: $pl";
  }
  $plateid = $rs->id;

  $rs = $schema->resultset('Position')->find_or_new(
    { plate_id => $plateid,
      well => $well,
      primer_id => $primerid,
      store_type_id => $st_id,
    });
  unless ($rs->in_storage) {
    $rs->insert;
    $rs->store_date($date);
    given ($st_id) {
      when ([2,4]) {
        $rs->synthetic_name($t1->elm($r,'sn3p'));
      }
      when ([1,3,6,7]) {
        $rs->synthetic_name($t1->elm($r,'sn5p'));
      }
    }
    $rs->update;
  }
}

sub fromTSV {
    my $file = $_[0] || die "File not declared!";
    ### read: $file
    my $t =
      Data::Table::fromTSV( $file, 1, undef,
        { OS => Data::Table::fromFileGuessOS($file),
          skip_pattern => '^\s*#' } );
    $t->rotate if ( $t->type == 1 );
    return $t;
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
