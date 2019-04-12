use utf8;
package Ctnet::Schema::Result::Position;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::Position

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<position>

=cut

__PACKAGE__->table("position");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 plate_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 well

  data_type: 'char'
  is_nullable: 0
  size: 10

=head2 primer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 synthetic_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 45

=head2 store_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 store_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "plate_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "well",
  { data_type => "char", is_nullable => 0, size => 10 },
  "primer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "synthetic_name",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 45 },
  "store_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "store_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 plate

Type: belongs_to

Related object: L<Ctnet::Schema::Result::Plate>

=cut

__PACKAGE__->belongs_to(
  "plate",
  "Ctnet::Schema::Result::Plate",
  { id => "plate_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "CASCADE" },
);

=head2 primer

Type: belongs_to

Related object: L<Ctnet::Schema::Result::Primer>

=cut

__PACKAGE__->belongs_to(
  "primer",
  "Ctnet::Schema::Result::Primer",
  { id => "primer_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 store_type

Type: belongs_to

Related object: L<Ctnet::Schema::Result::StoreType>

=cut

__PACKAGE__->belongs_to(
  "store_type",
  "Ctnet::Schema::Result::StoreType",
  { id => "store_type_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-08-26 15:56:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Kn3RTpiyqYEqxpHHDZ9/hg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
