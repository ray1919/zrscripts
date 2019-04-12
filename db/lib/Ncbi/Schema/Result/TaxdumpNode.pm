use utf8;
package Ncbi::Schema::Result::TaxdumpNode;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ncbi::Schema::Result::TaxdumpNode

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<taxdump_nodes>

=cut

__PACKAGE__->table("taxdump_nodes");

=head1 ACCESSORS

=head2 tax_id

  data_type: 'integer'
  is_nullable: 0

=head2 parent_tax_id

  data_type: 'integer'
  is_nullable: 0

=head2 rank

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=head2 embl_code

  data_type: 'char'
  is_nullable: 0
  size: 2

=head2 division_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 inherited_div_flag

  data_type: 'tinyint'
  is_nullable: 0

=head2 genetic_code_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 inherited_gc_flag

  data_type: 'tinyint'
  is_nullable: 0

=head2 mitochondrial_genetic_code_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 inherited_mgc_flag

  data_type: 'tinyint'
  is_nullable: 0

=head2 genbank_hidden_flag

  data_type: 'tinyint'
  is_nullable: 0

=head2 hidden_subtree_root_flag

  data_type: 'tinyint'
  is_nullable: 0

=head2 comments

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=cut

__PACKAGE__->add_columns(
  "tax_id",
  { data_type => "integer", is_nullable => 0 },
  "parent_tax_id",
  { data_type => "integer", is_nullable => 0 },
  "rank",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "embl_code",
  { data_type => "char", is_nullable => 0, size => 2 },
  "division_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "inherited_div_flag",
  { data_type => "tinyint", is_nullable => 0 },
  "genetic_code_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "inherited_gc_flag",
  { data_type => "tinyint", is_nullable => 0 },
  "mitochondrial_genetic_code_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "inherited_mgc_flag",
  { data_type => "tinyint", is_nullable => 0 },
  "genbank_hidden_flag",
  { data_type => "tinyint", is_nullable => 0 },
  "hidden_subtree_root_flag",
  { data_type => "tinyint", is_nullable => 0 },
  "comments",
  { data_type => "varchar", is_nullable => 0, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</tax_id>

=back

=cut

__PACKAGE__->set_primary_key("tax_id");

=head1 RELATIONS

=head2 division

Type: belongs_to

Related object: L<Ncbi::Schema::Result::TaxdumpDivision>

=cut

__PACKAGE__->belongs_to(
  "division",
  "Ncbi::Schema::Result::TaxdumpDivision",
  { division_id => "division_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 genetic_code

Type: belongs_to

Related object: L<Ncbi::Schema::Result::TaxdumpGencode>

=cut

__PACKAGE__->belongs_to(
  "genetic_code",
  "Ncbi::Schema::Result::TaxdumpGencode",
  { genetic_code_id => "genetic_code_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 mitochondrial_genetic_code

Type: belongs_to

Related object: L<Ncbi::Schema::Result::TaxdumpGencode>

=cut

__PACKAGE__->belongs_to(
  "mitochondrial_genetic_code",
  "Ncbi::Schema::Result::TaxdumpGencode",
  { genetic_code_id => "mitochondrial_genetic_code_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-11-04 13:47:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7T9VzBQhQ5Vw/HXAOGGN/Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
