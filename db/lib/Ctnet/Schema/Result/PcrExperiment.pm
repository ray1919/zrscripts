use utf8;
package Ctnet::Schema::Result::PcrExperiment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::PcrExperiment

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<PCR_experiment>

=cut

__PACKAGE__->table("PCR_experiment");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 gene_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 primer_id

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 primer_fk

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 ct

  data_type: 'float'
  is_nullable: 1

=head2 tm1

  data_type: 'float'
  is_nullable: 1

=head2 tm2

  data_type: 'float'
  is_nullable: 1

=head2 service_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 array_name

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 pos

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 plate_type

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 sample_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "gene_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "primer_id",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "primer_fk",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "ct",
  { data_type => "float", is_nullable => 1 },
  "tm1",
  { data_type => "float", is_nullable => 1 },
  "tm2",
  { data_type => "float", is_nullable => 1 },
  "service_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "array_name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "pos",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "plate_type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "sample_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 gene

Type: belongs_to

Related object: L<Ctnet::Schema::Result::Gene>

=cut

__PACKAGE__->belongs_to(
  "gene",
  "Ctnet::Schema::Result::Gene",
  { gene_id => "gene_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 primer_fk

Type: belongs_to

Related object: L<Ctnet::Schema::Result::Primer>

=cut

__PACKAGE__->belongs_to(
  "primer_fk",
  "Ctnet::Schema::Result::Primer",
  { id => "primer_fk" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);

=head2 sample

Type: belongs_to

Related object: L<Ctnet::Schema::Result::PcrSample>

=cut

__PACKAGE__->belongs_to(
  "sample",
  "Ctnet::Schema::Result::PcrSample",
  { id => "sample_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 service

Type: belongs_to

Related object: L<Ctnet::Schema::Result::PcrService>

=cut

__PACKAGE__->belongs_to(
  "service",
  "Ctnet::Schema::Result::PcrService",
  { id => "service_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 15:38:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:t1WNOoWeCWBxg0/W79qR4w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
