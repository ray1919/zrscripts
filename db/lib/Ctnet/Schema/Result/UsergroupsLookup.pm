use utf8;
package Ctnet::Schema::Result::UsergroupsLookup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::UsergroupsLookup

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<usergroups_lookup>

=cut

__PACKAGE__->table("usergroups_lookup");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 element

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 value

  data_type: 'integer'
  is_nullable: 1

=head2 text

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "element",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "value",
  { data_type => "integer", is_nullable => 1 },
  "text",
  { data_type => "varchar", is_nullable => 1, size => 40 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-05-16 15:23:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mNv5GYOay0YDg+SiBkh/jA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
