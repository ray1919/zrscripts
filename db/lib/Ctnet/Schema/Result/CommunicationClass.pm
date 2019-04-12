use utf8;
package Ctnet::Schema::Result::CommunicationClass;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::CommunicationClass

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<communication_class>

=cut

__PACKAGE__->table("communication_class");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 class

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "class",
  { data_type => "varchar", is_nullable => 0, size => 45 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 visits

Type: has_many

Related object: L<Ctnet::Schema::Result::Visit>

=cut

__PACKAGE__->has_many(
  "visits",
  "Ctnet::Schema::Result::Visit",
  { "foreign.class" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 15:38:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6c7oH8uvWx3aF1zAyCAh4Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
