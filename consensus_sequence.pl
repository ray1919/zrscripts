#!/usr/bin/env perl
# Author: Zhao
# Date: 2014-07-17
# Purpose: 寻找基因组序列中唯一的一致序列

use 5.014;
use Data::Dump qw/dump/;
use Smart::Comments;
use autodie qw(:all);
use DBI;

my $MIN_LEN = 20;

### Query whole genomic sequences in NCBI with tax id 1311
### Representative sequence NC_004116.fa
# grep -P "complete genome$" 1311_complete_genome.fasta |cut -f1 -d ' ' > 1311_complete_genome.fosn
# delete NC_004116 from fosn
# fastaindex 1311_complete_genome.fasta 1311_complete_genome.idx
# fastafetch -f 1311_complete_genome.fasta -i 1311_complete_genome.idx -q 1311_complete_genome.fosn -F T >  query.fa
### use mummer to locate unique consensus seuqence between each chromes seuqnes
# time mummer -mum -b -c NC_004116.fa query.fa > query.mums
### find commen consensus seuqences

dump gb_id2tax_id('gi|618628472|gb|CP007565.1|');exit;
consensus_blast_parse(1311,"subseq.m8");
exit;

my @cms = common_mummer_sequence('query.mums'); # time elapsed: 4s
# open my $fh, '>', 'consensus.cords';
# map {say $fh join "\t", @$_} @cms;
# close $fh;

### fetch fasta from refseq
fetch_fasta("NC_004116.fa",@cms);

### construct non-target nt db
tax2genus_gi(1311);
fetch_gi_fasta(1311, 'nt.idx'); # time elapsed: 8min

### mummer against non-target db
mummer_and_parse(1311); # time 48s

### blast-based compare

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
  while (<$fh1>) {
    my @fd = split "\t", $_;
    my ($qid,$sid,$identity) = @fd[0..2];
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
    exit;
  }
  open my $fh2, '>', "$tax_id.consensus.blast.fosn";
  foreach my $k ( keys %consensus_id )  {
    say $fh2 $k if $spec_id{$k} == 1;
  }
}

sub mummer_and_parse {
  my $tax_id = shift;
  system("mummer -mumreference -b -c $tax_id.genus.gi.fa NC_004116.fa.subseq > NC_004116.fa.mums") unless -f "NC_004116.fa.mums";
  open my $fh1, '<', "NC_004116.fa.mums";
  my (%spec_id,$seq_id);
  while (<$fh1>) {
    chomp;
    if (/^> (\S+)/) {
      $seq_id = $1;
      $spec_id{$seq_id} = 1 unless exists $spec_id{$seq_id};
    }
    else {
      $spec_id{$seq_id} = 0;
    }
  }
  open my $fh2, '>', "$tax_id.consensus.fosn";
  foreach my $k ( keys %spec_id )  {
    say $fh2 $k if $spec_id{$k} == 1;
  }
  # fastaindex NC_004116.fa.subseq NC_004116.fa.subseq.idx
  # fastafetch -f NC_004116.fa.subseq -i NC_004116.fa.subseq.idx -q 1311.consensus.fosn -F T > 1311.consensus.fa
  return;
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
  system("fastafetch -f nt -i $idx_file -F T -q $tax_id.genus.gi.fosn > $tax_id.genus.gi.fa");
  return;
}

sub tax2genus_gi {
  my $taxid = shift;
  return 2 if -f "$taxid.genus.gi.txt";
  my $dbh = DBI->connect('dbi:mysql:ncbi','ncbi','ncbi');
  # find parent tax id
  my $sql1 = "select parent_tax_id from taxdump_nodes where tax_id = $taxid";
  my $parent_tax_id = $dbh->selectrow_array($sql1);
  my $sql2 = "select rank from taxdump_nodes where tax_id = $parent_tax_id";
  my $parent_rank = $dbh->selectrow_array($sql2);
  ### parent tax rank : $parent_rank
  return if $parent_rank ne 'genus';
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
  while ( my @i50 = splice(@genus_tax_id, 0, 50) ) { ### Sub-species [===|    ] % done
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
  my ($file, @pos) = @_;
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

sub common_mummer_sequence {
  my $mummer_file = shift;
  open my $mf, '<', $mummer_file;
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
  return if scalar keys %ranges == 1;
  # sort these ranges within each chromesome
  my (@consensus,@ranges_sorted,@ranges_id);
  my $i = 0;
  foreach my $id (keys %ranges ) {
    my %sort_ranges;
    foreach my $r ( @{$ranges{$id}} ) {
      $sort_ranges{$r->[0]} = $r->[1];
    }
    foreach my $k (sort {$a <=> $b} keys %sort_ranges ) {
      push @{$ranges_sorted[$i]}, [$k,$sort_ranges{$k}];
    }
    push @ranges_id, $id;
    $i++;
  }
  # take the first as a initial pool
  @consensus = @{$ranges_sorted[0]};
  # compare with other chromes' ranges
  foreach my $i ( 1 .. $#ranges_sorted ) { ### Evaluating [===|    ] % done
    # id: $ranges_id[$i]
    @consensus = range_coverage([@consensus], [@{$ranges_sorted[$i]}]);
  }
  return @consensus;
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
  my ($a, $b) = @_;
  return $a if $a <= $b;
  return $b;
}

sub max {
  my ($a, $b) = @_;
  return $a if $a >= $b;
  return $b;
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
