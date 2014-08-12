#!/usr/bin/env perl
# Author: Zhao
# Date: 2014-07-17
# Purpose: 寻找基因组序列中唯一的一致序列

use 5.014;
use Data::Dump qw/dump/;
use Smart::Comments;
use autodie qw(:all);
use LWP::Simple;
use utf8::all;
use Cwd;
use DBI;
use Term::Choose qw( choose );

my $MIN_LEN = 20;
my $NT_FILE = "../../nt";

# run once
# make_gi_fosn_db('nt.idx');

### fetch genome sequence from ncbi, internet connection required
# run once
# prepare_genome("tax_id_list.txt");

mummer_genomes("tax_id_list.txt");
exit;

### find commen consensus seuqences

my @cms = common_mummer_sequence('query.mums'); # time elapsed: 4s

### fetch fasta from refseq
fetch_fasta("NC_004116.fa",@cms);

### construct non-target nt db
tax2genus_gi(1311);
# etch_gi_fasta(1311, 'nt.idx'); # time elapsed: 11 mins
fetch_gi_fasta_db(1311, 'nt.idx'); # time elapsed: 2 mins

### mummer against non-target db
mummer_and_parse(1311); # time 48s
exit;

# blast-based compare
# consensus_blast_parse(1311,"subseq.m8");

sub mummer_genomes {
# Representative sequence NC_004116.fa
# grep -P "complete genome$" 1311_complete_genome.fasta |cut -f1 -d ' ' > 1311_complete_genome.fosn
# delete NC_004116 from fosn
# fastaindex 1311_complete_genome.fasta 1311_complete_genome.idx
# fastafetch -f 1311_complete_genome.fasta -i 1311_complete_genome.idx -q 1311_complete_genome.fosn -F T >  query.fa
# use mummer to locate unique consensus seuqence between each chromes seuqnes
# time mummer -mum -b -c NC_004116.fa query.fa > query.mums
  my $tax_file = shift;
  my $cwd = getcwd();
  open my $fh1, '<', $tax_file;
  while (<$fh1>) {
    chomp;
    ### Tax: $_
    my @line = split "\t", $_;
    my $tax_id = $line[0];
    chdir $cwd;
    mkdir $tax_id unless -d $tax_id;
    chdir "$cwd/$tax_id";
    next if -f "$tax_id.consensus.nb.fa";
    next if -f "EMPTY_GENOME";
    next if -f "EMPTY_RESULT";
    unless ( -f "$tax_id.query.mums" ) {
      my $genome_file = "../tmp/$tax_id.genome.fa";
      # my @fa_names = split "\n", `grep "^>" $genome_file`;
      my @fa_lens = split "\n", `fastalength $genome_file|sort -n`;
      my @answer = choose([@fa_lens], {index => 1, layout => 1});
      system("grep '^>' $genome_file|tail");
      map {splice @fa_lens, $_, 1} reverse @answer;
      my (@genome_len,@genome_idx);
      foreach my $s ( @fa_lens ) {
        my @fd = split /\s+/, $s;
        push @genome_len, $fd[0];
        push @genome_idx, $fd[1];
      }
      my $max_len = max(@genome_len);
      my $min_len = min(@genome_len);
      if ($#genome_len < 1) {
        ### no genome sequence find
        system("touch EMPTY_GENOME");
        next;
      }
      say "Genome sequences count: ",scalar @genome_len;
      say "Max length: $max_len";
      say "Min length: $min_len";
      say "Is this right?";
      my $answer = choose(['Yes','No','Next']);
      return if $answer eq 'No';
      next if $answer eq 'Next';
  
      ### take first & shortest sequence as refseq
      my $ref_fosn = shift @genome_idx;
      system("fastaindex $genome_file $tax_id.idx") unless -f "$tax_id.idx";
      open my $fh1, '>', "$tax_id.query.fosn";
      map {say $fh1 $_} @genome_idx;
      close $fh1;
      ### ref genome fa
      system("fastafetch -f $genome_file -i $tax_id.idx -q '$ref_fosn' > $tax_id.ref.fa");
      ### query genome fa
      system("fastafetch -f $genome_file -i $tax_id.idx -F T -q $tax_id.query.fosn > $tax_id.query.fa");
      ### mummer to find uniq consensus seqs
      system("mummer -mum -b -c $tax_id.ref.fa $tax_id.query.fa > $tax_id.query.mums") unless -f "$tax_id.query.mums";
    }
    ### find common sequence region
    my @cms = common_mummer_sequence($tax_id);
    if ($#cms == -1) {
      ### no common mummer sequence find
      system("touch EMPTY_RESULT");
      next;
    }
    say scalar @cms, " mummer sequences find";
    ### fetch fasta from refseq
    fetch_common_seq($tax_id,[@cms]);
    # fetch_fasta($tax_id,@cms);

    ### construct non-target nt db
    tax2genus_gi($tax_id);
    ### fetch non-target fasta
    fetch_gi_fasta_db($tax_id, '../../nt.idx'); # time elapsed: 2 mins

    ### mummer against non-target db
    mummer_and_parse($tax_id); # time 48s

    ### exract coords and junction sequence
    consensus_coords($tax_id);

  }
}

