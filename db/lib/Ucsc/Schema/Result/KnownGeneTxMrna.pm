use utf8;
package Ucsc::Schema::Result::KnownGeneTxMrna;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ucsc::Schema::Result::KnownGeneTxMrna

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<knownGeneTxMrna>

=cut

__PACKAGE__->table("knownGeneTxMrna");

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 seq

  data_type: 'longblob'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "seq",
  { data_type => "longblob", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->set_primary_key("name");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-17 11:21:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zv8hoZSMdcZq3wXP3VviSg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
