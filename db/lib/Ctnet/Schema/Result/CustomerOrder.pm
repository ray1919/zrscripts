use utf8;
package Ctnet::Schema::Result::CustomerOrder;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ctnet::Schema::Result::CustomerOrder

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<customer_order>

=cut

__PACKAGE__->table("customer_order");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 customer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 sales

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 price

  data_type: 'float'
  is_nullable: 1

=head2 quantity

  data_type: 'smallint'
  is_nullable: 1

=head2 date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 create_time

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "customer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "sales",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "price",
  { data_type => "float", is_nullable => 1 },
  "quantity",
  { data_type => "smallint", is_nullable => 1 },
  "date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "create_time",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
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
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-05-16 15:23:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PP1H2OcwiOEm3pBOGYomWA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
