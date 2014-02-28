#!/usr/bin/env perl
# Date: 2014-02-13
# Author: Zhao
# Purpose: 把Typer Analyzer导出的XML文件parse出来。

use 5.012;
use XML::Simple;
use Data::Dump qw/dump/;
use Data::Table;
use Excel::Writer::XLSX;
use Smart::Comments;

my $book = Excel::Writer::XLSX->new("massarray_plate.xlsx");
my $format = $book->add_format();
$format->set_font('Verdana');
$format->set_align("left");
$format->set_size(10);
my $format2 = $book->add_format();
$format2->set_font('Verdana');
$format2->set_align("left");
$format2->set_size(10);
$format2->set_bold();

readcsv();
readxml();

$book->close();

### done

sub readcsv {
  my @csvs = glob "*.csv";
  foreach my $csv_file (@csvs) {
    # original table
    my $t = Data::Table::fromCSV($csv_file,1,undef,{skip_lines=>7});
    my $sheet1 = $book->add_worksheet("Original table");
    $sheet1->write_row( 'A1', [$t->header], $format2 );
    $sheet1->write_col( 'A2', $$t{'data'}, $format );
    # pivot table
    my $pt = $t->pivot("Sample",1,"Genotype",["Assay"],0);
    my $sheet2 = $book->add_worksheet("Pivot table");
    $sheet2->write_row( 'A1', [$pt->header], $format2 );
    $sheet2->write_col( 'A2', $$pt{'data'}, $format );
    # determine how many samples:
    my $sheet3 = $book->add_worksheet("Sample table");
    my @samples = $pt->header;
    $sheet3->write_col('A1',["$#samples samples",@samples[1..$#samples]],$format);
    # determine how many variations are included in the assays:
    my $sheet4 = $book->add_worksheet("Variation table");
    my @assays = $pt->col('Assay');
    $sheet4->write_col('A1',[($#assays+1)." variations",@assays],$format);

    # Identify trouble variation assays. list all variations that has NA call. Calculate the percentage of the NA calls among all samples.
    my $t_na = $t->match_pattern_hash('$_{"Genotype"} eq "NA"');
    my $t_na_group = $t_na->group(['Assay'],['Genotype','Genotype'],
      [sub {scalar @_},sub {int(scalar @_ / $#samples * 100000)/1000}],['NA cnt','NA %'],0);
    $t_na_group->sort('NA %',0,1);
    my $sheet5 = $book->add_worksheet("Trouble variation assays");
    $sheet5->write_row( 'A1', [$t_na_group->header], $format2 );
    $sheet5->write_col( 'A2', $$t_na_group{'data'}, $format );
    
    # Overall quality analysis (the number of A, B, C, D, N, I)
    my $t_gt_group = $t->group(['Description'],['Assay','Assay'],
      [sub {scalar @_},sub {int(scalar @_ / $t->nofRow * 100000)/1000}],['Cnt','%'],0);
    $t_gt_group->sort('Description',1,0);
    my $sheet6 = $book->add_worksheet("Overall quality");
    $sheet6->write_row( 'A1', [$t_gt_group->header], $format2 );
    $sheet6->write_col( 'A2', $$t_gt_group{'data'}, $format );

    # List the quality of each variation
    my $t_vgt_group = $t->group(['Assay','Description'],['Sample','Sample'],
      [sub {scalar @_},sub {int(scalar @_ / $#samples * 100000)/1000}],['Count','%'],0);
    $t_vgt_group->sort('Assay',1,0,'Description',1,0);
    my $sheet7 = $book->add_worksheet("Quality of each variation");
    $sheet7->write_row( 'A1', [$t_vgt_group->header], $format2 );
    $sheet7->write_col( 'A2', $$t_vgt_group{'data'}, $format );

    # Do sample_id vs number of NA analysis. This analysis can be used to see whether some samples generate significantly more NAs than other samples do.
    my $t_sna_group = $t_na->group(['Sample'],['Genotype','Genotype'],
      [sub {scalar @_},sub {int(scalar @_ / ($#assays+1) * 100000)/1000}],['NA Count','NA %'],0);
    $t_sna_group->sort('NA %',0,1);
    my $sheet8 = $book->add_worksheet("Quality by samples");
    $sheet8->write_row( 'A1', [$t_sna_group->header], $format2 );
    $sheet8->write_col( 'A2', $$t_sna_group{'data'}, $format );

    # examine genotype frequency of each variation
    my $t_nna = $t->match_pattern_hash('$_{"Genotype"} ne "NA"');
    my $t_vnna_group = $t_nna->group(['Assay','Genotype'],['Sample','Sample'],
      [sub {scalar @_},sub {int(scalar @_ / $#samples * 100000)/1000}],['Count','%'],0);
    $t_vnna_group->sort('Assay',1,0,'Count',0,1);
    my $sheet9 = $book->add_worksheet("Genotype distribution");
    $sheet9->write_row( 'A1', [$t_vnna_group->header], $format2 );
    $sheet9->write_col( 'A2', $$t_vnna_group{'data'}, $format );

    # genotype count per assay
    my $t_vnna_cnt_group = $t_vnna_group->group(['Assay'],['Genotype','Genotype'],
      [sub {scalar @_},sub {join ',', @_}],['Genotype Count','Genotypes'],0);
    $t_vnna_cnt_group->sort('Assay',1,0,);
    my $sheet0 = $book->add_worksheet("Assay genotype ");
    $sheet0->write_row( 'A1', [$t_vnna_cnt_group->header], $format2 );
    $sheet0->write_col( 'A2', $$t_vnna_cnt_group{'data'}, $format );
    last;
  }
}

sub readxml {
  my @xmls = glob "*.xml";
  foreach my $xml_file (@xmls) {
    ### reading : $xml_file
    my $ref = XMLin($xml_file);
    
    my %chip = %{$$ref{'typeranalyzer'}};
    ### records
    my @records = @{$chip{'all-records'}{'record'}};
    my $chip = $chip{'chip'};
    my $retbl = new Data::Table([], [sort keys $records[0]], Data::Table::ROW_BASED);
    map {$retbl->addRow($records[$_])} 0 .. $#records;
    my $sheet = $book->add_worksheet($chip);
    $sheet->write_row( 'A1', [$retbl->header], $format2 );
    $sheet->write_col( 'A2', $$retbl{'data'}, $format );
    return;
    
    ### spectra # NOT PRATICAL
    my @spectra = @{$chip{'all-spectra'}{'spectrum'}};
    open my $fh, '>', "$chip.spectrum.txt";
    say $fh "spectrum";
    map {say $fh join("\t",${$spectra[$_]}{'well-position'},${$spectra[$_]}{'content'})} 0 .. $#spectra;
    close $fh;
  }
}

sub sheet_name {
  my $name = shift;
  my $suffix = shift || '';
  if (length($name) + length($suffix) > 31) {
    $name = substr($name,0,31-length($suffix));
  }
  return $name.$suffix;
}