sub consensus_coords {
  my $tax_id = shift;
  return if -f "$tax_id.consensus.nb.fa";
  return if not -f "$tax_id.consensus.fa";
  my @line = split "\n", `grep "^>" $tax_id.consensus.fa`;
  my (%coords, @coords_sorted);
  open my $fh1, '>', "$tax_id.consensus.coords";
  foreach my $l ( @line ) {
    $l =~ />\S+:subseq\((\d+),(\d+)\)/;
    say $fh1 join "\t", $1, $2;
    $coords{$1} = $2;
  }
  close $fh1;
  my $i= 0;
  foreach my $c (sort {$a <=> $b} keys %coords) {
    $coords_sorted[$i++] = [$c, $coords{$c}];
  }
  my @pos;
  foreach my $i ( 1 .. $#coords_sorted ) {
    my $inter_len = $coords_sorted[$i][0] - ($coords_sorted[$i-1][0] + $coords_sorted[$i-1][1] - 1) - 1;
    if ($inter_len > 20 && $inter_len < 100) {
      my $len = $coords_sorted[$i][0] + $coords_sorted[$i][1] - 1 - $coords_sorted[$i-1][0] + 1;
      # system("fastasubseq -f $tax_id.ref.fa -s $coords_sorted[$i-1][0] -l $len >> $tax_id.consensus.nb.fa");
      push @pos, [$coords_sorted[$i-1][0], $len];
    }
  }
  fasta_subseq("$tax_id.ref.fa",[@pos],"$tax_id.consensus.nb.fa");
  return;
}

sub prepare_genome {
  ### Query whole genomic sequences in NCBI with tax id
  my $tax_file = shift;
  open my $fh1, '<', $tax_file;
  while (<$fh1>) {
    my @line = split "\t", $_;
    my $tax_id = $line[0];
    my $query = "txid${tax_id}[Organism:exp] AND \"complete genome\"[Title]";
    my $genome_file = "$tax_id.genome.fa";
    next if -f $genome_file;
    ### SP: $tax_id
    query_genbank($query, $genome_file);
    sleep 2;
  }
}

sub query_genbank {
  my ($query,$save) = @_;
  
  #assemble the esearch URL
  my $base = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/';
  my $url = $base . "esearch.fcgi?db=nuccore&term=$query&usehistory=y";
  
  #post the esearch URL
  my $output = get($url);
  
  #parse WebEnv and QueryKey
  my $web = $1 if ($output =~ /<WebEnv>(\S+)<\/WebEnv>/);
  my $key = $1 if ($output =~ /<QueryKey>(\d+)<\/QueryKey>/);
  my $count = $1 if ($output =~ /<Count>(\d+)<\/Count>/);
  
  #assemble the efetch URL
  $url = $base . "efetch.fcgi?db=nuccore&query_key=$key&WebEnv=$web";
  $url .= "&rettype=fasta&retmode=text";
  
  #post the efetch URL
  # my $fasta = get($url);

  # save fasta to file
  open my $fh1, '>', $save;
  # say $fh1 $fasta;

  # retrieve data in batches of 50
  my $retmax = 50;
  for (my $retstart = 0; $retstart < $count; $retstart += $retmax) {
        my $efetch_url = $base ."efetch.fcgi?db=nuccore&WebEnv=$web";
        $efetch_url .= "&query_key=$key&retstart=$retstart";
        $efetch_url .= "&retmax=$retmax&rettype=fasta&retmode=text";
        my $efetch_out = get($efetch_url);
        say $fh1 $efetch_out;
  }
  close $fh1;

  return 1;
}

