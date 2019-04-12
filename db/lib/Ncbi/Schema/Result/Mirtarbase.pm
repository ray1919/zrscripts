use utf8;
package Ncbi::Schema::Result::Mirtarbase;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ncbi::Schema::Result::Mirtarbase - MTI_4.5

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<mirtarbase>

=cut

__PACKAGE__->table("mirtarbase");

=head1 ACCESSORS

=head2 mirtarbase id

  accessor: 'mirtarbase_id'
  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 mirna

  data_type: 'varchar'
  is_nullable: 0
  size: 18

=head2 species_mirna

  data_type: 'varchar'
  is_nullable: 0
  size: 37

=head2 target_gene

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=head2 target_gene_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 species_gene

  data_type: 'varchar'
  is_nullable: 0
  size: 37

=head2 experiments

  data_type: 'varchar'
  is_nullable: 0
  size: 152

=head2 support_type

  data_type: 'varchar'
  is_nullable: 0
  size: 25

=head2 reference

  data_type: 'varchar'
  is_nullable: 0
  size: 9

=cut

__PACKAGE__->add_columns(
  "mirtarbase id",
  {
    accessor => "mirtarbase_id",
    data_type => "varchar",
    is_nullable => 0,
    size => 10,
  },
  "mirna",
  { data_type => "varchar", is_nullable => 0, size => 18 },
  "species_mirna",
  { data_type => "varchar", is_nullable => 0, size => 37 },
  "target_gene",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "target_gene_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "species_gene",
  { data_type => "varchar", is_nullable => 0, size => 37 },
  "experiments",
  { data_type => "varchar", is_nullable => 0, size => 152 },
  "support_type",
  { data_type => "varchar", is_nullable => 0, size => 25 },
  "reference",
  { data_type => "varchar", is_nullable => 0, size => 9 },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-06-09 10:13:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:awVmHkMuwCU/ANb8+OneoA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
