use utf8;
package Ucsc::Schema::Result::KgXref;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ucsc::Schema::Result::KgXref

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<kgXref>

=cut

__PACKAGE__->table("kgXref");

=head1 ACCESSORS

=head2 kgid

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 mrna

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 spid

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 spdisplayid

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 genesymbol

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 refseq

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 protacc

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 description

  data_type: 'longblob'
  is_nullable: 0

=head2 rfamacc

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 trnaname

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "kgid",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "mrna",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "spid",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "spdisplayid",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "genesymbol",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "refseq",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "protacc",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "description",
  { data_type => "longblob", is_nullable => 0 },
  "rfamacc",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "trnaname",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-17 11:21:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:d1MA8XrIgoX605ttZWGESg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