sub consensus_blast_parse {
  my ($tax_id,$blast_file) = @_;
  open my $fh1, '<', $blast_file;
  # make a list of tax id in same specie
  my $dbh = DBI->connect('dbi:mysql:ncbi','ncbi','ncbi');
  my $sql1 = "select tax_id from taxdump_nodes where parent_tax_id = $tax_id";
  my $rv1 = $dbh->selectcol_arrayref($sql1);
  my @specie_tax_id;
  foreach my $i ( @$rv1 ) { ### Species [===|    ] % done
    # sub sub species tax ids
    my $sql2 = "select tax_id from taxdump_nodes where parent_tax_id = $i";
    my $rv2 = $dbh->selectcol_arrayref($sql2);
    push @specie_tax_id, @$rv2;
  }
  push @specie_tax_id, @$rv1;
  push @specie_tax_id, $tax_id;

  my %consensus_id;
  my $n = 0;
  while (<$fh1>) { # Parse blast output [===|    ] % done
    my @fd = split "\t", $_;
    my ($qid,$sid,$identity) = @fd[0..2];
    # bar($n++, 260223);
    if (!defined $consensus_id{$qid}) {
      $consensus_id{$qid} = 1;
    }
    elsif ($consensus_id{$qid} == 0) {
      next;
    }
    my $stax_id = gb_id2tax_id($sid);
    if (! ( $stax_id ~~ @specie_tax_id) ) {
      $consensus_id{$qid} = 0;
    }
  }
  open my $fh2, '>', "$tax_id.consensus.blast.fosn";
  foreach my $k ( keys %consensus_id )  {
    say $fh2 $k if $consensus_id{$k} == 1;
  }
}

sub mummer_and_parse {
  my $tax_id = shift;
  return if -f "$tax_id.consensus.fa";
  if (-z "$tax_id.genus.gi.fa") {
    ### empty non-target db fasta
    system("ln -s $tax_id.ref.fa.subseq $tax_id.consensus.fa");
    ### Finished. Consensus sequences saved: $tax_id
    return 1;
  }
  system("mummer -maxmatch -b -c $tax_id.ref.fa.subseq $tax_id.genus.gi.fa > $tax_id.ref.fa.mums") unless -f "$tax_id.ref.fa.mums";
  ### drop non-specific common sequences
  system("cut -f3 -d ' ' $tax_id.ref.fa.mums|sort|uniq > $tax_id.ref.fa.mums.id") unless -f "$tax_id.ref.fa.mums.id";
  open my $fh1, '<', "$tax_id.ref.fa.mums.id";
  my %spec_id;
  while (<$fh1>) {
    chomp;
    $spec_id{$_} = 0;
  }
  open my $fh2, '>', "$tax_id.consensus.remove.fosn";
  foreach my $k ( keys %spec_id )  {
    say $fh2 $k;
  }
  close $fh2;
  system("fastaremove -f $tax_id.ref.fa.subseq -r $tax_id.consensus.remove.fosn > $tax_id.consensus.fa");
#  system("mummer -mumreference -b -c $tax_id.genus.gi.fa $tax_id.ref.fa.subseq > $tax_id.ref.fa.mums") unless -f "$tax_id.ref.fa.mums";
#  open my $fh1, '<', "$tax_id.ref.fa.mums";
#  my (%spec_id,$seq_id);
#  while (<$fh1>) {
#    chomp;
#    if (/^> (\S+)/) {
#      $seq_id = $1;
#      $spec_id{$seq_id} = 1 unless exists $spec_id{$seq_id};
#    }
#    else {
#      $spec_id{$seq_id} = 0;
#    }
#  }
#  open my $fh2, '>', "$tax_id.consensus.fosn";
#  foreach my $k ( keys %spec_id )  {
#    say $fh2 $k if $spec_id{$k} == 1;
#  }
#  close $fh2;
#  if ( ! -z "$tax_id.consensus.fosn") {
#    system("fastaindex $tax_id.ref.fa.subseq $tax_id.ref.fa.subseq.idx");
#    system("fastafetch -f $tax_id.ref.fa.subseq -i $tax_id.ref.fa.subseq.idx -q $tax_id.consensus.fosn -F T > $tax_id.consensus.fa");
#    ### Finished. Consensus sequences saved: $tax_id
#  }
#  else {
#    ### no consensus sequence find
#    system("touch EMPTY_RESULT");
#  }
  return 0;
}

