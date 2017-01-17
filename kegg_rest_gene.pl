#!/usr/bin/env perl
# Author: Zhao
# Date: 2013-09-03
# Purpose: 用kegg api 获取每个基因的信息
# Update: 2016-05-10
# 从KEGG PATHWAY中挑选88个基因作为芯片产品

use 5.012;
use LWP::Simple;
use Data::Printer;
use Smart::Comments;
use Data::Dump qw/dump/;
use Excel::Writer::XLSX;
use POSIX qw(ceil);
use DBI;
use KGML;
my $each = 5;

my $file = shift || die "Input a file name";
my $og = shift || 'hsa';
my $dir = '.dl';
mkdir($dir) unless -d $dir;
kg_gene_from_path($file);
exit;
kg_defi_from_path($file); # new
kg_88genes_from_path($file); # new
kg_path_from_gi($file);
kg_name_from_gi($file);

sub kg_defi_from_path {
  my $file = shift || die "Input a kegg pathway id file name";
  exit unless -f $file;
  open my $fh, '<', $file || die $!;
  
  my (@path, $pathId);
  while (<$fh>) {
    chomp;
    $pathId = $_;
    push @path, $pathId;
  }

  my (%pathmap, %genes, %path, %desc);

  my $i = 1;
  my $n = ceil(scalar @path / $each);
  # retrieve 10 records a time (max limit)
  while ( my @g10 = splice(@path, 0, $each) ) {
    my $link = join('+',@g10);
    my $url = "http://rest.kegg.jp/get/$link";
    my $of = crypt($link,$link);
    $of =~ s/\W//g;
    unless (-f "$dir/$of") {system("wget $url -O $dir/$of -q")};

    %path = read_kg_entry("$dir/$of");
    map {$genes{$_} = $path{$_}{'GENE'}} keys %path;
    map {$pathmap{$_} = $path{$_}{'PATHWAY_MAP'}[0]} keys %path;

    foreach my $p ( keys %path ) {
      $desc{$p} = $path{$p}{"DESCRIPTION"}->[0];
      say join "\t", $p,$pathmap{$p}, $desc{$p};
    }
  }
}

