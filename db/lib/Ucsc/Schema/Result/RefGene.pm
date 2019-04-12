use utf8;
package Ucsc::Schema::Result::RefGene;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ucsc::Schema::Result::RefGene

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<refGene>

=cut

__PACKAGE__->table("refGene");

=head1 ACCESSORS

=head2 bin

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 chrom

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 strand

  data_type: 'char'
  is_nullable: 0
  size: 1

=head2 txstart

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 txend

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 cdsstart

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 cdsend

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 exoncount

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 exonstarts

  data_type: 'longblob'
  is_nullable: 0

=head2 exonends

  data_type: 'longblob'
  is_nullable: 0

=head2 score

  data_type: 'integer'
  is_nullable: 1

=head2 name2

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 cdsstartstat

  data_type: 'enum'
  extra: {list => ["none","unk","incmpl","cmpl"]}
  is_nullable: 0

=head2 cdsendstat

  data_type: 'enum'
  extra: {list => ["none","unk","incmpl","cmpl"]}
  is_nullable: 0

=head2 exonframes

  data_type: 'longblob'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "bin",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "chrom",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "strand",
  { data_type => "char", is_nullable => 0, size => 1 },
  "txstart",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "txend",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "cdsstart",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "cdsend",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "exoncount",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "exonstarts",
  { data_type => "longblob", is_nullable => 0 },
  "exonends",
  { data_type => "longblob", is_nullable => 0 },
  "score",
  { data_type => "integer", is_nullable => 1 },
  "name2",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "cdsstartstat",
  {
    data_type => "enum",
    extra => { list => ["none", "unk", "incmpl", "cmpl"] },
    is_nullable => 0,
  },
  "cdsendstat",
  {
    data_type => "enum",
    extra => { list => ["none", "unk", "incmpl", "cmpl"] },
    is_nullable => 0,
  },
  "exonframes",
  { data_type => "longblob", is_nullable => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-19 11:21:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sVL66Q/t+Y95LUk90acD4A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
