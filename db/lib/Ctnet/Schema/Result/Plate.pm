use utf8;
package Ctnet::Schema::Result::Plate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::Plate

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<plate>

=cut

__PACKAGE__->table("plate");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 feature

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "feature",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name", ["name"]);

=head1 RELATIONS

=head2 positions

Type: has_many

Related object: L<Ctnet::Schema::Result::Position>

=cut

__PACKAGE__->has_many(
  "positions",
  "Ctnet::Schema::Result::Position",
  { "foreign.plate_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-08-26 15:56:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:b/xs9hIUOOSNlzoPvfIibQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