sub kg_88genes_from_path {
  my $file = shift || die "Input a kegg pathway id file name";
  exit unless -f $file;
  open my $fh, '<', $file || die $!;
  
  my (@path,$class,$egName, $cnName, $pathId, %path_name, @name_list);
  while (<$fh>) {
    chomp;
    my @cells = split "\t", $_;
    if ($cells[0] ne '') {
      $class = $cells[0];
    }
    ($egName, $cnName, $pathId) = @cells[1..3];
    push @path, "$og$pathId"; #, $class, $egName, $cnName];
    $path_name{"$og$pathId"}{"class"} = $class;
    $path_name{"$og$pathId"}{"egName"} = $egName;
    $path_name{"$og$pathId"}{"cnName"} = $cnName;
    push @name_list, [$egName, $cnName, $class, "$og$pathId"];
  }
  
  my (%pathmap, %genes, %path, @desc);

  open my $fh_ref, '>', "array_reference.txt";
  my $i = 1;
  my $n = ceil(scalar @path / $each);
  # retrieve 10 records a time (max limit)
  while ( my @g10 = splice(@path, 0, $each) ) {
    my $link = join('+',@g10);
    my $url = "http://rest.kegg.jp/get/$link";
    my $of = crypt($link,$link);
    $of =~ s/\W//g;
    unless (-f "$dir/$of") {system("wget $url -O $dir/$of -q")};

    %path = read_kg_entry("$dir/$of");
    map {$genes{$_} = $path{$_}{'GENE'}} keys %path;
    map {$pathmap{$_} = $path{$_}{'PATHWAY_MAP'}[0]} keys %path;

    # Dump reference
    foreach my $p (keys %path) {
      foreach my $l ( @{$path{$p}{'REFERENCE'}} ) {
        if ($l =~ /PMID:(\d+)/) {
          say $fh_ref "$p\t$1";
        }
      }
    }

    for my $p ( keys %path ) {
      push @desc, [ $p, $path{$p}{"DESCRIPTION"}];
    }
    # bar($i++,$n);
  }
  close $fh_ref;

  # 每个通路挑选88个基因。原则是优先挑选转录因子里的基因，然后按gene id从小到大排序，取每个
  # 连续id的第一个基因，若不满足88个，则再挑选第二个基因。
  open my $fh2, '<', "transfac.gi.txt";
  my @tf_gis = <$fh2>;
  map {chomp} @tf_gis;
  my %tf_gis = (@tf_gis, reverse @tf_gis);

  open my $fh3, '<', "hk.txt";
  my @hk_gis = <$fh3>;
  map {chomp} @hk_gis;

  my %array;
  foreach my $p (keys %genes) { ### Selecting [====%       ] done
    my (@all_gis, @selected);
    @all_gis = map { $_->[0] } @{$genes{$p}}; # all gene in pathway
    @all_gis = protein_gis([@all_gis]); # filter non-protein-coding genes
    @all_gis = removeHK([@all_gis], [@hk_gis]); # filter house-keeping genes

    if ( scalar @all_gis < 88 ) {
      say "$p LESS THAN 88 GENES.";
      next;
    }

    for my $i (0 .. $#all_gis) {
      if ( defined $tf_gis{$all_gis[$i]} ) {
        push @selected, splice @all_gis, $i, 1;
      }
    }

    # 算法1: 挑取去不连续gene id作为候选基因
#   while (scalar @selected < 88 ) {
#     my ($a, $b) = candidate([@all_gis]);
#     my @candidate = @$a;
#     @all_gis = @$b;
#     if (scalar @candidate + scalar @selected >= 88 ) {
#       push @selected, @candidate[ 0 .. (86 - $#selected) ];
#     }
#     else {
#       push @selected, @candidate;
#     }
#   }

    # 算法2：根据PATHWAY MAP网络节点连接权重打分排序挑选
    # 优先选择历遍所有节点，其次按分数排序选择
    my ($first_gene_ids, $gene_rank) = KGML::kgmap_gene_rank($p);
    my @new_sel = priority_genes($gene_rank,88-scalar @selected,
      [protein_gis($first_gene_ids)], [@hk_gis, @selected]);
    @selected = (@selected, @new_sel);
    if (scalar @selected < 88 ) {
      @new_sel = priority_genes($gene_rank,88-scalar @selected,
        [protein_gis($gene_rank)], [@hk_gis, @selected]);
      @selected = (@selected, @new_sel);
    }
    if (scalar @selected < 88 ) {
      warn("$p gene seleted not enough.");
    }

    $array{$p} = [ @selected ];
  }
  my @array_list;
  foreach my $p ( keys %array ) {
    my $rv = query_geneinfo($array{$p}, $path_name{$p}{"egName"}) ;
    push @array_list, @$rv;
  }

  my $workbook = Excel::Writer::XLSX->new( 'pathway_genes.xlsx' );
  my $color = 27;
  my $format = $workbook->add_format();
  $format->set_font('Courier New');
  $format->set_align("left");
  $format->set_size(10);
  my $worksheet = $workbook->add_worksheet('PCR ARRAY');
  $worksheet->write_row('A1', ['Name', 'Name2', 'class', 'KEGG ID'], $format);
  $worksheet->write_col('A2', \@name_list, $format);
  my $worksheet = $workbook->add_worksheet('PATH DESC');
  $worksheet->write_row('A1', ['KEGG ID', 'Description'], $format);
  $worksheet->write_col('A2', \@desc, $format);
  $worksheet = $workbook->add_worksheet('GENE LIST');
  $worksheet->write_row('A1', ['Symbol', 'GeneID', 'description', 'Synonyms', 'tax_id', 'type_of_gene', 'cnName'], $format);
  $worksheet->write_col('A2', \@array_list, $format);

  $workbook->close();
  say '';
}

sub priority_genes {
  my ($gene_rank, $num, $IncludeSet, $ExcludeSet) = @_;
  # ordered array, number, array
  # purpose: select $num gene from gene_rank within includeset and not in excludeset
  my @selected;
  foreach my $i ( @$gene_rank ) {
    if ( $i ~~ @$ExcludeSet || !($i ~~ @$IncludeSet) ){
      next;
    }
    push @selected, $i;
    last if scalar @selected == $num;
  }
  return @selected;
}

sub removeHK {
  my ($a, $b) = @_;
  my %a = (@$a, reverse @$a);
  my %b = (@$b, reverse @$b);
  foreach my $k ( keys %a ) {
    if (exists $b{$k} ) {
      delete $a{$k};
    }
  }
  return keys %a;
}

sub protein_gis {
  my $gi = shift;
  my $dbh = DBI->connect('dbi:mysql:ncbi','ncbi','ncbi');
  my $gistring = join ',', @$gi;
  my $sql = "SELECT GeneID FROM gene_info
  WHERE GeneID in ($gistring) AND type_of_gene = 'protein-coding'";
  my $rv = $dbh->selectall_hashref($sql, 'GeneID');
  $dbh->disconnect;
  return keys %$rv;
}

