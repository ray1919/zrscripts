use utf8;
package Ncbi::Schema::Result::Gene2refseq;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ncbi::Schema::Result::Gene2refseq - 2013-10-15

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<gene2refseq>

=cut

__PACKAGE__->table("gene2refseq");

=head1 ACCESSORS

=head2 tax_id

  data_type: 'bigint'
  is_nullable: 1

=head2 geneid

  data_type: 'bigint'
  is_nullable: 1

=head2 status

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 rna_acc

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 rna_gi

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 pro_acc

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 pro_gi

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 genomic_acc

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 genomic_gi

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 genomic_start

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 genomic_stop

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 oritation

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 assembly

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 mature_pep_acc

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 mature_pep_gi

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 symbol

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=cut

__PACKAGE__->add_columns(
  "tax_id",
  { data_type => "bigint", is_nullable => 1 },
  "geneid",
  { data_type => "bigint", is_nullable => 1 },
  "status",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "rna_acc",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "rna_gi",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "pro_acc",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "pro_gi",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "genomic_acc",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "genomic_gi",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "genomic_start",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "genomic_stop",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "oritation",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "assembly",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "mature_pep_acc",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "mature_pep_gi",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "symbol",
  { data_type => "varchar", is_nullable => 0, size => 20 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-10-15 15:52:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:p2P6eXA8SwFvJ2dgjUW3zQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
