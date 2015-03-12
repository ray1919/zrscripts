require(KEGG.db,quietly=TRUE)
require(topGO,quietly=TRUE)
library(DOSE)
getGeneSet.KEGGprofile <- function(setType="KEGGprofile", organism) {
  if (setType != "KEGGprofile")
    stop("setType should be 'KEGGprofile'... ")
  keggpathway2gene <- as.list(KEGGPATHID2EXTID)
  return(keggpathway2gene)
}

getGeneSet.GO <- function(setType="GOMF", organism) {
  if (setType != "GO")
    stop("setType should be 'GO'... ")
  # mapdb <- c("org.Hs.eg.db","org.Mm.eg.db")
  # names(mapdb) <- c("human","mouse")
  mapdb <- list(human = "org.Hs.eg.db",mouse = "org.Mm.eg.db")
  allGO2genes = annFUN.org(whichOnto='MF', feasibleGenes = NULL,
                           mapping=mapdb[organism], ID = "entrez")
  return(allGO2genes)
}

EXTID2TERMID.GOBP <- function(gene, organism) {
  retVal <- ALLGO2GENE(organism,"BP")
  ## split the table into a named list of GOs
  genes2GO <- split(retVal[["go_id"]], retVal[["gene_id"]])
  retVal <- genes2GO[gene]
  retVal <- retVal[sapply(retVal,length) > 0]
  return(retVal)
}

EXTID2TERMID.GOMF <- function(gene, organism) {
  retVal <- ALLGO2GENE(organism,"MF")
  ## split the table into a named list of GOs
  genes2GO <- split(retVal[["go_id"]], retVal[["gene_id"]])
  retVal <- genes2GO[gene]
  retVal <- retVal[sapply(retVal,length) > 0]
  return(retVal)
}

EXTID2TERMID.KEGGprofile <- function(gene, organism) {
  retVal <- as.list(KEGGEXTID2PATHID)
  retVal <- retVal[gene]
  retVal <- retVal[sapply(retVal,length) > 0]
  return(retVal)
}

ALLEXTID.KEGGprofile <- function(organism) {
  retVal <- as.list(KEGGEXTID2PATHID)
  ptn <- list(human = "hsa", mouse = "mmu")
  retVal <- retVal[sapply(sapply(retVal,grep,pattern = ptn[organism]),length) > 0]
  return(names(retVal))
}

ALLEXTID.GOBP <- function(organism) {
  retVal <- ALLGO2GENE(organism,"BP")
  allids <- unique(retVal[["gene_id"]])
  return(allids)
}

ALLEXTID.GOMF <- function(organism) {
  retVal <- ALLGO2GENE(organism,"MF")
  allids <- unique(retVal[["gene_id"]])
  return(allids)
}

TERMID2EXTID.KEGGprofile <- function(term,organism) {
  retVal <- as.list(KEGGPATHID2EXTID)
  return(retVal[term])
}

TERMID2EXTID.GOBP <- function(term,organism) {
  retVal <- ALLGO2GENE(organism,"BP")
  ## split the table into a named list of GOs
  .GO2genes <- split(retVal[["gene_id"]], retVal[["go_id"]])
  return(.GO2genes[term])
}
TERMID2EXTID.GOMF <- function(term,organism) {
  retVal <- ALLGO2GENE(organism,"MF")
  ## split the table into a named list of GOs
  .GO2genes <- split(retVal[["gene_id"]], retVal[["go_id"]])
  return(.GO2genes[term])
}

ALLGO2GENE <- function(organism,ont="MF") {
  # whichOnto, feasibleGenes = NULL, mapping, ID = "entrez"
  mapdb <- list(human = "org.Hs.eg.db",mouse = "org.Mm.eg.db")
  mapping=mapdb[organism]
  ID = "entrez"
  feasibleGenes = NULL
  whichOnto <- ont
  tableName <- c("genes", "accessions", "alias", "ensembl",
                 "gene_info", "gene_info", "unigene")
  keyName <- c("gene_id", "accessions", "alias_symbol", "ensembl_id",
               "symbol", "gene_name", "unigene_id")
  names(tableName) <- names(keyName) <- c("entrez", "genbank", "alias", "ensembl",
                                          "symbol", "genename", "unigene")
  
  
  ## we add the .db ending if needed 
  mapping <- paste(sub(".db$", "", mapping), ".db", sep = "")
  require(mapping, character.only = TRUE) || stop(paste("package", mapping, "is required", sep = " "))
  mapping <- sub(".db$", "", mapping)
  
  geneID <- keyName[tolower(ID)]
  .sql <- paste("SELECT DISTINCT go_id, ", geneID, " FROM ", tableName[tolower(ID)],
                " INNER JOIN ", paste("go", tolower(whichOnto), sep = "_"),
                " USING(_id)", sep = "")
  retVal <- dbGetQuery(get(paste(mapping, "dbconn", sep = "_"))(), .sql)
  
  ## restric to the set of feasibleGenes
  if(!is.null(feasibleGenes))
    retVal <- retVal[retVal[[geneID]] %in% feasibleGenes, ]
  
  return(retVal)
}

TERM2NAME.GOBP <- function(term,organism) {
  res <- getTermsDefinition(term,ontology = "BP",numChar = 80)
  return(res)
}

TERM2NAME.GOMF <- function(term,organism) {
  res <- getTermsDefinition(term,ontology = "MF",numChar = 80)
  return(res)
}

TERM2NAME.KEGGprofile <- function(term,organism) {
    pathID <- as.character(term)
    pathway2name<-as.list(KEGGPATHID2NAME)
    res <- unlist(pathway2name[substr(term,4,8)])
    return(res)
}

getTermsDefinition <- function(whichTerms, ontology = "MF", numChar = 80, multipLines = FALSE) {
  
  qTerms <- paste(paste("'", whichTerms, "'", sep = ""), collapse = ",")
  retVal <- dbGetQuery(GO_dbconn(), paste("SELECT term, go_id FROM go_term WHERE ontology IN",
                                          "('", ontology, "') AND go_id IN (", qTerms, ");", sep = ""))
  
  termsNames <- retVal$term
  names(termsNames) <- retVal$go_id
  
  if(!multipLines) 
    shortNames <- paste(substr(termsNames, 1, numChar),
                        ifelse(nchar(termsNames) > numChar, '...', ''), sep = '')
  else
    shortNames <- sapply(termsNames,
                         function(x) {
                           a <- strwrap(x, numChar)
                           return(paste(a, sep = "", collapse = "\\\n"))
                         })
  
  names(shortNames) <- names(termsNames)
  return(shortNames[whichTerms])
}
