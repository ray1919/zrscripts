use utf8;
package Ctnet::Schema::Result::UsergroupsCron;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::UsergroupsCron

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<usergroups_cron>

=cut

__PACKAGE__->table("usergroups_cron");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 lapse

  data_type: 'integer'
  is_nullable: 1

=head2 last_occurrence

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "lapse",
  { data_type => "integer", is_nullable => 1 },
  "last_occurrence",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-05-16 15:23:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7gnzdqWNVYGDdaJif0po+g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
