use utf8;
package Ctnet::Schema::Result::Visit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::Visit

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<visit>

=cut

__PACKAGE__->table("visit");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 customer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 executor

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 way

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 class

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 time

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 return_visit

  data_type: 'tinyint'
  is_nullable: 1

=head2 scheduled

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 create_time

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 create_user_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "customer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "executor",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "way",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "class",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "time",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "return_visit",
  { data_type => "tinyint", is_nullable => 1 },
  "scheduled",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "create_time",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "create_user_id",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 class

Type: belongs_to

Related object: L<Ctnet::Schema::Result::CommunicationClass>

=cut

__PACKAGE__->belongs_to(
  "class",
  "Ctnet::Schema::Result::CommunicationClass",
  { id => "class" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);

=head2 customer

Type: belongs_to

Related object: L<Ctnet::Schema::Result::Customer>

=cut

__PACKAGE__->belongs_to(
  "customer",
  "Ctnet::Schema::Result::Customer",
  { id => "customer_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);

=head3 customer

Type: belongs_to

Related object: L<Ctnet::Schema::Result::Customer>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Ctnet::Schema::Result::UsergroupsUser",
  { id => "create_user_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 15:38:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cFcmdc+Cj9hqsJsR/sQo2A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
