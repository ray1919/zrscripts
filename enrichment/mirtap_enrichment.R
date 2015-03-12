library(miRNAtap,quietly=TRUE,verbose=F)
source("miRNAtap_gseAnalysis.R",verbose=F)
file_list <- dir(pattern ="mir.*\\.txt")
res_file <- "enrichment.txt"
unlink(res_file)
for (mir_list_file in file_list) {
  mir_list = read.table(mir_list_file,header=F,as.is=T)
  print(mir_list_file)
  pb <- txtProgressBar(max=length(mir_list$V1)*3, width = 50,style = 3)
  i <- 1
  for ( mir in mir_list$V1) {
    # print(mir)
    org = substr(mir,1,3)
    mir <- substr(mir,5,nchar(mir))
    predictions = getPredictedTargets(mir, species=org, method='geom',
                                      sources = c("pictar", "diana", "targetscan", "miranda","miRDB"))
    a <- predictions[,"rank_product"]
    genes = names(a[a<20])
    
    # enrichment analysis import DOSE function
    for (setType in c("KEGGprofile","GOMF","GOBP")) {
      y <- enrich.internal(genes, organism = "mouse", pvalueCutoff=0.05, pAdjustMethod="BH",
                           qvalueCutoff=0.2, ont = setType,minGSSize = 5)
      setTxtProgressBar(pb,i)
      i <- i + 1
      if (is.null(y)) next
      tblRes <- y@result
      if (nrow(tblRes) > 0 ) {
        tblRes$mirna <- mir
        tblRes$list <- mir_list_file
        tblRes$category <- setType
        if (nrow(tblRes) > 0 )
          write.table(tblRes,file = res_file,append = T,quote = F,
                      sep="\t",row.names=F,col.names=F)
      }
    }
  }
  print(" done")
}
