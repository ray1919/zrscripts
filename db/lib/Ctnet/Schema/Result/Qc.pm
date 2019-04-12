use utf8;
package Ctnet::Schema::Result::Qc;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::Qc

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<qc>

=cut

__PACKAGE__->table("qc");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 15

=head2 note

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 15 },
  "note",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-08-26 15:56:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pi9MIERwqUNoI4/x8uTosw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
