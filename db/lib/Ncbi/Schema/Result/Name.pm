use utf8;
package Ncbi::Schema::Result::Name;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ncbi::Schema::Result::Name

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<names>

=cut

__PACKAGE__->table("names");

=head1 ACCESSORS

=head2 tax_id

  data_type: 'integer'
  is_nullable: 0

=head2 name_txt

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 unique_name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 name_class

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=cut

__PACKAGE__->add_columns(
  "tax_id",
  { data_type => "integer", is_nullable => 0 },
  "name_txt",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "unique_name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "name_class",
  { data_type => "varchar", is_nullable => 0, size => 50 },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-06-09 10:13:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:C82eCFpWSqe9pl42YCg9qQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
