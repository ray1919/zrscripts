use utf8;
package Ncbi::Schema::Result::TaxdumpMerged;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ncbi::Schema::Result::TaxdumpMerged

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<taxdump_merged>

=cut

__PACKAGE__->table("taxdump_merged");

=head1 ACCESSORS

=head2 old_tax_id

  data_type: 'integer'
  is_nullable: 0

=head2 new_tax_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "old_tax_id",
  { data_type => "integer", is_nullable => 0 },
  "new_tax_id",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</old_tax_id>

=back

=cut

__PACKAGE__->set_primary_key("old_tax_id");


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-11-04 13:47:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WW1d7j3A9AcXrH/8ftBaGA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
