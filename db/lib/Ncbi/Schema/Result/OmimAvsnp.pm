use utf8;
package Ncbi::Schema::Result::OmimAvsnp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ncbi::Schema::Result::OmimAvsnp - ver. 140604

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<OmimAVSNP>

=cut

__PACKAGE__->table("OmimAVSNP");

=head1 ACCESSORS

=head2 omim_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 locus_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 locus_symbol

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 av_id

  data_type: 'char'
  is_nullable: 0
  size: 4

=head2 av_name

  data_type: 'text'
  is_nullable: 1

=head2 mutation

  data_type: 'varchar'
  is_nullable: 0
  size: 75

=head2 dbsnp

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "omim_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "locus_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "locus_symbol",
  { data_type => "varchar", is_nullable => 0, size => 10 },
  "av_id",
  { data_type => "char", is_nullable => 0, size => 4 },
  "av_name",
  { data_type => "text", is_nullable => 1 },
  "mutation",
  { data_type => "varchar", is_nullable => 0, size => 75 },
  "dbsnp",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-06-09 10:08:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fBUIO2dxUcq8hj54/sxBvg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
