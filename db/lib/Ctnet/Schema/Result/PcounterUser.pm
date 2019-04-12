use utf8;
package Ctnet::Schema::Result::PcounterUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::PcounterUser

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<pcounter_users>

=cut

__PACKAGE__->table("pcounter_users");

=head1 ACCESSORS

=head2 user_ip

  data_type: 'varchar'
  is_nullable: 0
  size: 39

=head2 user_time

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_ip",
  { data_type => "varchar", is_nullable => 0, size => 39 },
  "user_time",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<user_ip>

=over 4

=item * L</user_ip>

=back

=cut

__PACKAGE__->add_unique_constraint("user_ip", ["user_ip"]);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-08-29 13:29:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4/HPLH3iR6SSY6O4a3Nszg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
