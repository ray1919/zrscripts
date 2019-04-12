use utf8;
package Ncbi::Schema::Result::SnpGene;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ncbi::Schema::Result::SnpGene

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<snp_genes>

=cut

__PACKAGE__->table("snp_genes");

=head1 ACCESSORS

=head2 snp_rs

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 gene_id

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  "snp_rs",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "gene_id",
  { data_type => "varchar", is_nullable => 1, size => 20 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-17 08:50:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gaqH52VQrBe0zmZjG5N8YQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
