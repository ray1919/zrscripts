use utf8;
package Ncbi::Schema::Result::GeneInfo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ncbi::Schema::Result::GeneInfo

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<gene_info>

=cut

__PACKAGE__->table("gene_info");

=head1 ACCESSORS

=head2 tax_id

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 geneid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 symbol

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 locustag

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 synonyms

  data_type: 'text'
  is_nullable: 1

=head2 dbxrefs

  data_type: 'text'
  is_nullable: 1

=head2 chromosome

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 map_location

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 type_of_gene

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 symbol_from_nomenclature_authority

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 full_name_from_nomenclature_authority

  data_type: 'text'
  is_nullable: 1

=head2 nomenclature_status

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 other_designations

  data_type: 'text'
  is_nullable: 1

=head2 modification_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "tax_id",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "geneid",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "symbol",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "locustag",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "synonyms",
  { data_type => "text", is_nullable => 1 },
  "dbxrefs",
  { data_type => "text", is_nullable => 1 },
  "chromosome",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "map_location",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "type_of_gene",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "symbol_from_nomenclature_authority",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "full_name_from_nomenclature_authority",
  { data_type => "text", is_nullable => 1 },
  "nomenclature_status",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "other_designations",
  { data_type => "text", is_nullable => 1 },
  "modification_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</geneid>

=back

=cut

__PACKAGE__->set_primary_key("geneid");


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-06-09 10:13:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UDTUk/3F9yzoXQglCxggxQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
