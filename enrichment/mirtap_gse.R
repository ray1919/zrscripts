library(miRNAtap,quietly=TRUE,verbose=F)
library(DOSE)
source("miRNAtap_gseAnalysis.R",verbose=F)
file_list <- dir(pattern ="mir.*\\.txt")
res_file <- "gse.txt"
unlink(res_file)
for (mir_list_file in file_list) {
  mir_list = read.table(mir_list_file,header=F,as.is=T)
  print(mir_list_file)
  pb <- txtProgressBar(max=length(mir_list$V1)*2, width = 50,style = 3)
  i <- 1
  for ( mir in mir_list$V1) {
    # print(mir)
    org = substr(mir,1,3)
    mir <- substr(mir,5,nchar(mir))
    predictions = getPredictedTargets(mir, species=org, method='geom',
                  sources = c("pictar", "diana", "targetscan", "miranda","miRDB"))
    rankedGenes = predictions[,'rank_product']
    
    # gse enrichment
    for (setType in c("KEGGprofile","GO")) {
      y <- gseAnalyzer(rankedGenes, organism = "mouse", nPerm = 10000, minGSSize = 5,
                      pvalueCutoff = 0.1, pAdjustMethod = "BH", verbose = FALSE,
                      setType = setType)
      setTxtProgressBar(pb,i)
      i <- i + 1
      if (is.null(y)) next
      tblRes <- y@result
      if (nrow(tblRes) > 0 ) {
        tblRes$mirna <- mir
        tblRes$list <- mir_list_file
        tblRes$category <- setType
        tblRes <- tblRes[tblRes$enrichmentScore > 0,] # enrich at the end of list is
                                                      # not significant
        if (nrow(tblRes) > 0 )
          write.table(tblRes,file = res_file,append = T,quote = F,
                    sep="\t",row.names=F,col.names=F)
      }
    }
  }
  print(" done")
}
