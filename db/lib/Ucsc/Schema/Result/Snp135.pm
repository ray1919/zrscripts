use utf8;
package Ucsc::Schema::Result::Snp135;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ucsc::Schema::Result::Snp135

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<snp135>

=cut

__PACKAGE__->table("snp135");

=head1 ACCESSORS

=head2 bin

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 chrom

  data_type: 'varchar'
  is_nullable: 0
  size: 31

=head2 chromstart

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 chromend

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 15

=head2 score

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 strand

  data_type: 'enum'
  extra: {list => ["+","-"]}
  is_nullable: 0

=head2 refncbi

  data_type: 'blob'
  is_nullable: 0

=head2 refucsc

  data_type: 'blob'
  is_nullable: 0

=head2 observed

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 moltype

  data_type: 'enum'
  extra: {list => ["unknown","genomic","cDNA"]}
  is_nullable: 0

=head2 class

  data_type: 'enum'
  extra: {list => ["unknown","single","in-del","het","microsatellite","named","mixed","mnp","insertion","deletion"]}
  is_nullable: 0

=head2 valid

  data_type: 'set'
  extra: {list => ["unknown","by-cluster","by-frequency","by-submitter","by-2hit-2allele","by-hapmap","by-1000genomes"]}
  is_nullable: 0

=head2 avhet

  data_type: 'float'
  is_nullable: 0

=head2 avhetse

  data_type: 'float'
  is_nullable: 0

=head2 func

  data_type: 'set'
  extra: {list => ["unknown","coding-synon","intron","near-gene-3","near-gene-5","nonsense","missense","stop-loss","frameshift","cds-indel","untranslated-3","untranslated-5","splice-5"]}
  is_nullable: 0

=head2 loctype

  data_type: 'enum'
  extra: {list => ["range","exact","between","rangeInsertion","rangeSubstitution","rangeDeletion"]}
  is_nullable: 0

=head2 weight

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 exceptions

  data_type: 'set'
  extra: {list => ["RefAlleleMismatch","RefAlleleRevComp","DuplicateObserved","MixedObserved","FlankMismatchGenomeLonger","FlankMismatchGenomeEqual","FlankMismatchGenomeShorter","NamedDeletionZeroSpan","NamedInsertionNonzeroSpan","SingleClassLongerSpan","SingleClassZeroSpan","SingleClassTriAllelic","SingleClassQuadAllelic","ObservedWrongFormat","ObservedTooLong","ObservedContainsIupac","ObservedMismatch","MultipleAlignments","NonIntegerChromCount","AlleleFreqSumNot1","SingleAlleleFreq","InconsistentAlleles"]}
  is_nullable: 0

=head2 submittercount

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 submitters

  data_type: 'longblob'
  is_nullable: 0

=head2 allelefreqcount

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 alleles

  data_type: 'longblob'
  is_nullable: 0

=head2 allelens

  data_type: 'longblob'
  is_nullable: 0

=head2 allelefreqs

  data_type: 'longblob'
  is_nullable: 0

=head2 bitfields

  data_type: 'set'
  extra: {list => ["clinically-assoc","maf-5-some-pop","maf-5-all-pops","has-omim-omia","microattr-tpa","submitted-by-lsdb","genotype-conflict","rs-cluster-nonoverlapping-alleles","observed-mismatch"]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "bin",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "chrom",
  { data_type => "varchar", is_nullable => 0, size => 31 },
  "chromstart",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "chromend",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 15 },
  "score",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "strand",
  { data_type => "enum", extra => { list => ["+", "-"] }, is_nullable => 0 },
  "refncbi",
  { data_type => "blob", is_nullable => 0 },
  "refucsc",
  { data_type => "blob", is_nullable => 0 },
  "observed",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "moltype",
  {
    data_type => "enum",
    extra => { list => ["unknown", "genomic", "cDNA"] },
    is_nullable => 0,
  },
  "class",
  {
    data_type => "enum",
    extra => {
      list => [
        "unknown",
        "single",
        "in-del",
        "het",
        "microsatellite",
        "named",
        "mixed",
        "mnp",
        "insertion",
        "deletion",
      ],
    },
    is_nullable => 0,
  },
  "valid",
  {
    data_type => "set",
    extra => {
      list => [
        "unknown",
        "by-cluster",
        "by-frequency",
        "by-submitter",
        "by-2hit-2allele",
        "by-hapmap",
        "by-1000genomes",
      ],
    },
    is_nullable => 0,
  },
  "avhet",
  { data_type => "float", is_nullable => 0 },
  "avhetse",
  { data_type => "float", is_nullable => 0 },
  "func",
  {
    data_type => "set",
    extra => {
      list => [
        "unknown",
        "coding-synon",
        "intron",
        "near-gene-3",
        "near-gene-5",
        "nonsense",
        "missense",
        "stop-loss",
        "frameshift",
        "cds-indel",
        "untranslated-3",
        "untranslated-5",
        "splice-5",
      ],
    },
    is_nullable => 0,
  },
  "loctype",
  {
    data_type => "enum",
    extra => {
      list => [
        "range",
        "exact",
        "between",
        "rangeInsertion",
        "rangeSubstitution",
        "rangeDeletion",
      ],
    },
    is_nullable => 0,
  },
  "weight",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "exceptions",
  {
    data_type => "set",
    extra => {
      list => [
        "RefAlleleMismatch",
        "RefAlleleRevComp",
        "DuplicateObserved",
        "MixedObserved",
        "FlankMismatchGenomeLonger",
        "FlankMismatchGenomeEqual",
        "FlankMismatchGenomeShorter",
        "NamedDeletionZeroSpan",
        "NamedInsertionNonzeroSpan",
        "SingleClassLongerSpan",
        "SingleClassZeroSpan",
        "SingleClassTriAllelic",
        "SingleClassQuadAllelic",
        "ObservedWrongFormat",
        "ObservedTooLong",
        "ObservedContainsIupac",
        "ObservedMismatch",
        "MultipleAlignments",
        "NonIntegerChromCount",
        "AlleleFreqSumNot1",
        "SingleAlleleFreq",
        "InconsistentAlleles",
      ],
    },
    is_nullable => 0,
  },
  "submittercount",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "submitters",
  { data_type => "longblob", is_nullable => 0 },
  "allelefreqcount",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "alleles",
  { data_type => "longblob", is_nullable => 0 },
  "allelens",
  { data_type => "longblob", is_nullable => 0 },
  "allelefreqs",
  { data_type => "longblob", is_nullable => 0 },
  "bitfields",
  {
    data_type => "set",
    extra => {
      list => [
        "clinically-assoc",
        "maf-5-some-pop",
        "maf-5-all-pops",
        "has-omim-omia",
        "microattr-tpa",
        "submitted-by-lsdb",
        "genotype-conflict",
        "rs-cluster-nonoverlapping-alleles",
        "observed-mismatch",
      ],
    },
    is_nullable => 0,
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-17 11:21:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iMI7dgJHZ5/K6wMSBtmaMw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
