#!/usr/bin/env perl
# Date: 2012-12-24
# Author: Zhao
# Purpose: parse data from primer tables, insert into ctnet
# Update: 2013-07-11
# Note: update primer db using text
# Bug: create date

use lib 'lib';
use Ctnet::Schema;
use Data::Table;
use POSIX qw(strftime);
use 5.010;
my $schema = Ctnet::Schema->connect('dbi:mysql:ctnet', 'ctnet', 'ctnet', { mysql_enable_utf8 => 1 });
my $date = strftime "%Y-%m-%d", localtime;

my $file1 = shift || die "file not found!";
my $t1 = fromTSV($file1);

foreach my $r ( 0 .. $t1->lastRow) {
  $rs = $schema->resultset('Primer')->search(
    {
      primer_id => $t1->elm($r,'primer_id'),
    });
  unless ($rs == 1) {
    say 'error1 ', $t1->elm($r,'primer_id');
    next;
  }
  $os = $schema->resultset('Position')->search(
    {
      primer_id => $rs->first->id,
      store_type_id => { '<' => 5 },
    });
  unless ($os > 0 ) {
    say 'error2 ', $t1->elm($r,'primer_id');
    next;
  }
  while ( my $o = $os->next ) {
    if ( $o->store_type_id % 2 == 1 ) {
      $o->synthetic_name($o->synthetic_name . $t1->elm($r,'fn') . ';');
    }
    else {
      $o->synthetic_name($o->synthetic_name . $t1->elm($r,'rn') . ';');
    }
    $o->update;
  }

  bar($r, $t1->lastRow);
}
say '';

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
