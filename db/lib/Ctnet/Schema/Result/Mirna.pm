use utf8;
package Ctnet::Schema::Result::Mirna;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::Mirna - miRBase 20

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<mirna>

=cut

__PACKAGE__->table("mirna");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 mirna_id

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 accession

  data_type: 'varchar'
  is_nullable: 0
  size: 15

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 tax_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "mirna_id",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "accession",
  { data_type => "varchar", is_nullable => 0, size => 15 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "tax_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 primers

Type: has_many

Related object: L<Ctnet::Schema::Result::Primer>

=cut

__PACKAGE__->has_many(
  "primers",
  "Ctnet::Schema::Result::Primer",
  { "foreign.mirna_fk" => "self.id" },
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
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 15:38:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:O2GrKlsWBwyiiJPkZTjXrw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
