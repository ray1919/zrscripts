-- MySQL dump 10.13  Distrib 5.7.25, for Linux (x86_64)
--
-- Host: localhost    Database: ncbi
-- ------------------------------------------------------
-- Server version	5.7.25-0ubuntu0.16.04.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `OmimAVSNP`
--

DROP TABLE IF EXISTS `OmimAVSNP`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `OmimAVSNP` (
  `omim_id` int(11) unsigned NOT NULL,
  `locus_id` int(10) unsigned NOT NULL,
  `locus_symbol` varchar(10) NOT NULL,
  `av_id` char(4) NOT NULL,
  `av_name` text,
  `mutation` varchar(75) NOT NULL,
  `dbsnp` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='ver. 150902';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `OmimVarLocusIdSNP`
--

DROP TABLE IF EXISTS `OmimVarLocusIdSNP`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `OmimVarLocusIdSNP` (
  `omim_id` int(11) NOT NULL,
  `locus_id` int(11) DEFAULT NULL,
  `omimvar_id` char(4) DEFAULT NULL,
  `locus_symbol` char(10) DEFAULT NULL,
  `var1` char(20) DEFAULT NULL,
  `aa_position` int(11) DEFAULT NULL,
  `var2` char(20) DEFAULT NULL,
  `var_class` int(11) NOT NULL,
  `snp_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `clinvar`
--

DROP TABLE IF EXISTS `clinvar`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `clinvar` (
  `clinvar_id` int(11) NOT NULL,
  `clinvar_acc` char(12) NOT NULL,
  `title` text NOT NULL,
  `phenotype` varchar(150) NOT NULL,
  `gene_id` int(11) DEFAULT NULL,
  `omim_id` int(11) DEFAULT NULL,
  `hgvs` text,
  `omim_av` varchar(120) DEFAULT NULL,
  `dbsnp` varchar(40) DEFAULT NULL,
  `cli_sig` varchar(50) DEFAULT NULL,
  `sl_acc` varchar(20) DEFAULT NULL,
  `sl_ass` varchar(12) DEFAULT NULL,
  `sl_chr` varchar(20) DEFAULT NULL,
  `sl_start` int(11) DEFAULT NULL,
  `sl_stop` int(11) DEFAULT NULL,
  `type` varchar(25) NOT NULL,
  KEY `gene_id` (`gene_id`),
  KEY `omim_av` (`omim_av`),
  KEY `dbsnp` (`dbsnp`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='2018-09 update';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `clinvar_citation`
--

DROP TABLE IF EXISTS `clinvar_citation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `clinvar_citation` (
  `clinvar_id` int(11) NOT NULL,
  `citation` text NOT NULL,
  KEY `clinvar_id` (`clinvar_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gene2accession`
--

DROP TABLE IF EXISTS `gene2accession`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gene2accession` (
  `tax_id` int(10) unsigned NOT NULL DEFAULT '0',
  `GeneID` varchar(32) NOT NULL DEFAULT '',
  `status` varchar(16) NOT NULL DEFAULT '',
  `RNA_nucleotide_accession` varchar(32) NOT NULL DEFAULT '',
  `RNA_nucleotide_gi` varchar(32) NOT NULL DEFAULT '',
  `protein_accession` varchar(32) NOT NULL DEFAULT '',
  `protein_gi` varchar(32) NOT NULL DEFAULT '',
  `genomic_nucleotide_accession` varchar(32) NOT NULL DEFAULT '',
  `genomic_nucleotide_gi` varchar(32) NOT NULL DEFAULT '',
  `start_position` bigint(32) unsigned DEFAULT '0',
  `end_position` bigint(32) unsigned DEFAULT '0',
  `orientation` char(1) NOT NULL DEFAULT '',
  `assembly` varchar(64) NOT NULL DEFAULT '',
  `mature_peptide_accession` varchar(32) NOT NULL DEFAULT '',
  `mature_peptide_gi` varchar(32) NOT NULL DEFAULT '',
  `Symbol` varchar(32) NOT NULL DEFAULT '',
  KEY `index_geneid` (`GeneID`),
  KEY `index_accession` (`protein_accession`),
  KEY `index_protein_gi` (`protein_gi`),
  KEY `index_genomic_nucleotide_gi` (`genomic_nucleotide_gi`),
  KEY `index_RNA_nucleotide_gi` (`RNA_nucleotide_gi`),
  KEY `index_tax_id` (`tax_id`),
  KEY `start_position_end_position` (`start_position`,`end_position`),
  KEY `assembly` (`assembly`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gene2refseq`
--

DROP TABLE IF EXISTS `gene2refseq`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gene2refseq` (
  `tax_id` bigint(20) DEFAULT NULL,
  `geneid` bigint(20) DEFAULT NULL,
  `status` varchar(20) NOT NULL,
  `rna_acc` varchar(20) NOT NULL,
  `rna_gi` varchar(20) NOT NULL,
  `pro_acc` varchar(20) NOT NULL,
  `pro_gi` varchar(20) NOT NULL,
  `genomic_acc` varchar(20) NOT NULL,
  `genomic_gi` varchar(20) NOT NULL,
  `genomic_start` varchar(20) NOT NULL,
  `genomic_stop` varchar(20) NOT NULL,
  `oritation` varchar(20) NOT NULL,
  `assembly` varchar(20) NOT NULL,
  `mature_pep_acc` varchar(20) NOT NULL,
  `mature_pep_gi` varchar(20) NOT NULL,
  `symbol` varchar(20) NOT NULL,
  KEY `tax_id` (`tax_id`),
  KEY `geneid` (`geneid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='2013-10-15';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gene_info`
--

DROP TABLE IF EXISTS `gene_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gene_info` (
  `tax_id` int(11) NOT NULL,
  `GeneID` int(11) NOT NULL,
  `Symbol` varchar(50) NOT NULL,
  `LocusTag` varchar(20) NOT NULL,
  `Synonyms` text NOT NULL,
  `dbXrefs` text NOT NULL,
  `chromosome` varchar(20) NOT NULL,
  `map_location` varchar(50) NOT NULL,
  `description` text NOT NULL,
  `type_of_gene` varchar(30) NOT NULL,
  `Symbol_from_nomenclature_authority` varchar(50) NOT NULL,
  `Full_name_from_nomenclature_authority` text NOT NULL,
  `Nomenclature_status` varchar(30) NOT NULL,
  `Other_designations` text NOT NULL,
  `Modification_date` date NOT NULL,
  `Feature_type` text NOT NULL,
  PRIMARY KEY (`GeneID`),
  KEY `Symbol` (`Symbol`),
  KEY `tax_id` (`tax_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gene_info.old`
--

DROP TABLE IF EXISTS `gene_info.old`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gene_info.old` (
  `tax_id` int(11) NOT NULL,
  `GeneID` int(11) unsigned NOT NULL,
  `Symbol` varchar(100) DEFAULT NULL,
  `LocusTag` varchar(200) DEFAULT NULL,
  `Synonyms` text,
  `dbXrefs` text,
  `chromosome` varchar(20) DEFAULT NULL,
  `map_location` varchar(50) DEFAULT NULL,
  `description` text,
  `type_of_gene` varchar(50) DEFAULT NULL,
  `Symbol_from_nomenclature_authority` varchar(200) DEFAULT NULL,
  `Full_name_from_nomenclature_authority` text,
  `Nomenclature_status` varchar(200) DEFAULT NULL,
  `Other_designations` text,
  `Modification_date` date DEFAULT NULL,
  PRIMARY KEY (`GeneID`),
  KEY `Symbol` (`Symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='2017-02-05';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mirtarbase`
--

DROP TABLE IF EXISTS `mirtarbase`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mirtarbase` (
  `mirtarbase id` varchar(10) NOT NULL,
  `mirna` varchar(18) NOT NULL,
  `species_mirna` varchar(37) NOT NULL,
  `target_gene` varchar(16) NOT NULL,
  `target_gene_id` int(10) unsigned DEFAULT NULL,
  `species_gene` varchar(37) NOT NULL,
  `experiments` varchar(152) NOT NULL,
  `support_type` varchar(25) NOT NULL,
  `reference` varchar(9) NOT NULL,
  KEY `mirna` (`mirna`),
  KEY `species_mirna` (`species_mirna`),
  KEY `species_gene` (`species_gene`),
  KEY `support_type` (`support_type`),
  KEY `target_gene_id` (`target_gene_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='MTI_4.5';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `names`
--

DROP TABLE IF EXISTS `names`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `names` (
  `tax_id` int(11) NOT NULL,
  `name_txt` varchar(100) NOT NULL,
  `unique_name` varchar(100) NOT NULL,
  `name_class` varchar(50) NOT NULL,
  KEY `tax_id` (`tax_id`),
  KEY `name_txt` (`name_txt`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `snp_genes`
--

DROP TABLE IF EXISTS `snp_genes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `snp_genes` (
  `snp_rs` varchar(20) DEFAULT NULL,
  `gene_id` varchar(20) DEFAULT NULL,
  KEY `gene_id` (`gene_id`),
  KEY `snp_rs` (`snp_rs`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taxdump_citations`
--

DROP TABLE IF EXISTS `taxdump_citations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `taxdump_citations` (
  `cit_id` int(11) NOT NULL,
  `cit_key` varchar(150) DEFAULT NULL,
  `pubmed_id` varchar(8) DEFAULT NULL,
  `medline_id` int(11) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `text` text,
  `taxid_list` mediumtext,
  PRIMARY KEY (`cit_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taxdump_delnodes`
--

DROP TABLE IF EXISTS `taxdump_delnodes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `taxdump_delnodes` (
  `tax_id` int(11) NOT NULL,
  PRIMARY KEY (`tax_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taxdump_division`
--

DROP TABLE IF EXISTS `taxdump_division`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `taxdump_division` (
  `division_id` int(11) NOT NULL,
  `division_cde` char(3) NOT NULL,
  `division_name` varchar(21) NOT NULL,
  `comments` varchar(56) NOT NULL,
  PRIMARY KEY (`division_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taxdump_gencode`
--

DROP TABLE IF EXISTS `taxdump_gencode`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `taxdump_gencode` (
  `genetic_code_id` int(11) NOT NULL,
  `abbreviation` varchar(45) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `cde` varchar(65) NOT NULL,
  `starts` varchar(65) NOT NULL,
  PRIMARY KEY (`genetic_code_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taxdump_gi_fosn`
--

DROP TABLE IF EXISTS `taxdump_gi_fosn`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `taxdump_gi_fosn` (
  `gi` bigint(20) unsigned NOT NULL,
  `fosn` varchar(50) NOT NULL,
  KEY `gi` (`gi`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taxdump_gi_taxid_nucl`
--

DROP TABLE IF EXISTS `taxdump_gi_taxid_nucl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `taxdump_gi_taxid_nucl` (
  `gi` bigint(20) unsigned NOT NULL,
  `tax_id` int(11) NOT NULL,
  KEY `tax_id` (`tax_id`),
  KEY `gi` (`gi`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taxdump_merged`
--

DROP TABLE IF EXISTS `taxdump_merged`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `taxdump_merged` (
  `old_tax_id` int(11) NOT NULL,
  `new_tax_id` int(11) NOT NULL,
  PRIMARY KEY (`old_tax_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taxdump_names`
--

DROP TABLE IF EXISTS `taxdump_names`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `taxdump_names` (
  `tax_id` int(11) NOT NULL,
  `name_txt` varchar(180) NOT NULL,
  `unique_name` varchar(100) DEFAULT NULL,
  `name_class` varchar(20) NOT NULL,
  KEY `tax_id` (`tax_id`),
  KEY `name_class` (`name_class`),
  KEY `name_txt` (`name_txt`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taxdump_nodes`
--

DROP TABLE IF EXISTS `taxdump_nodes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `taxdump_nodes` (
  `tax_id` int(11) NOT NULL,
  `parent_tax_id` int(11) NOT NULL,
  `rank` varchar(16) NOT NULL,
  `embl_code` char(2) NOT NULL,
  `division_id` int(11) DEFAULT NULL,
  `inherited_div_flag` tinyint(1) NOT NULL,
  `genetic_code_id` int(11) NOT NULL,
  `inherited_GC_flag` tinyint(1) NOT NULL,
  `mitochondrial_genetic_code_id` int(11) NOT NULL,
  `inherited_MGC_flag` tinyint(1) NOT NULL,
  `GenBank_hidden_flag` tinyint(1) NOT NULL,
  `hidden_subtree_root_flag` tinyint(1) NOT NULL,
  `comments` varchar(20) NOT NULL,
  PRIMARY KEY (`tax_id`),
  KEY `division_id` (`division_id`),
  KEY `genetic_code_id` (`genetic_code_id`),
  KEY `mitochondrial_genetic_code_id` (`mitochondrial_genetic_code_id`),
  KEY `parent_tax_id` (`parent_tax_id`),
  CONSTRAINT `taxdump_nodes_ibfk_1` FOREIGN KEY (`division_id`) REFERENCES `taxdump_division` (`division_id`),
  CONSTRAINT `taxdump_nodes_ibfk_2` FOREIGN KEY (`genetic_code_id`) REFERENCES `taxdump_gencode` (`genetic_code_id`),
  CONSTRAINT `taxdump_nodes_ibfk_3` FOREIGN KEY (`mitochondrial_genetic_code_id`) REFERENCES `taxdump_gencode` (`genetic_code_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-04-16 11:15:52
