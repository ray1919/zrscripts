#!/usr/bin/env perl
# Author: zhao
# Date: 2013-12-03
# Purpose: get mirna seq from mirbase db

use 5.012;
use Data::Dump qw/dump/;
use File::stat;

get_mature_seq(shift);

sub get_mature_seq {
  use DBI;
  use Excel::Writer::XLSX;
  my $f1 = shift or die 'mirna id list';
  open my $fh1, '<', $f1 or die $!;
  my $dbh = DBI->connect('dbi:mysql:mirbase','mirbase','mirbase');
  my @result;
  while(<$fh1>) {
    chomp;
    next if $_ eq '';
    my @line = split("\t",$_);
    # my $mirna_acc = $line[2];
    my $mirna_id = $line[0];
    # my $mature_id = $line[1];
    my $sql1 = "select i.mirna_acc, i.mirna_id, i.previous_mirna_id,
a.mature_acc, a.mature_name, a.previous_mature_id, 
i.sequence mirna_sequence,
substring(i.sequence, p.mature_from, p.mature_to - p.mature_from + 1) mature_sequence
from mirna i, mirna_mature a, mirna_pre_mature p
where a.mature_name = '$mirna_id'
and a.auto_mature = p.auto_mature
and p.auto_mirna = i.auto_mirna";
# where (i.mirna_id = '$mirna_id' or a.mature_name = '$mirna_id')
    my $rv = $dbh->selectall_arrayref($sql1);
    if (scalar keys $rv  == 0 ) {
      dump $mirna_id;next;
      $sql1 = "select i.mirna_acc, i.mirna_id, i.previous_mirna_id,
a.mature_acc, a.mature_name, a.previous_mature_id, 
i.sequence mirna_sequence,
substring(i.sequence, p.mature_from, p.mature_to - p.mature_from + 1) mature_sequence
from mirna i, mirna_mature a, mirna_pre_mature p
where a.previous_mature_id regexp '$mirna_id;|;$mirna_id|^${mirna_id}\$'
and a.auto_mature = p.auto_mature
and p.auto_mirna = i.auto_mirna";
# where (i.previous_mirna_id like '%$mirna_id%' or a.previous_mature_id like '%$mirna_id%')
      $rv = $dbh->selectall_arrayref($sql1);
      if (scalar keys $rv  == 0 ) {
        say join(";",@line) . " has no records!";
        exit;
      }
    }
    push(@result, @$rv);
  }
  # only mature sequence
  my (@mature_seq, @array);
  @array = @{$result[0]}[3,4,5,7];
  foreach my $i ( 1 .. $#result ) {
    my @a = @{$result[$i]}[3,4,5,7];
    if ( @a ~~ @array ) {
      next;
    }
    else {
      push @mature_seq, [@array];
      @array = @a;
    }
  }
  push @mature_seq, [@array];

  my $workbook = Excel::Writer::XLSX->new( 'mirna_seq-'.stat($fh1)->mtime.'.xlsx' );
  my $format = $workbook->add_format();
  $format->set_font('Courier New');
  my $worksheet = $workbook->add_worksheet('miRNA sequence');
  $worksheet->write_row('A1', ['mirna acc', 'mirna id', 'previous mirna id',
      'mature acc', 'mature name', 'previous mature id', 'mirna sequence',
      'mature sequence'], $format);
  $worksheet->write_col('A2', \@result, $format);
  $worksheet->set_column( 0, 7, 20 );
  $worksheet = $workbook->add_worksheet('mature sequence');
  $worksheet->write_row('A1', ['mature acc', 'mature name',
      'previous mature id', 'mature sequence'], $format);
  $worksheet->write_col('A2', \@mature_seq, $format);
  $worksheet->set_column( 0, 3, 20 );
  $workbook->close();
}
