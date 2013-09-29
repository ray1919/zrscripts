sink("log", append = FALSE, type = c("output", "message"), split = FALSE)
library(GOstats)
library(EMA)
library(fdrtool)
library(org.Pt.eg.db)

Args <- commandArgs()

UNIV <- Args[6]
# GL <- Args[5]
DIR <- Args[5]
PVCUT <- Args[7]
FDRcut <- Args[8]

# sprintf('%s','%s','PROCESSING PLEASE WAIT...','\n')

ALLFILES <- list.files(toString(DIR))

# ,pattern='^H11_'

i <- 1
universe <- read.table(toString(UNIV), sep = "\t", header = FALSE)
while (i <= length(ALLFILES)) {
  if (file.info(paste(toString(DIR), "/", toString(ALLFILES[i]), sep = "", collapse = NULL))$size == 0) {
    i <- i + 1
    next
  }
  inGenes <- read.table(paste(toString(DIR), "/", toString(ALLFILES[i]), sep = "", collapse = NULL), sep = "\t", 
                        header = FALSE)
  if (nrow(inGenes) < 7) {
    i <- i + 1
    next
  }
  OUTFILE <- paste(toString(DIR), "/", toString(ALLFILES[i]), ".ENR", sep = "", collapse = NULL)
  selected <- unique(inGenes$V1)
  paramK <- new("KEGGHyperGParams", geneIds = selected, universeGeneIds = universe, annotation = "org.Hs.eg.db", 
                pvalueCutoff = as.numeric(PVCUT), testDirection = "over")
  hypK <- hyperGTest(paramK)
  sumTableK <- summary(hypK)
  
  
  # subset the output table to get the columns of interest
  
  # (GO ID, GO description, p-value) (KEGG ID, KEGG description, p-value)
  
  outK <- subset(sumTableK, select = c(1, 7, 2))
  
  # cat(outK$KEGGID)
  
  # retrieve input genes associated witsourceh each KEGG identifier
  
  # use the org.Hs.eg data mapping to get KEGG terms for each ID
  
  
  if (length(outK$KEGGID) >= 2) {
    keggMaps <- lapply(outK$KEGGID, function(x) unlist(mget(x, org.Hs.egPATH2EG)))
    
    # subset the selected genes based on those in the mappings
    
    keggSelected <- lapply(keggMaps, function(x) selected[selected %in% x])
    
    # join together with a semicolon to make up the last column
    
    outK$inGenes <- unlist(lapply(keggSelected, function(x) paste(x, collapse = ",")))
    
    # adjusted pvalues here we use FDR-BF
    
    pvalsK <- outK$Pvalue
    
    adjpvalsK <- multiple.correction(pvalsK, typeFDR = "FDR-BH")
    fdr = fdrtool(adjpvalsK, statistic = "pvalue", plot = FALSE)
    
    
    
    # Add the adjusted Pvalues to the data frame containing the results
    
    outK[, 5] <- as.data.frame(adjpvalsK)
    outK[, 6] <- as.data.frame(fdr$qval)
    outK <- outK[outK[, "fdr$qval"] < FDRcut, ]
    
    # write the final data table as a tab separated file
    
    write.table(outK, file = OUTFILE, sep = "\t", row.names = FALSE, quote = FALSE)
    debugging_line <- paste(as.character(ALLFILES[i]), "... Done", sep = " ")
    cat(debugging_line)
  }
  i <- i + 1
}
