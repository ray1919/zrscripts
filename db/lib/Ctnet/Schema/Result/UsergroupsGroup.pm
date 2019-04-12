use utf8;
package Ctnet::Schema::Result::UsergroupsGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::UsergroupsGroup

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<usergroups_group>

=cut

__PACKAGE__->table("usergroups_group");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 groupname

  data_type: 'varchar'
  is_nullable: 0
  size: 120

=head2 level

  data_type: 'integer'
  is_nullable: 1

=head2 home

  data_type: 'varchar'
  is_nullable: 1
  size: 120

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "groupname",
  { data_type => "varchar", is_nullable => 0, size => 120 },
  "level",
  { data_type => "integer", is_nullable => 1 },
  "home",
  { data_type => "varchar", is_nullable => 1, size => 120 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<groupname>

=over 4

=item * L</groupname>

=back

=cut

__PACKAGE__->add_unique_constraint("groupname", ["groupname"]);

=head1 RELATIONS

=head2 usergroups_users

Type: has_many

Related object: L<Ctnet::Schema::Result::UsergroupsUser>

=cut

__PACKAGE__->has_many(
  "usergroups_users",
  "Ctnet::Schema::Result::UsergroupsUser",
  { "foreign.group_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-05-16 15:23:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AWhr2x+oFyo0v8ZqojUH7A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