sub gb_id2tax_id {
  my $id = shift;
  my $dbh = DBI->connect('dbi:mysql:ncbi','ncbi','ncbi');
  if ( $id =~ /gi\|(\d+)\|/ ) {
    my $gi = $1;
    my $sql1 = "select tax_id from taxdump_gi_taxid_nucl where gi = $gi";
    my $tax_id = $dbh->selectrow_array($sql1);
    return $tax_id;
  }
  else {
    return 0;
  }
}

sub make_gi_fosn_db {
  my $idx_file = shift;
  open my $fh1, '<', $idx_file;
  open my $fh2, '>', 'taxdump_gi_fosn.txt';
  while (<$fh1> ) { ### Reading index & insert into db [===|    ] % done
    chomp;
    my @fields = split ' ', $_;
    if ( $fields[0] =~ /gi\|(\d+)\|/ ) {
      say $fh2 join "\t", $1, $fields[0];
    }
  }
  close $fh1;
  close $fh2;
  ### import data into mysql db
  say("mysqlimport -L -u ncbi --password=ncbi ncbi taxdump_gi_fosn.txt");
}

sub fetch_gi_fasta_db {
  my ($tax_id,$idx_file) = @_;
  return 2 if -f "$tax_id.genus.gi.fa";
  ### fetch fasta
  `fastacmd -d nt -i $tax_id.genus.gi.txt -o $tax_id.genus.gi.fa`;
#  open my $fh1, '<', "$tax_id.genus.gi.txt";
#  my @gi = <$fh1>;
#  map {chomp} @gi;
#  close $fh1;
#  my $dbh = DBI->connect('dbi:mysql:ncbi','ncbi','ncbi');
#  open my $fh3, '>', "$tax_id.genus.gi.fosn";
#  foreach my $i ( @gi) {  ### Mapping gi to fosn [===|                 ] % done
#    my $sql1 = "select fosn from taxdump_gi_fosn where gi = $i";
#    my $fosn = $dbh->selectrow_array($sql1);
#    say $fh3 $fosn if defined $fosn;
#  }
#  close $fh3;
#  ### fetch fasta
#  system("fastafetch -f $NT_FILE -i $idx_file -F T -q $tax_id.genus.gi.fosn > $tax_id.genus.gi.fa");
  return;
}

sub fetch_gi_fasta {
  my ($tax_id,$idx_file) = @_;
  return 2 if -f "$tax_id.genus.gi.fa";
  open my $fh1, '<', "$tax_id.genus.gi.txt";
  my @gi = <$fh1>;
  map {chomp} @gi;
  close $fh1;
  open my $fh2, '<', $idx_file;
  open my $fh3, '>', "$tax_id.genus.gi.fosn";
  my %fa_idx;
  while (<$fh2> ) { ### Reading index [===|    ] % done
    chomp;
    my @fields = split ' ', $_;
    if ( $fields[0] =~ /gi\|(\d+)\|/ ) {
      $fa_idx{$1} = $fields[0];
    }
  }
  close $fh2;
  foreach my $i ( @gi) {
    say $fh3 $fa_idx{$i} if exists $fa_idx{$i};
  }
  close $fh3;
  ### fetch fasta
  system("fastafetch -f $NT_FILE -i $idx_file -F T -q $tax_id.genus.gi.fosn > $tax_id.genus.gi.fa");
  return;
}

