use utf8;
package Ctnet::Schema::Result::PcrSample;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::PcrSample

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<PCR_sample>

=cut

__PACKAGE__->table("PCR_sample");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 service_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 species_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 note

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "service_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "species_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "note",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 pcr_experiments

Type: has_many

Related object: L<Ctnet::Schema::Result::PcrExperiment>

=cut

__PACKAGE__->has_many(
  "pcr_experiments",
  "Ctnet::Schema::Result::PcrExperiment",
  { "foreign.sample_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 species

Type: belongs_to

Related object: L<Ctnet::Schema::Result::Species>

=cut

__PACKAGE__->belongs_to(
  "species",
  "Ctnet::Schema::Result::Species",
  { id => "species_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-08-26 15:56:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:du+c2ZI8w71l/dLh2RpmGw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
