use utf8;
package Ctnet::Schema::Result::Gene;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::Gene

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<gene>

=cut

__PACKAGE__->table("gene");

=head1 ACCESSORS

=head2 gene_id

  data_type: 'integer'
  is_nullable: 0

=head2 gene_symbol

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 gene_name

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 tax_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 synonyms

  data_type: 'text'
  is_nullable: 1

=head2 type_of_gene

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 modification_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "gene_id",
  { data_type => "integer", is_nullable => 0 },
  "gene_symbol",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "gene_name",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "tax_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "synonyms",
  { data_type => "text", is_nullable => 1 },
  "type_of_gene",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "modification_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</gene_id>

=back

=cut

__PACKAGE__->set_primary_key("gene_id");

=head1 RELATIONS

=head2 pcr_experiments

Type: has_many

Related object: L<Ctnet::Schema::Result::PcrExperiment>

=cut

__PACKAGE__->has_many(
  "pcr_experiments",
  "Ctnet::Schema::Result::PcrExperiment",
  { "foreign.gene_id" => "self.gene_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 primers

Type: has_many

Related object: L<Ctnet::Schema::Result::Primer>

=cut

__PACKAGE__->has_many(
  "primers",
  "Ctnet::Schema::Result::Primer",
  { "foreign.gene_fk" => "self.gene_id" },
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
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 15:38:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GdLEoAhq9l6ZXtyb+sRKJg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
