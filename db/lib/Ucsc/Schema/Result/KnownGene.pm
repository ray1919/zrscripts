use utf8;
package Ucsc::Schema::Result::KnownGene;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ucsc::Schema::Result::KnownGene

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<knownGene>

=cut

__PACKAGE__->table("knownGene");

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 chrom

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 strand

  data_type: 'char'
  default_value: (empty string)
  is_nullable: 0
  size: 1

=head2 txstart

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 txend

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 cdsstart

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 cdsend

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 exoncount

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 exonstarts

  data_type: 'longblob'
  is_nullable: 0

=head2 exonends

  data_type: 'longblob'
  is_nullable: 0

=head2 proteinid

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 40

=head2 alignid

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "chrom",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "strand",
  { data_type => "char", default_value => "", is_nullable => 0, size => 1 },
  "txstart",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "txend",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "cdsstart",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "cdsend",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "exoncount",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "exonstarts",
  { data_type => "longblob", is_nullable => 0 },
  "exonends",
  { data_type => "longblob", is_nullable => 0 },
  "proteinid",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 40 },
  "alignid",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-17 11:21:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pbPWsBGK5CGRxKteiiAIng


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