sub tax2genus_gi {
  my $taxid = shift;
  return 2 if -f "$taxid.genus.gi.txt";
  return 2 if -f "$taxid.genus.gi.fa";
  my $dbh = DBI->connect('dbi:mysql:ncbi','ncbi','ncbi');
  # find parent tax id
  my $sql1 = "select parent_tax_id from taxdump_nodes where tax_id = $taxid";
  my $parent_tax_id = $dbh->selectrow_array($sql1);
  my $sql2 = "select rank from taxdump_nodes where tax_id = $parent_tax_id";
  my $parent_rank = $dbh->selectrow_array($sql2);
  ### parent tax rank : $parent_rank
  # return if $parent_rank ne 'genus';
  # all species in same genus
  my $sql3 = "select tax_id from taxdump_nodes
  where parent_tax_id = $parent_tax_id and tax_id <> $taxid";
  my $rv1 = $dbh->selectcol_arrayref($sql3);
  my @genus_tax_id;
  foreach my $i ( @$rv1 ) { ### Species [===|    ] % done
    # sub species tax ids
    my $sql4 = "select tax_id from taxdump_nodes where parent_tax_id = $i";
    my $rv2 = $dbh->selectcol_arrayref($sql4);
    push @genus_tax_id, @$rv2;
  }
  push @genus_tax_id, @$rv1;
  open my $fh1, '>', "$taxid.genus.tax_id.txt";
  map {say $fh1 $_} @genus_tax_id;
  close $fh1;

  # query tax id to gi list
  my @gi_list;
  while ( my @i50 = splice(@genus_tax_id, 0, 50) ) {
    my $sql5 = "select gi from taxdump_gi_taxid_nucl where tax_id in (".
    (join ',', @i50) .")";
    my $rv3 = $dbh->selectcol_arrayref($sql5);
    push @gi_list, @$rv3;
  }
  open my $fh2, '>', "$taxid.genus.gi.txt";
  map {say $fh2 $_} @gi_list;
  close $fh2;
  return 1;
}

sub fetch_fasta {
  my ($tax_id, @pos) = @_;
  my $file = "$tax_id.ref.fa";
  my $output = "$file.subseq";
  if ( -f $output ) {
    say "$output already existed.";
    return;
  }
  foreach my $i ( 0 .. $#pos ) { ### Fasta fetching [===|    ] % done
    my $len = $pos[$i][1] - $pos[$i][0] + 1;
    my $start = $pos[$i][0] - 1; # 0 based;
    system("fastasubseq -f $file -s $start -l $len >> $output");
  }
  return;
}

sub fasta_subseq {
  my ($fasta, $pos, $save) = @_;
  return if -f $save;
  open my $fa, '<', $fasta;
  my $name = <$fa>;
  $name =~ s/\s.*//s;
  my $seq = '';
  while (<$fa>) { ### read ref seq [===|        ] % done
    chomp;
    s/\s//g;
    s/\d//g;
    $seq .= $_; 
  }
  open my $fs, '>', $save;
  foreach my $i (0 .. $#$pos) { ### subseq [===|              ] % done
    my $len = $$pos[$i][1];
    my $start = $$pos[$i][0];
    say $fs "$name:subseq($start,$len)";
    my $fa = substr $seq, $start, $len;
    $fa =~ s/(.{70})/$1\n/g;
    say $fs $fa;
  }
  close $fs;
  return;
}

sub fetch_common_seq {
  my ($tax_id, $pos) = @_;
  return if -f "$tax_id.ref.fa.subseq";
  open my $fa, '<', "$tax_id.ref.fa";
  my $name = <$fa>;
  $name =~ s/\s.*//s;
  my $seq = ''; 
  while (<$fa>) { ### read ref seq [===|        ] % done
    chomp;
    s/\s//g;
    s/\d//g;
    $seq .= $_; 
  }
  open my $fs, '>', "$tax_id.ref.fa.subseq";
  foreach my $i (0 .. $#$pos) { ### subseq of ref [===|              ] % done
    my $len = $$pos[$i][1] - $$pos[$i][0] + 1;
    my $start = $$pos[$i][0] - 1; # 0 based;
    say $fs "$name:subseq($start,$len)";
    my $fa = substr $seq, $start, $len;
    $fa =~ s/(.{70})/$1\n/g;
    say $fs $fa;
  }
  close $fs;
  return;
}

