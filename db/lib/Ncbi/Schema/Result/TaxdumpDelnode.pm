use utf8;
package Ncbi::Schema::Result::TaxdumpDelnode;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ncbi::Schema::Result::TaxdumpDelnode

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<taxdump_delnodes>

=cut

__PACKAGE__->table("taxdump_delnodes");

=head1 ACCESSORS

=head2 tax_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns("tax_id", { data_type => "integer", is_nullable => 0 });

=head1 PRIMARY KEY

=over 4

=item * L</tax_id>

=back

=cut

__PACKAGE__->set_primary_key("tax_id");


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-11-04 13:47:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8Ivh5sNicVQIq/m454U13A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
