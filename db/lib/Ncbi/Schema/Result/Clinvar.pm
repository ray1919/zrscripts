use utf8;
package Ncbi::Schema::Result::Clinvar;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ncbi::Schema::Result::Clinvar - 2014-06 update

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<clinvar>

=cut

__PACKAGE__->table("clinvar");

=head1 ACCESSORS

=head2 clinvar_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 clinvar_acc

  data_type: 'char'
  is_nullable: 0
  size: 12

=head2 title

  data_type: 'text'
  is_nullable: 0

=head2 phenotype

  data_type: 'varchar'
  is_nullable: 0
  size: 150

=head2 gene_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 omim_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 hgvs

  data_type: 'text'
  is_nullable: 1

=head2 omim_av

  data_type: 'varchar'
  is_nullable: 1
  size: 120

=head2 dbsnp

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 cli_sig

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 sl_acc

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 sl_ass

  data_type: 'varchar'
  is_nullable: 1
  size: 12

=head2 sl_chr

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 sl_start

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 sl_stop

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 25

=cut

__PACKAGE__->add_columns(
  "clinvar_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "clinvar_acc",
  { data_type => "char", is_nullable => 0, size => 12 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "phenotype",
  { data_type => "varchar", is_nullable => 0, size => 150 },
  "gene_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "omim_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "hgvs",
  { data_type => "text", is_nullable => 1 },
  "omim_av",
  { data_type => "varchar", is_nullable => 1, size => 120 },
  "dbsnp",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "cli_sig",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "sl_acc",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "sl_ass",
  { data_type => "varchar", is_nullable => 1, size => 12 },
  "sl_chr",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "sl_start",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "sl_stop",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 25 },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-11-04 13:47:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aWp9B6G2UWI7z4HWHnzHFQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
__PACKAGE__->belongs_to(
  "gene",
  "Ncbi::Schema::Result::GeneInfo",
  { GeneID => "gene_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);
