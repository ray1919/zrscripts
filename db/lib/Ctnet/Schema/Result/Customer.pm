use utf8;
package Ctnet::Schema::Result::Customer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::Customer

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<customer>

=cut

__PACKAGE__->table("customer");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 tel1

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 tel2

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 tel3

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 im

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 address

  data_type: 'text'
  is_nullable: 1

=head2 organization

  data_type: 'text'
  is_nullable: 1

=head2 source

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 add_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "tel1",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "tel2",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "tel3",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "im",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "address",
  { data_type => "text", is_nullable => 1 },
  "organization",
  { data_type => "text", is_nullable => 1 },
  "source",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "add_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "comment",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 customer_orders

Type: has_many

Related object: L<Ctnet::Schema::Result::CustomerOrder>

=cut

__PACKAGE__->has_many(
  "customer_orders",
  "Ctnet::Schema::Result::CustomerOrder",
  { "foreign.customer_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pcr_services

Type: has_many

Related object: L<Ctnet::Schema::Result::PcrService>

=cut

__PACKAGE__->has_many(
  "pcr_services",
  "Ctnet::Schema::Result::PcrService",
  { "foreign.customer_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 visits

Type: has_many

Related object: L<Ctnet::Schema::Result::Visit>

=cut

__PACKAGE__->has_many(
  "visits",
  "Ctnet::Schema::Result::Visit",
  { "foreign.customer_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 15:38:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VhauMqOIez388go/f9kx4A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
