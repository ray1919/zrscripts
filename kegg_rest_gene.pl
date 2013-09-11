#!/usr/bin/env perl
# Author: Zhao
# Date: 2013-09-03
# Purpose: 用kegg api 获取每个基因的信息

use 5.010;
use LWP::Simple;
use Smart::Comments;
use Data::Dump qw/dump/;
use Excel::Writer::XLSX;
use POSIX qw(ceil);
my $each = 10;

my $file = shift || die "Input a file name";
my $og = 'hsa';
$dir = '.dl';
mkdir($dir) unless -d $dir;
kg_path_from_gi($file);
exit;
kg_gene_from_path($file);
kg_name_from_gi($file);

sub kg_gene_from_path {
  my $file = shift || die "Input a kegg pathway id file name";
  exit unless -f $file;
  open $fh, '<', $file || die $!;
  
  my @path = <$fh>;
  map {chomp;} @path;
  
  my (%pathmap, %genes);
  $i = 1;
  my $n = ceil(scalar @path / $each);
  # retrieve 10 records a time (max limit)
  while ( my @g10 = splice(@path, 0, $each) ) {
    $link = join('+',@g10);
    $url = "http://rest.kegg.jp/get/$link";
    $of = crypt($link,$link);
    $of =~ s/\W//g;
    unless (-f "$dir/$of") {system("wget $url -O $dir/$of -q")};

    %path = read_kg_entry("$dir/$of");
    map {$genes{$_} = $path{$_}{'GENE'}} keys %path;
    map {$pathmap{$_} = $path{$_}{'PATHWAY_MAP'}[0]} keys %path;
    bar($i++,$n);
  }
  my $workbook = Excel::Writer::XLSX->new( 'pathway_genes.xlsx' );
  my $color = 27;
    $format = $workbook->add_format();
    $format->set_font('Courier New');
    $format->set_align("left");
    $format->set_size(10);
  foreach $p (keys %genes) {
    $worksheet = $workbook->add_worksheet(sheet_name($pathmap{$p}));
    $worksheet->set_tab_color( $color++ );
    $worksheet->write_row('A1', ['Gene ID', 'Gene'], $format);
    $worksheet->write_col('A2', $genes{$p}, $format);
  }
  $workbook->close();
  say '';
}

sub kg_name_from_gi {
  my $file = shift || die "Input a gi file name";
  exit unless -f $file;
  open $fh, '<', $file || die $!;
  open $ofh, '>', $file.'.name' || die $!;
  
  my @gl = <$fh>;
  map {chomp} @gl;
  my $i = 1;
  map {$rank{$_}=$i++} @gl;
  @gl = map {$og .':'. $_} @gl;
  
  $i = 1;
  my $n = ceil(scalar @gl / $each);
  bar(0,$n);
  # retrieve 10 records a time (max limit)
  while ( my @g10 = splice(@gl, 0, $each) ) {
    $link = join('+',@g10);
    $url = "http://rest.kegg.jp/get/$link";
    $of = crypt($link,$link);
    $of =~ s/\W//g;
    unless (-f "$dir/$of") {system("wget $url -O $dir/$of -q")};
    
    my %genes = read_kg_entry("$dir/$of");
    foreach my $g (sort {$rank{$a} <=> $rank{$b}} keys %genes) {
      say $ofh join("\t",$g,$genes{$g}{'NAME'}[0],$genes{$g}{'DEFINITION'}[0]);
    }
    bar($i++,$n);
  }
  say '';
  
}

sub kg_path_from_gi {
  my $file = shift || die "Input a gi file name";
  exit unless -f $file;
  open $fh, '<', $file || die $!;
  open $f2, '>', $file.'.path' || die $!;
  
  my @gl = ();
  while ( <$fh> ) {
    chomp;
    push(@gl, "$og:$_");
  }
  
  $i = 1;
  my $n = ceil(scalar @gl / $each);
  bar(0,$n);
  # retrieve 10 records a time (max limit)
  while ( my @g10 = splice(@gl, 0, $each) ) {
    $link = join('+',@g10);
    $url = "http://rest.kegg.jp/get/$link";
    $of = crypt($link,$link);
    $of =~ s/\W//g;
    unless (-f "$dir/$of") {system("wget $url -O $dir/$of -q")};

    my %genes = read_kg_entry("$dir/$of");
    
    my (%pathways,%p_genes);
    foreach my $gi (keys %genes) {
      say $f2 join("\t",$genes{$gi}{'NAME'}[0], $gi);
      say $f2 join("\n",@{$genes{$gi}{'PATHWAY'}}) if defined $genes{$gi}{'PATHWAY'};
      say $f2 '';
      map {$pathways{$_}++;push(@{$p_genes{$_}},$genes{$gi}{'NAME'}[0]);} @{$genes{$gi}{'PATHWAY'}};
    }
    foreach my $k (sort {$pathways{$b} <=> $pathways{$a}} keys %pathways) {
      say $f2 "$k\t$pathways{$k}\t", join(', ',@{$p_genes{$k}});
    }
    bar($i++,$n);
  }
  say '';
}

sub read_kg_entry {
  my $file = shift;
  open $kg, '<', $file || die $!;
  my @entry = <$kg>;
  my %entry;
    my ($gi,$key,@value);
  foreach my $c ( @entry ) {
    if ($c =~ /^([A-Z_]+)\s+(.*)/) {
      if ($1 eq 'ENTRY') {
        $2 =~ /(\S+)/;
        $gi = $1;
        @value = ();
        $key = '';
      }
      else {
        $key = $1;
        $value[0] = $2;
        $entry{$gi}{$key} = [@value];
      }
    }
    elsif ($c =~ /^\/\/\//) {
      my @names = split(', ', $entry{$gi}{'NAME'}[0]);
      map {$_ = [split('  ',$_)] } @{$entry{$gi}{'GENE'}};
      # dump @{$entry{$gi}{'GENE'}};
      # exit;
      $entry{$gi}{'NAME'} = [@names];
      # dump %entry;
    }
    elsif ($key =~ /SEQ/) {
      next;
    }
    elsif ($c =~ /\s+(.*)/) {
      push(@{$entry{$gi}{$key}}, $1);
    }
    else {
      die $gi;
    }
  }
  return %entry;
}

sub sheet_name {
  my $name = shift;
  my $suffix = shift || '';
  if (length($name) + length($suffix) > 31) {
    $name = substr($name,0,31-length($suffix));
  }
  return $name.$suffix;
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