sub common_mummer_sequence {
  my $tax_id = shift;
  return 1 if -f "$tax_id.ref.fa.subseq";
  open my $mf, '<', "$tax_id.query.mums";
  my (%ranges,$seq_id);
  # record each range as ref seq position
  while (<$mf>) {
    chomp;
    if (/^> (\S+)$/) {
      $seq_id = $1;
    }
    elsif (/^> (\S+) Reverse$/) {
      $seq_id = $1;
    }
    else {
      my @poss = split /\s+/, $_;
      push @{$ranges{$seq_id}}, [$poss[1], $poss[1] + $poss[3] - 1];
    }
  }
  # return if only 2 sequences
  # return if scalar keys %ranges == 1;
  # sort these ranges within each chromesome
  my (@consensus,@ranges_sorted,@ranges_id);
  my $i = 0;
  foreach my $id (keys %ranges ) {
    my %sort_ranges;
    foreach my $r ( @{$ranges{$id}} ) {
      if (not exists $sort_ranges{$r->[0]} ) {
        $sort_ranges{$r->[0]} = $r->[1];
      }
      else {
        $sort_ranges{$r->[0]} = max($sort_ranges{$r->[0]}, $r->[1]);
      }
    }
    foreach my $k (sort {$a <=> $b} keys %sort_ranges ) {
      my ($last_start, $last_stop);
      if ($#{$ranges_sorted[$i]} > -1 ) {
        $last_start  = $ranges_sorted[$i][$#{$ranges_sorted[$i]}][0];
        $last_stop   = $ranges_sorted[$i][$#{$ranges_sorted[$i]}][1];
        if ($last_start <= $k && $last_stop >= $sort_ranges{$k}) {
          next;
        }
        push @{$ranges_sorted[$i]}, [$k,$sort_ranges{$k}];
      }
      else {
        push @{$ranges_sorted[$i]}, [$k,$sort_ranges{$k}];
      }
    }
    push @ranges_id, $id;
    $i++;
  }
  # take the first as a initial pool
  @consensus = @{$ranges_sorted[0]};
  # compare with other chromes' ranges
  foreach my $i ( 1 .. $#ranges_sorted ) { ### Evaluating [===|          ] % done
    # id: $ranges_id[$i]
    @consensus = range_coverage([@consensus], [@{$ranges_sorted[$i]}]);
  }
  return merge_ranges(@consensus);
}

sub merge_ranges {
  my @a = @_;
    my (%sort_ranges,@rv);
    foreach my $r ( @a ) {
      if (not exists $sort_ranges{$r->[0]} ) {
        $sort_ranges{$r->[0]} = $r->[1];
      }
      else {
        $sort_ranges{$r->[0]} = max($sort_ranges{$r->[0]}, $r->[1]);
      }
    }
    foreach my $k (sort {$a <=> $b} keys %sort_ranges ) {
      my ($last_start, $last_stop);
      if ( $#rv > -1 ) {
        $last_start  = $rv[$#rv][0];
        $last_stop   = $rv[$#rv][1];
        if ($last_start <= $k && $last_stop >= $sort_ranges{$k}) {
          next;
        }
        push @rv, [$k,$sort_ranges{$k}];
      }
      else {
        push @rv, [$k,$sort_ranges{$k}];
      }
    }
    return @rv;
}

sub range_coverage {
  my ($a,$b) = @_; # two arrays must be sorted asd in first elm
  my @con;
  # step forword range by range
  my @query = @$b;
  foreach my $i ( 0 .. $#$a ) {
    my $n = 0;
    while (defined $query[$n]) {
      my @range = @{$a->[$i]};
      if ( $query[$n][1] < $range[0] + $MIN_LEN - 1 ) {
        splice @query, $n, 1;
        next;
      }
      last if $query[$n][0] > $range[1] - $MIN_LEN + 1;
      $range[0] = max($range[0], $query[$n][0]);
      $range[1] = min($range[1], $query[$n][1]);
      push @con, [@range];
      $n++;
    }
  }
  return uniq(@con);
}

sub min {
  my $a = shift;
  map {$a = $_ if $a > $_} @_;
  return $a;
}

sub max {
  my $a = shift;
  map {$a = $_ if $a < $_} @_;
  return $a;
}

sub uniq {
  my @a = @_;
  my (%uniq,@array);
  foreach my $i ( 0 .. $#a ) {
    $uniq{join '_', @{$a[$i]}} = $a[$i]->[0];
  }
  foreach my $k ( sort {$uniq{$a} <=> $uniq{$b}} keys %uniq ) {
    push @array, [split '_', $k];
  }
  return @array;
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
