use utf8;
package Ncbi::Schema::Result::TaxdumpDivision;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ncbi::Schema::Result::TaxdumpDivision

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<taxdump_division>

=cut

__PACKAGE__->table("taxdump_division");

=head1 ACCESSORS

=head2 division_id

  data_type: 'integer'
  is_nullable: 0

=head2 division_cde

  data_type: 'char'
  is_nullable: 0
  size: 3

=head2 division_name

  data_type: 'varchar'
  is_nullable: 0
  size: 21

=head2 comments

  data_type: 'varchar'
  is_nullable: 0
  size: 56

=cut

__PACKAGE__->add_columns(
  "division_id",
  { data_type => "integer", is_nullable => 0 },
  "division_cde",
  { data_type => "char", is_nullable => 0, size => 3 },
  "division_name",
  { data_type => "varchar", is_nullable => 0, size => 21 },
  "comments",
  { data_type => "varchar", is_nullable => 0, size => 56 },
);

=head1 PRIMARY KEY

=over 4

=item * L</division_id>

=back

=cut

__PACKAGE__->set_primary_key("division_id");

=head1 RELATIONS

=head2 taxdump_nodes

Type: has_many

Related object: L<Ncbi::Schema::Result::TaxdumpNode>

=cut

__PACKAGE__->has_many(
  "taxdump_nodes",
  "Ncbi::Schema::Result::TaxdumpNode",
  { "foreign.division_id" => "self.division_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-11-04 13:47:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fFqAF620v0dtt9mjKgyczg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
