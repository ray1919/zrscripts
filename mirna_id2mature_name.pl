#!/usr/bin/env perl
# Date: 2013-11-11
# Author: zhao
# Purpose: convert default mirna id to it previous mature name

use 5.012;
use DBI;
use Data::Dump qw/dump/;

my $f1 = shift or die 'mirna id list';
open my $fh1, '<', $f1 or die $!;
my $dbh = DBI->connect('dbi:mysql:mirbase','mirbase','mirbase');
while(<$fh1>) {
  chomp;
  my $mirna_id = $_;
  my $mirna_pid = $mirna_id;
  if ($mirna_id =~ /(hsa-\w+-\w+)-\d+/) {
    $mirna_pid = $1;
  };
  my $sql1 = "select m.mature_name, m.previous_mature_id
  from mirna_mature m, mirna p, mirna_pre_mature r
  where p.mirna_id = '$mirna_id'
    and r.auto_mirna = p.auto_mirna
    and m.auto_mature = r.auto_mature";
  my $rv = $dbh->selectall_hashref($sql1,['previous_mature_id']);
  foreach my $k (keys $rv) {
    my @keys = split(';', $k);
    if (@keys ~~ /^$mirna_pid$/i) {
      print join("\t",$mirna_id,$$rv{$k}{'mature_name'},"\n");
    }
  }
  if (scalar keys $rv  == 0 ) { # maybe it is a previous id
    my $sql1 = "select m.mature_name, m.previous_mature_id
    from mirna_mature m, mirna p, mirna_pre_mature r
    where p.previous_mirna_id like '%$mirna_id%'
      and r.auto_mirna = p.auto_mirna
      and m.auto_mature = r.auto_mature";
    my $rv = $dbh->selectall_hashref($sql1,['previous_mature_id']);
    if (scalar keys $rv > 0) {
      foreach my $k (keys $rv) {
        my @keys = split(';', $k);
        if (@keys ~~ /^$mirna_pid$/i) {
          print join("\t",$mirna_id,$$rv{$k}{'mature_name'},"\n");
        }
      }
      next;
    }
    ### maybe it is a mature id
    my $sql2 = "select m.mature_name
    from mirna_mature m
    where m.mature_name = '$mirna_id'";
    my $rv = $dbh->selectall_hashref($sql2,['mature_name']);
    if (scalar keys $rv > 0) {
      print join("\t",$mirna_id,$mirna_id,"\n");
    }
    else { # previous id of mature id ?
      my $sql3 = "select m.mature_name, m.previous_mature_id
      from mirna_mature m
      where m.previous_mature_id like '%$mirna_id%'";
      my $rv = $dbh->selectall_hashref($sql3,['previous_mature_id']);
      foreach my $k (keys $rv) {
        my @keys = split(';', $k);
        if (@keys ~~ /^$mirna_pid$/i) {
          print join("\t",$mirna_id,$$rv{$k}{'mature_name'},"\n");
        }
      }
      if (scalar keys $rv  == 0 ) {
        say "$mirna_id has no records!";
        exit;
      }
    }
  }
}
