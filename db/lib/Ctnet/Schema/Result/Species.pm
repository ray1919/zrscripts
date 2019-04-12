use utf8;
package Ctnet::Schema::Result::Species;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::Species

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<species>

=cut

__PACKAGE__->table("species");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 common

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "common",
  { data_type => "varchar", is_nullable => 1, size => 45 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 genes

Type: has_many

Related object: L<Ctnet::Schema::Result::Gene>

=cut

__PACKAGE__->has_many(
  "genes",
  "Ctnet::Schema::Result::Gene",
  { "foreign.tax_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mirnas

Type: has_many

Related object: L<Ctnet::Schema::Result::Mirna>

=cut

__PACKAGE__->has_many(
  "mirnas",
  "Ctnet::Schema::Result::Mirna",
  { "foreign.tax_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pcr_samples

Type: has_many

Related object: L<Ctnet::Schema::Result::PcrSample>

=cut

__PACKAGE__->has_many(
  "pcr_samples",
  "Ctnet::Schema::Result::PcrSample",
  { "foreign.species_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 primers

Type: has_many

Related object: L<Ctnet::Schema::Result::Primer>

=cut

__PACKAGE__->has_many(
  "primers",
  "Ctnet::Schema::Result::Primer",
  { "foreign.tax_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 15:38:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:utwDYhZPQxuy0y6hnEQBfw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
