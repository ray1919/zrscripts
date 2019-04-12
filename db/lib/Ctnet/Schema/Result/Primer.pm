use utf8;
package Ctnet::Schema::Result::Primer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::Primer

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<primer>

=cut

__PACKAGE__->table("primer");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 gene_id

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 gene_symbol

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 primer_id

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 barcode

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 tax_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 type_of_primer

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 gene_fk

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 mirna_fk

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 create_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 update_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 qc

  data_type: 'smallint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "gene_id",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "gene_symbol",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "primer_id",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "barcode",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "tax_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "type_of_primer",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "gene_fk",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "mirna_fk",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "create_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "update_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "qc",
  { data_type => "smallint", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 gene_fk

Type: belongs_to

Related object: L<Ctnet::Schema::Result::Gene>

=cut

__PACKAGE__->belongs_to(
  "gene_fk",
  "Ctnet::Schema::Result::Gene",
  { gene_id => "gene_fk" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 mirna_fk

Type: belongs_to

Related object: L<Ctnet::Schema::Result::Mirna>

=cut

__PACKAGE__->belongs_to(
  "mirna_fk",
  "Ctnet::Schema::Result::Mirna",
  { id => "mirna_fk" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 pcr_experiments

Type: has_many

Related object: L<Ctnet::Schema::Result::PcrExperiment>

=cut

__PACKAGE__->has_many(
  "pcr_experiments",
  "Ctnet::Schema::Result::PcrExperiment",
  { "foreign.primer_fk" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 positions

Type: has_many

Related object: L<Ctnet::Schema::Result::Position>

=cut

__PACKAGE__->has_many(
  "positions",
  "Ctnet::Schema::Result::Position",
  { "foreign.primer_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tax

Type: belongs_to

Related object: L<Ctnet::Schema::Result::Species>

=cut

__PACKAGE__->belongs_to(
  "tax",
  "Ctnet::Schema::Result::Species",
  { id => "tax_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 15:38:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RvQc7G3JdeuhvglFlJWIMA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
