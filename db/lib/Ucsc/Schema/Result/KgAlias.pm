use utf8;
package Ucsc::Schema::Result::KgAlias;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ucsc::Schema::Result::KgAlias

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<kgAlias>

=cut

__PACKAGE__->table("kgAlias");

=head1 ACCESSORS

=head2 kgid

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 40

=head2 alias

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=cut

__PACKAGE__->add_columns(
  "kgid",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 40 },
  "alias",
  { data_type => "varchar", is_nullable => 1, size => 80 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-17 11:21:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YQmLj6klKIIJqzmsCz1/rA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
