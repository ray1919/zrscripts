#!/usr/bin/perl
# Purpose: Here is a script for gene set enrichment over KEGG, the perl script
# serves as automation for the analysis of several gene set files inside a
# directory, the R script does the analysis itself using bioconductor GOStats
# package.


    use strict;
    use warnings;
my $num_args = $#ARGV + 1;
if ($num_args != 4 ) {
	print "usage: perl BulkEnrichment.pl <Folder containing the Gene List> <Universe> <pvalue_cutoff> <FDR_cutoff> \n";
	exit;
}

    my $dir = $ARGV[0];
    my $universe=$ARGV[1];
    my $pvalue_cutoff = $ARGV[2];
    my $FDR_cutoff = $ARGV[3];

   
   
 my $Enrichment_CMD = "R --slave --vanilla --args $dir $universe $pvalue_cutoff $FDR_cutoff < enrichment.R > LOG";
system($Enrichment_CMD);

exit 0;