sub query_geneinfo {
  my $gi = shift;
  my $p = shift;
  my $dbh = DBI->connect('dbi:mysql:ncbi','ncbi','ncbi');
  my $gistring = join ',', @$gi;
  my $sql = "SELECT Symbol, GeneID, description, Synonyms, tax_id, type_of_gene, '$p' as c
  FROM gene_info WHERE GeneID in ($gistring)";
  my $rv = $dbh->selectall_arrayref($sql);
  $dbh->disconnect;
  return $rv;
}

sub candidate {
  my $all = shift;
  my @can = sort {$a <=> $b} @$all;
  my @left;

  for my $i ( reverse 1 .. $#can ) {
    if ( $can[$i] == $can[$i - 1] + 1 ) {
      push @left, splice @can, $i, 1;
    }
  }
  return [@can], [@left];
}

sub kg_gene_from_path {
  my $file = shift || die "Input a kegg pathway id file name";
  exit unless -f $file;
  open my $fh, '<', $file || die $!;
  
  my @path = <$fh>;
  map {chomp;} @path;
  
  my (%pathmap, %genes);
  my $i = 1;
  my $n = ceil(scalar @path / $each);
  # retrieve 10 records a time (max limit)
  while ( my @g10 = splice(@path, 0, $each) ) {
    my $link = join('+',@g10);
    my $url = "http://rest.kegg.jp/get/$link";
    my $of = crypt($link,$link);
    $of =~ s/\W//g;
    unless (-f "$dir/$of") {system("wget $url -O $dir/$of -q")};

    my %path = read_kg_entry("$dir/$of");
    map {$genes{$_} = $path{$_}{'GENE'}} keys %path;
    map {$pathmap{$_} = $path{$_}{'PATHWAY_MAP'}[0]} keys %path;
    bar($i++,$n);
  }
  my $workbook = Excel::Writer::XLSX->new( 'pathway_genes.xlsx' );
  my $color = 27;
    my $format = $workbook->add_format();
    $format->set_font('Courier New');
    $format->set_align("left");
    $format->set_size(10);
  foreach my $p (keys %genes) {
    my $worksheet = $workbook->add_worksheet(sheet_name($pathmap{$p}));
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
  open my $fh, '<', $file || die $!;
  open my $ofh, '>', $file.'.name' || die $!;
  
  my @gl = <$fh>;
  map {chomp} @gl;
  my $i = 1;
  my %rank;
  map {$rank{$_}=$i++} @gl;
  @gl = map {$og .':'. $_} @gl;
  
  my $i = 1;
  my $n = ceil(scalar @gl / $each);
  bar(0,$n);
  # retrieve 10 records a time (max limit)
  while ( my @g10 = splice(@gl, 0, $each) ) {
    my $link = join('+',@g10);
    my $url = "http://rest.kegg.jp/get/$link";
    my $of = crypt($link,$link);
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
  open my $fh, '<', $file || die $!;
  open my $f2, '>', $file.'.path' || die $!;
  
  my @gl = ();
  while ( <$fh> ) {
    chomp;
    push(@gl, "$og:$_");
  }
  
  my $i = 1;
  my $n = ceil(scalar @gl / $each);
  bar(0,$n);
  my %genes_all;
  # retrieve 10 records a time (max limit)
  while ( my @g10 = splice(@gl, 0, $each) ) {
    my $link = join('+',@g10);
    my $url = "http://rest.kegg.jp/get/$link";
    my $of = crypt($link,$link);
    $of =~ s/\W//g;
    unless (-f "$dir/$of") {system("wget $url -O $dir/$of -q")};

    my %genes = read_kg_entry("$dir/$of");
    %genes_all = (%genes_all, %genes);
    bar($i++,$n);
  }
    my (%pathways,%p_genes, %p_genes_all);
    foreach my $gi (keys %genes_all) {
      say $f2 join("\t",$genes_all{$gi}{'NAME'}[0], $gi);
      say $f2 join("\n",@{$genes_all{$gi}{'PATHWAY'}}) if defined $genes_all{$gi}{'PATHWAY'};
      say $f2 '';
      map {$pathways{$_}++;push(@{$p_genes_all{$_}},$genes_all{$gi}{'NAME'}[0]);} @{$genes_all{$gi}{'PATHWAY'}};
    }
    foreach my $k (sort {$pathways{$b} <=> $pathways{$a}} keys %pathways) {
      say $f2 "$k\t$pathways{$k}\t", join(', ',@{$p_genes{$k}});
    }
  say '';
}

sub read_kg_entry {
  my $file = shift;
  open my $kg, '<', $file || die $!;
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
        if (exists $entry{$gi}{$key}) {
          push(@{$entry{$gi}{$key}}, $2);
        } else {
          $entry{$gi}{$key} = [@value];
        }
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
  $name =~ s/[|]|\:|\*|\?|\/|\\/-/g;
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
