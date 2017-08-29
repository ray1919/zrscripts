#!/usr/bin/env perl
# Date:2017-08-29
# Author: Zhao
# Purpose: 根据Fusion ID来获取融合基因序列。

use 5.012;
use Data::Dump qw/dump/;
use Bio::DB::RefSeq;
use Bioinfo::Fasta;
use Bio::SeqHash;


open my $fh1, '<', 'translocation_name.tsv';

my $title = <$fh1>;
while (<$fh1>) {
    chomp;
    my @fields = split "\t", $_;
    my $fusion_id = $fields[0];
    my $translocation_name = $fields[1];
    my ($gene1, $acc1, $start1, $end1, $gene2, $acc2, $start2, $end2);
    if ($translocation_name =~ m/(\w+)\{(\S+)\}:r\.(\d+)_(\d+)_(\w+)\{(\S+)\}:r\.(\d+)_(\d+)/ )
    {
        ($gene1, $acc1, $start1, $end1, $gene2, $acc2, $start2, $end2) =
            ($1, $2, $3, $4, $5, $6, $7, $8);
    } else {
        print "$translocation_name Pattern not found!";
    }
    my $gene_seq1 = get_fusion_gene_seq($acc1, $start1, $end1);
    my $gene_seq2 = get_fusion_gene_seq($acc2, $start2, $end2);
    my $fusion_seq = "$gene_seq1|$gene_seq2";
    say ">COSF$fusion_id";
    say $fusion_seq;
}

sub get_fusion_gene_seq {
    my ($acc, $start, $end) = @_;
    if ($acc =~ m/^ENST/) {
        return substr get_ens_gene($acc), $start-1, $end - $start + 1;
    } elsif ($acc =~ m/^NM_/) {
        return substr get_gb_gene($acc), $start-1, $end - $start + 1;
    } else {
        return 0;
    }
}

sub get_ens_gene {
    my ($acc) = @_;
    my $seq_id = `grep $acc All_COSMIC_Genes.fasta |cut -f2 -d'>'|cut -f1 -d' '`;
    chomp $seq_id;
    my $obj = Bio::SeqHash->new(file => "All_COSMIC_Genes.fasta");
    my $seq_fa = $obj->get_seq($seq_id); # get the sequence of "seq_id"(in the FASTA format)
    return $seq_fa;
}

sub get_gb_gene {
    my ($acc) = @_;
    my $db = Bio::DB::RefSeq->new();
    $db->request_format('fasta');
    my $seq = $db->get_Seq_by_acc($acc); # RefSeq ACC
    return $seq->seq;
}

