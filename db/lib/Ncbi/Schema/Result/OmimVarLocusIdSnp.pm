use utf8;
package Ncbi::Schema::Result::OmimVarLocusIdSnp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ncbi::Schema::Result::OmimVarLocusIdSnp

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<OmimVarLocusIdSNP>

=cut

__PACKAGE__->table("OmimVarLocusIdSNP");

=head1 ACCESSORS

=head2 omim_id

  data_type: 'integer'
  is_nullable: 0

=head2 locus_id

  data_type: 'integer'
  is_nullable: 1

=head2 omimvar_id

  data_type: 'char'
  is_nullable: 1
  size: 4

=head2 locus_symbol

  data_type: 'char'
  is_nullable: 1
  size: 10

=head2 var1

  data_type: 'char'
  is_nullable: 1
  size: 20

=head2 aa_position

  data_type: 'integer'
  is_nullable: 1

=head2 var2

  data_type: 'char'
  is_nullable: 1
  size: 20

=head2 var_class

  data_type: 'integer'
  is_nullable: 0

=head2 snp_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "omim_id",
  { data_type => "integer", is_nullable => 0 },
  "locus_id",
  { data_type => "integer", is_nullable => 1 },
  "omimvar_id",
  { data_type => "char", is_nullable => 1, size => 4 },
  "locus_symbol",
  { data_type => "char", is_nullable => 1, size => 10 },
  "var1",
  { data_type => "char", is_nullable => 1, size => 20 },
  "aa_position",
  { data_type => "integer", is_nullable => 1 },
  "var2",
  { data_type => "char", is_nullable => 1, size => 20 },
  "var_class",
  { data_type => "integer", is_nullable => 0 },
  "snp_id",
  { data_type => "integer", is_nullable => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-24 10:41:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ft3qb5OyZzfe2203oDJqOA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
