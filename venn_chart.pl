#!/usr/bin/perl
use warnings;
use Carp;
use strict;
use Venn::Chart;

die 'No files input' unless @ARGV > 1;
my ($f1,$f2,$f3) = @ARGV;

open my $fh1, '<', $f1 || die $!;
open my $fh2, '<', $f2 || die $!;
open my $fh3, '<', $f3 if defined $f3;

# Create the Venn::Chart constructor
my $venn_chart = Venn::Chart->new( 600, 600 ) or die("error : $!");

# Set a title and a legend for our chart
$venn_chart->set_options( -title => 'Venn diagram' );
# $venn_chart->set_legends( 'Team 1', 'Team 2', 'Team 3' );
$venn_chart->set_legends( $f1,$f2,$f3 );

# 3 lists for the Venn diagram
my @team1 = <$fh1>;
my @team2 = <$fh2>;
my @team3 = <$fh3> if defined $f3;
map {chomp} (@team1,@team2,@team3);

# Create a diagram with gd object
my $gd_venn = $venn_chart->plot( \@team1, \@team2, \@team3 );

# Create a Venn diagram image in png, gif and jpeg format
open my $fh_venn, '>', 'VennChart.png' or die("Unable to create png file\n");
binmode $fh_venn;
print {$fh_venn} $gd_venn->png;
close $fh_venn or die('Unable to close file');

# Create an histogram image of Venn diagram (png, gif and jpeg format)
# my $gd_histogram = $venn_chart->plot_histogram;
# open my $fh_histo, '>', 'VennHistogram.png' or die("Unable to create png file\n");
# binmode $fh_histo;
# print {$fh_histo} $gd_histogram->png;
# close $fh_histo or die('Unable to close file');

# Get data list for each intersection or unique region between the 3 lists
my @ref_lists = $venn_chart->get_list_regions();
my $list_number = 1;
foreach my $ref_region ( @ref_lists ) {
  print "List $list_number : @{ $ref_region }\n";
  $list_number++;
}
