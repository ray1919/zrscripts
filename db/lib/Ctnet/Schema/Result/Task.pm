use utf8;
package Ctnet::Schema::Result::Task;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::Task

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<task>

=cut

__PACKAGE__->table("task");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 status

  data_type: 'text'
  is_nullable: 1

=head2 owner_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 requester_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 acceptance_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 due_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 weekly_remind

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 note

  data_type: 'text'
  is_nullable: 1

=head2 create_time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 create_user_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 update_time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 update_user_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "status",
  { data_type => "text", is_nullable => 1 },
  "owner_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "requester_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "acceptance_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "due_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "weekly_remind",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "note",
  { data_type => "text", is_nullable => 1 },
  "create_time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "create_user_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "update_time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "update_user_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 create_user

Type: belongs_to

Related object: L<Ctnet::Schema::Result::UsergroupsUser>

=cut

__PACKAGE__->belongs_to(
  "create_user",
  "Ctnet::Schema::Result::UsergroupsUser",
  { id => "create_user_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 owner

Type: belongs_to

Related object: L<Ctnet::Schema::Result::UsergroupsUser>

=cut

__PACKAGE__->belongs_to(
  "owner",
  "Ctnet::Schema::Result::UsergroupsUser",
  { id => "owner_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 requester

Type: belongs_to

Related object: L<Ctnet::Schema::Result::UsergroupsUser>

=cut

__PACKAGE__->belongs_to(
  "requester",
  "Ctnet::Schema::Result::UsergroupsUser",
  { id => "requester_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 update_user

Type: belongs_to

Related object: L<Ctnet::Schema::Result::UsergroupsUser>

=cut

__PACKAGE__->belongs_to(
  "update_user",
  "Ctnet::Schema::Result::UsergroupsUser",
  { id => "update_user_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-08-29 13:30:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:y6gMcmq8YtP48GKw196hHQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
