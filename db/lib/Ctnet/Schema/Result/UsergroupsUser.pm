use utf8;
package Ctnet::Schema::Result::UsergroupsUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::UsergroupsUser

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<usergroups_user>

=cut

__PACKAGE__->table("usergroups_user");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 group_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 120

=head2 password

  data_type: 'varchar'
  is_nullable: 1
  size: 120

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 120

=head2 home

  data_type: 'varchar'
  is_nullable: 1
  size: 120

=head2 status

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 0

=head2 question

  data_type: 'text'
  is_nullable: 1

=head2 answer

  data_type: 'text'
  is_nullable: 1

=head2 creation_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 activation_code

  data_type: 'varchar'
  is_nullable: 1
  size: 30

=head2 activation_time

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 last_login

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 ban

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 ban_reason

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "group_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 120 },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 120 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 120 },
  "home",
  { data_type => "varchar", is_nullable => 1, size => 120 },
  "status",
  { data_type => "tinyint", default_value => 1, is_nullable => 0 },
  "question",
  { data_type => "text", is_nullable => 1 },
  "answer",
  { data_type => "text", is_nullable => 1 },
  "creation_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "activation_code",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "activation_time",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "last_login",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "ban",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "ban_reason",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<email>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("email", ["email"]);

=head2 C<username>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("username", ["username"]);

=head1 RELATIONS

=head2 group

Type: belongs_to

Related object: L<Ctnet::Schema::Result::UsergroupsGroup>

=cut

__PACKAGE__->belongs_to(
  "group",
  "Ctnet::Schema::Result::UsergroupsGroup",
  { id => "group_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "RESTRICT",
  },
);

=head2 task_create_users

Type: has_many

Related object: L<Ctnet::Schema::Result::Task>

=cut

__PACKAGE__->has_many(
  "task_create_users",
  "Ctnet::Schema::Result::Task",
  { "foreign.create_user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 task_owners

Type: has_many

Related object: L<Ctnet::Schema::Result::Task>

=cut

__PACKAGE__->has_many(
  "task_owners",
  "Ctnet::Schema::Result::Task",
  { "foreign.owner_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 task_requesters

Type: has_many

Related object: L<Ctnet::Schema::Result::Task>

=cut

__PACKAGE__->has_many(
  "task_requesters",
  "Ctnet::Schema::Result::Task",
  { "foreign.requester_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 task_update_users

Type: has_many

Related object: L<Ctnet::Schema::Result::Task>

=cut

__PACKAGE__->has_many(
  "task_update_users",
  "Ctnet::Schema::Result::Task",
  { "foreign.update_user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-08-26 15:56:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ul8zfjE+hXoxzFajI5C3cw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
