# Date: 2016-05-16
# Purpose: Find enriched kegg and go germs in gene set
library("qvalue",quietly=TRUE)

gene_ids <- c(9131, 10000, 317, 468, 472, 572, 578, 581, 27113, 596, 597, 598, 10018, 637, 329, 332, 823, 843, 100506742, 835, 836, 839, 840, 841, 842, 8837, 1147, 1439, 1075, 54205, 153090, 1616, 1649, 1676, 1677, 56616, 9451, 1965, 2021, 2081, 8772, 355, 356, 2353, 10912, 3002, 3265, 8739, 27429, 3562, 3708, 3725, 4000, 5604, 9020, 4217, 5594, 5602, 5599, 5601, 4170, 4790, 4792, 4803, 4914, 10038, 5170, 55367, 23533, 5366, 5551, 5783, 5894, 5970, 8737, 5414, 6708, 7124, 8793, 7132, 8743, 7157, 63970, 8717, 7185, 7186, 10376, 331)

get_gene_set <- function (type = c("`KEGG-PATHWAY`", "`GO-BP`", "`GO-MF`"), species = "human") {
  library(DBI)
  GS_CON <- dbConnect(RMySQL::MySQL(), user='gene_set', password='gene_set', dbname='gene_set', host='localhost')
  query <- paste("SELECT * FROM", type)
  retVal <- dbGetQuery(GS_CON, query)
  dbDisconnect(GS_CON)
  my_gene_set <- split(retVal$Gene_ID, retVal$id)
  return(my_gene_set)
}

geneSet <- list()
geneSet$GOBP <- get_gene_set("`GO-BP`")
geneSet$GOMF <- get_gene_set("`GO-MF`")
geneSet$KEGG <- get_gene_set("`KEGG-PATHWAY")
TERM2NAME <- get_gene_set("`TERM2NAME")

id2symbol <- function(idList) {
  # convert gene id to gene symbol
  library(org.Hs.eg.db)
  x <- org.Hs.egSYMBOL
  mapped_genes <- mappedkeys(x)
  xx <- as.list(x[mapped_genes])
  symbol <- xx[as.character(idList)]
  return(as.character(symbol))
}

validIds <- function(idList) {
  x <- org.Hs.egSYMBOL
  mapped_genes <- mappedkeys(x)
  return(intersect(mapped_genes,idList))
}

GSEA.cs <- function(geneList, geneSet, nPerm = 2000, minGSSize = 3, background = 18775) {
  # 背景值18775统计自6出miR靶基因预测源数据中，出现在2个或以上数据库的基因数
  retTbl <- data.frame()
  geneList <- validIds(geneList)
  for (db_name in names(geneSet)) {
    for (term_name in names(geneSet[[db_name]])) {
      interSets <- intersect(geneList,geneSet[[db_name]][[term_name]])
      a <- length(interSets)
      if (a < minGSSize)
        next
      
      b <- length(geneSet[[db_name]][[term_name]]) - a
      c <- length(geneList) - a
      d <- background - a - b - c
      x <- matrix(c(a, b, c, d), ncol = 2, dimnames = list(
        c("IsTarget","NotTarget"), c("InNetwork","OutNetwork")))
      
      pval <- chisq.test(x, simulate.p.value = TRUE, B = nPerm)$p.value
      if ( a/b < c/d ) {
        pval <- 0.95
        next
      }
      tblRes <- data.frame(Source = db_name, Term = term_name,
                           Desc = TERM2NAME[[term_name]],
                           Target_Cnt = length(geneList),
                           Gene_Set_Size=a + b, Intersection_Size = a,
                           Intersection_Genes=paste(id2symbol(interSets), collapse = ", "),
                           P_Value=pval )
      retTbl <- rbind(retTbl, tblRes)
    }
  }
  return(retTbl)
}

enrichTbl <- GSEA.cs(gene_ids, geneSet, nPerm = 2000, minGSSize = 8)
p.adj <- p.adjust(enrichTbl$P_Value, method="BH")
enrichTbl$p.adj <- p.adj
# qvalues <- qvalue(enrichTbl$P_Value, pi0.method="bootstrap")
# enrichTbl$qvalue <- qvalues$qvalues
