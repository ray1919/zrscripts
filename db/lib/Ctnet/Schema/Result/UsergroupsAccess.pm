use utf8;
package Ctnet::Schema::Result::UsergroupsAccess;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::UsergroupsAccess

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<usergroups_access>

=cut

__PACKAGE__->table("usergroups_access");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 element

  data_type: 'integer'
  is_nullable: 0

=head2 element_id

  data_type: 'bigint'
  is_nullable: 0

=head2 module

  data_type: 'varchar'
  is_nullable: 0
  size: 140

=head2 controller

  data_type: 'varchar'
  is_nullable: 0
  size: 140

=head2 permission

  data_type: 'varchar'
  is_nullable: 0
  size: 7

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "element",
  { data_type => "integer", is_nullable => 0 },
  "element_id",
  { data_type => "bigint", is_nullable => 0 },
  "module",
  { data_type => "varchar", is_nullable => 0, size => 140 },
  "controller",
  { data_type => "varchar", is_nullable => 0, size => 140 },
  "permission",
  { data_type => "varchar", is_nullable => 0, size => 7 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-05-16 15:23:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zV2VDj8xlV5juZLzd9PIMQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
