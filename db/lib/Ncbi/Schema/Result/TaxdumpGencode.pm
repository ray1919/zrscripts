use utf8;
package Ncbi::Schema::Result::TaxdumpGencode;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ncbi::Schema::Result::TaxdumpGencode

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<taxdump_gencode>

=cut

__PACKAGE__->table("taxdump_gencode");

=head1 ACCESSORS

=head2 genetic_code_id

  data_type: 'integer'
  is_nullable: 0

=head2 abbreviation

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 cde

  data_type: 'varchar'
  is_nullable: 0
  size: 65

=head2 starts

  data_type: 'varchar'
  is_nullable: 0
  size: 65

=cut

__PACKAGE__->add_columns(
  "genetic_code_id",
  { data_type => "integer", is_nullable => 0 },
  "abbreviation",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "cde",
  { data_type => "varchar", is_nullable => 0, size => 65 },
  "starts",
  { data_type => "varchar", is_nullable => 0, size => 65 },
);

=head1 PRIMARY KEY

=over 4

=item * L</genetic_code_id>

=back

=cut

__PACKAGE__->set_primary_key("genetic_code_id");

=head1 RELATIONS

=head2 taxdump_nodes_genetic_codes

Type: has_many

Related object: L<Ncbi::Schema::Result::TaxdumpNode>

=cut

__PACKAGE__->has_many(
  "taxdump_nodes_genetic_codes",
  "Ncbi::Schema::Result::TaxdumpNode",
  { "foreign.genetic_code_id" => "self.genetic_code_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 taxdump_nodes_mitochondrial_genetic_codes

Type: has_many

Related object: L<Ncbi::Schema::Result::TaxdumpNode>

=cut

__PACKAGE__->has_many(
  "taxdump_nodes_mitochondrial_genetic_codes",
  "Ncbi::Schema::Result::TaxdumpNode",
  {
    "foreign.mitochondrial_genetic_code_id" => "self.genetic_code_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-11-04 13:47:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nAHxK+H/adXjqTeNgpGuxQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
