use utf8;
package Ctnet::Schema::Result::UsergroupsConfiguration;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::UsergroupsConfiguration

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<usergroups_configuration>

=cut

__PACKAGE__->table("usergroups_configuration");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 rule

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 value

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 options

  data_type: 'text'
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "rule",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "value",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "options",
  { data_type => "text", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-05-16 15:23:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lHxNaO9dMvMQc/Gj91PRWA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
