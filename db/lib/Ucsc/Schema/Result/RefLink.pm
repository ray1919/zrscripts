use utf8;
package Ucsc::Schema::Result::RefLink;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ucsc::Schema::Result::RefLink

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<refLink>

=cut

__PACKAGE__->table("refLink");

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 product

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 mrnaacc

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 protacc

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 genename

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 prodname

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 locuslinkid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 omimid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "product",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "mrnaacc",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "protacc",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "genename",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "prodname",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "locuslinkid",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "omimid",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</mrnaacc>

=back

=cut

__PACKAGE__->set_primary_key("mrnaacc");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-19 11:21:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YUHiclHn+iL0EE/mWd4n3w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
