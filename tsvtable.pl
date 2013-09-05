#!/usr/bin/perl
#===========================================================================
#
#         FILE: tsvtable.pl
#
#        USAGE: ./tsvtable.pl
#
#  DESCRIPTION: desplay tsv formated file as table-like output in linux
#               terminal
#
#      OPTIONS: <file in tsv format> [line2echo] [cellwidth]
# REQUIREMENTS: Linux bash env
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Zhao Rui (赵锐), zzqr@live.cn
#      VERSION: 1.0
#      CREATED: 08/22/2011 02:44:33 PM
#     REVISION: ---
#===========================================================================

# use constant WIDTH => 12;
use Term::ReadKey;

($t_width) = GetTerminalSize( );
# file_checking
$file = shift;
if ( !defined $file || !( -e $file ) ) {
  print "File argument error!\n";
  exit;
}
my $line2echo = shift || 10; # default lines to echo
my $cellwidth = shift || 12; # default cell width 12

# file reading
open( IN, $file );
$n = 0;
$is_end = 1;
while (<IN>) {
  if ( $n == $line2echo) {
    $is_end = 0;
    last;
  }
  next if /^#/;
  chomp $_;
  s/\r//g;
  @line = split( "\t", $_ );
  for ( $i = 0 ; $i < @line ; $i++ ) {
    if ( length( $line[$i] ) > $cellwidth ) {
      $line[$i] = substr( $line[$i], 0, $cellwidth - 4 ) . '...';
    }
    if ( !defined $col_len[$i] ) {
      $col_len[$i] = length( $line[$i] );
    }
    elsif ( length( $line[$i] ) > $col_len[$i] ) {
      $col_len[$i] = length( $line[$i] );
    }
    push( @{ $table[$n] }, $line[$i] );
  }
  $n++;
}

my $row = 0;
do {
  for ( $n = 0 ; $n < @table ; $n++ ) {
    $width = 1;
    $width_cr = 1;
    print $row > 0 ? "\033[36m|\033[0m" : "\033[32m|\033[0m";
    for ( $i = 0 ; $i < @{ $table[$n] } ; $i++ ) {
      $width += $col_len[$i] + 1;
      $width_cr += $col_len[$i] + 1 if ( $width > $t_width * $row );
      if ( $t_width < $width_cr ) { # the current width exceed the terminal
        print '.' x ( $t_width + $col_len[$i] - $width_cr );
        last;
      }
      if ( $width > $t_width * $row ) {
        print $table[$n][$i], " " x ( $col_len[$i] - length( $table[$n][$i] ) ),
          "\033[36m|\033[0m";
      }
    }
    print "\n";
  }
  print "...\n" if ($is_end == 0);
  $row++;
} while($width_cr > $t_width);
