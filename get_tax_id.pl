#!/usr/bin/env perl
# Date: 2014-09-02
# Author: Zhao
# Purpose: locate tax id from scienctific species name

use 5.012;
use Data::Dump qw/dump/;
use DBI;
use autodie;

my $dbi = DBI->connect('dbi:mysql:ncbi','ncbi','ncbi');
my $file = shift || die 'no file';
open my $fh1, '<', $file;
open my $fh2, '>', "$file.taxid";

while (<$fh1>) {
  chomp;
  my $name = $_;
  $name =~ s/'/\\'/g;
  my $sql = "SELECT `tax_id` FROM `taxdump_names` WHERE `name_txt` = '$name'";
  my $rv = $dbi->selectrow_array($sql);
  unless (defined $rv) {
    say "$name not found" unless defined $rv;
  }
  say $fh2 join "\t",$name,$rv;
}

