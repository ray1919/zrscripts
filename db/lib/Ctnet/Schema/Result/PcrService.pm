use utf8;
package Ctnet::Schema::Result::PcrService;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::PcrService

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<PCR_service>

=cut

__PACKAGE__->table("PCR_service");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 customer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 service_type

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 sample_arrival_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 report_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 note

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "customer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "service_type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "sample_arrival_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "report_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
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

=head2 customer

Type: belongs_to

Related object: L<Ctnet::Schema::Result::Customer>

=cut

__PACKAGE__->belongs_to(
  "customer",
  "Ctnet::Schema::Result::Customer",
  { id => "customer_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 pcr_experiments

Type: has_many

Related object: L<Ctnet::Schema::Result::PcrExperiment>

=cut

__PACKAGE__->has_many(
  "pcr_experiments",
  "Ctnet::Schema::Result::PcrExperiment",
  { "foreign.service_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pcr_samples

Type: has_many

Related object: L<Ctnet::Schema::Result::PcrSample>

=cut

__PACKAGE__->has_many(
  "pcr_samples",
  "Ctnet::Schema::Result::PcrSample",
  { "foreign.service_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 15:38:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:y8adjekuRPycwSIRS49lyw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
