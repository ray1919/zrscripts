use utf8;
package Ncbi::Schema::Result::TaxdumpGiFosn;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ncbi::Schema::Result::TaxdumpGiFosn

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<taxdump_gi_fosn>

=cut

__PACKAGE__->table("taxdump_gi_fosn");

=head1 ACCESSORS

=head2 gi

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 fosn

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=cut

__PACKAGE__->add_columns(
  "gi",
  { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 0 },
  "fosn",
  { data_type => "varchar", is_nullable => 0, size => 50 },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-11-04 13:47:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nA5QemtZeJWpDZpKHzfBaA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
