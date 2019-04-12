use utf8;
package Ncbi::Schema::Result::ClinvarCitation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ncbi::Schema::Result::ClinvarCitation

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<clinvar_citation>

=cut

__PACKAGE__->table("clinvar_citation");

=head1 ACCESSORS

=head2 clinvar_id

  data_type: 'integer'
  is_nullable: 0

=head2 citation

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "clinvar_id",
  { data_type => "integer", is_nullable => 0 },
  "citation",
  { data_type => "text", is_nullable => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-10-15 15:52:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xy5ziiH9Z+35McB2y/+ZUQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
