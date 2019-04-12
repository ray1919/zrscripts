use utf8;
package Ncbi::Schema::Result::TaxdumpCitation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ncbi::Schema::Result::TaxdumpCitation

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<taxdump_citations>

=cut

__PACKAGE__->table("taxdump_citations");

=head1 ACCESSORS

=head2 cit_id

  data_type: 'integer'
  is_nullable: 0

=head2 cit_key

  data_type: 'varchar'
  is_nullable: 1
  size: 150

=head2 pubmed_id

  data_type: 'varchar'
  is_nullable: 1
  size: 8

=head2 medline_id

  data_type: 'integer'
  is_nullable: 1

=head2 url

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 text

  data_type: 'text'
  is_nullable: 1

=head2 taxid_list

  data_type: 'mediumtext'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cit_id",
  { data_type => "integer", is_nullable => 0 },
  "cit_key",
  { data_type => "varchar", is_nullable => 1, size => 150 },
  "pubmed_id",
  { data_type => "varchar", is_nullable => 1, size => 8 },
  "medline_id",
  { data_type => "integer", is_nullable => 1 },
  "url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "text",
  { data_type => "text", is_nullable => 1 },
  "taxid_list",
  { data_type => "mediumtext", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cit_id>

=back

=cut

__PACKAGE__->set_primary_key("cit_id");


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-11-04 13:47:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:O8DRd3OMoapXfCpSKepK6A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
