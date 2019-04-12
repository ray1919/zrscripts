use utf8;
package Ctnet::Schema::Result::PcounterSave;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::PcounterSave

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<pcounter_save>

=cut

__PACKAGE__->table("pcounter_save");

=head1 ACCESSORS

=head2 save_name

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 save_value

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "save_name",
  { data_type => "varchar", is_nullable => 0, size => 10 },
  "save_value",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-08-29 13:29:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:E0v5AQY5bMhchrjevdb/Uw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
