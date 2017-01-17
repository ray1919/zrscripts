library(shiny)
suppressPackageStartupMessages(library(openxlsx))
suppressPackageStartupMessages(library(reshape))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(scales))
suppressPackageStartupMessages(library(naturalsort))
suppressPackageStartupMessages(library(DBI))
suppressPackageStartupMessages(library(plyr))
library(dplyr)

substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}

paste3 <- function(...,sep=", ") {
  L <- list(...)
  L <- lapply(L,function(x) {x[is.na(x)] <- ""; x})
  ret <-gsub(paste0("(^",sep,"|",sep,"$)"),"",
             gsub(paste0(sep,sep),sep,
                  do.call(paste,c(L,list(sep=sep)))))
  is.na(ret) <- ret==""
  ret
}

# final workbook
# wb <- createWorkbook(creator="CT Bioscience")

rv <- reactiveValues()
rv$wb <- createWorkbook(creator="CT Bioscience")
options("openxlsx.borderColour" = "#4F80BD")
options("openxlsx.borderStyle" = "thin")
# 
# headSty <- createStyle(fgFill="#DCE6F1", halign="center",
#                        border = "TopBottomLeftRight")



shinyServer(function(input, output) {
  
  output$contents <- renderTable(input$files[,1:3])
  unlink("*.png")
  observeEvent(input$processData, {
      withProgress(message = 'Calculation in progress',
                   detail = 'This may take a while...', value = 0, {
                     if (input$task == "routine") {
                       
                       ##########      常规数据比较分析       ##########
                       options(stringsAsFactors = FALSE)
                       
                       if (!"PCR_Layout_Template.xlsx" %in% input$files$name) {
                         stop(paste("ERROR 1:","PCR_Layout_Template.xlsx not exists.",sep = " "))
                       }
                       filepath <- function(x) {input$files$datapath[input$files$name == x]}
                       template_filepath <- filepath("PCR_Layout_Template.xlsx")
                       # gene and primer info
                       schema1 <- read.xlsx(template_filepath,sheet=1,colNames=T,
                                            cols=1:4)
                       # HK genes
                       schema2 <- read.xlsx(template_filepath,sheet=2,colNames=T,
                                            cols=1:2)
                       # CT,TM files
                       schema3 <- read.xlsx(template_filepath,sheet=3,colNames=T,
                                            cols=1:11)
                       # compare
                       schema4 <- read.xlsx(template_filepath,sheet=4,colNames=T,
                                            cols=2:4)
                       symbolList <- schema1$Symbol[schema1$Symbol!="[SKIP]"]
                     
                       incProgress(0.1, "Experiment schema read.")
                       # read sample file
                       for (i in 1:nrow(schema3)) {
                         for ( filename in schema3[i,c(2:3,5)] ) {
                           if (is.na(filename)) next
                           if (!filename %in% input$files$name) {
                             stop(paste("ERROR 2:",filename,"not exists.",sep = " "))
                           }
                         }
                       }
                       
                       # check compare name
                       
                       # 假设出现两版或以上的情况，样本对应均一致。
                       samples_per_array <- sapply(schema3[schema3[,6]==1,1], strsplit,split=',')
                       if (is.na(schema3[1,4])) {
                         groups_per_array  <- list()
                       } else {
                         groups_per_array  <- sapply(schema3[schema3[,6]==1,4], strsplit,split=',')
                         # 组内不满指定命名个数的，用最后一命名代替空白命名
                         # Update: 2016-03-14
                         for (i in 1:length(groups_per_array) ) {
                           if (length(groups_per_array[[i]]) < schema3[i,10] ) {
                             groups_per_array[[i]] <- c(groups_per_array[[i]],
                                                        rep(groups_per_array[[i]][length(groups_per_array[[i]])],
                                                            times = schema3[i,10] - length(groups_per_array[[i]])) )
                           }
                         }
                       }
                       
                       # all_samples <- unique(unlist(samples_per_array))
                       all_samples <- as.character(unlist(samples_per_array))

                       all_groups <- unlist(groups_per_array)
                       names(all_samples) <- NULL
                       if (!is.null(all_groups))
                         names(all_groups) <- all_samples
                       
                       # 确定需要进行数据分析的样本。不进行数据分析的样本，在进行看家基因选择时不考虑
                       sample_analysis <- rep(F,length(all_samples))
                       

                       for (i in unique(unlist(schema4[,1:2])) ) {
                         if (i %in% all_samples) {
                           sample_analysis[all_samples == i] <- TRUE
                         }
                         if ( i %in% all_groups ) {
                           sample_analysis[all_samples %in% names(all_groups[all_groups==i])] <- TRUE
                         }
                         if ( ! i %in% all_samples && ! i %in% all_groups) {
                           stop(paste("ERROR 3:",i,"not declared.",sep = " "))
                         }
                       }
                       
                       # 判断是否是miRNA芯片
                       if ( any(grepl("\\w\\w\\w-\\w\\w\\w-\\d",schema1$Symbol,perl=T)) ) {
                         array_type = "miRNA"
                       } else {
                         array_type = "gene"
                       }
                       if (nrow(schema2) > 0) {
                         normalization.method <- "HK"
                       } else {
                         normalization.method <- "median"
                       }
                       incProgress(0.2, "File check finish.")
                       
                       dataTbl <- data.frame(symbol=character(),sample=character(),geneid=numeric(),primerid=numeric(),
                                             pos=character(),ct=numeric(),tm1=numeric(),tm2=numeric(),opt.tm=character(),
                                             istmoutlier1=logical(),istmoutlier2=logical(),
                                             ishousekeeping=logical(),isdoublepeak=logical(),
                                             tmlowerlimit=numeric(),tmupperlimit=numeric(),
                                             qual=numeric())
                       
                       # 1   TM outlier compare to archive data
                       # 2   none GDC CT > 35 or GDC CT < 35
                       # 4	  double peak
                       # 8	  TM outlier among same batch data
                       # 16	Detector Call uncertain / Late Cp call
                       # 32	No CT
                       if (array_type == "miRNA") {
                         qc_cutoff <- 4
                         min_CI = 2 # min tm confidence interval
                       } else if (array_type == "gene") {
                         qc_cutoff <- 10
                         min_CI = 0.6 # min tm confidence interval
                       }
                       
                       insertRow <- function(existingDF, newrow) {
                         # new.line <- data.frame(newrow)
                         # colnames(new.line) <- colnames(existingDF)
                         # rbind(existingDF, new.line)
                         r=nrow(existingDF) + 1
                         # existingDF[seq(r+1,nrow(existingDF)+1),] <- existingDF[seq(r,nrow(existingDF)),]
                         existingDF[r,] <- newrow
                         existingDF
                       }
                       
                       geneMaxNum <- 1L
                       # read sample CT file
                       # pb <- txtProgressBar(max = nrow(schema3), style = 3)
                       for (j in 1: nrow(schema3)) {
                         # make pos => gene primer row index hash table
                         # pos2idx <- hash()
                         # pos2smp <- hash()
                         # rowNum <- 2*sqrt(schema3[j,6]/6)
                         # colNum <- 3*sqrt(schema3[j,6]/6)
                         # spr <- schema3[j,8]               # sample per row
                         # spc <- schema3[j,7] / schema3[j,8]  # sample per col
                         # for ( s in 1:rowNum ) {   # row, A .. H
                         #   for ( t in 1:colNum ) { # col, 1 .. 12
                         #     .set(pos2idx,keys = paste(LETTERS[s],t,sep=""),
                         #          values = (s-1) %% (rowNum/spc) * (colNum/spr) +
                         #            (t-1) %% (colNum/spr) + 1)
                         #     .set(pos2smp,keys = paste(LETTERS[s],t,sep=""),
                         #          values = (s-1) %/% (rowNum/spc) * spr + (t-1) %/% (colNum/spr) + 1)
                         #   }
                         # }
                         posmap <- data.frame()
                         rowNum <- 2*sqrt(schema3[j,7]/6)
                         colNum <- 3*sqrt(schema3[j,7]/6)
                         spr <- schema3[j,9]               # sample per row
                         spc <- schema3[j,8] / schema3[j,9]  # sample per col
                         for ( s in 1:rowNum ) {   # row, A .. H
                           for ( t in 1:colNum ) { # col, 1 .. 12
                             row.tmp <- data.frame(pos = paste(LETTERS[s],t,sep=""),
                                                   plate = schema3[j,6],
                                                   sample = (s-1) %/% (rowNum %/% spc) * spr +
                                                     (t-1) %/% (colNum %/% spr) + 1,
                                                   idx = (s-1) %% (rowNum %/% spc) * (colNum %/% spr) +
                                                     (t-1) %% (colNum %/% spr) +
                                                     geneMaxNum[as.integer(schema3[j,6])])
                             posmap <- rbind(posmap, row.tmp)
                           }
                         }
                         
                         geneMaxNum[as.integer(schema3[j,6])+1] =
                           geneMaxNum[as.integer(schema3[j,6])] + schema3[j,7] / schema3[j,8]
                         # geneNum = nrow(schema1)
                         
                         ct_raw <- read.table(filepath(schema3[j,2]), sep="\t",skip = 1,header=T,
                                              stringsAsFactors=F)
                         tm_raw <- read.table(filepath(schema3[j,3]), sep="\t",skip = 1,header=T,
                                              stringsAsFactors=F)
                         
                         # for (i in 1: (length(unlist(samples_per_array[j])) * geneNum)) {
                         # 导出的文件有可能包含空白数据行
                         for ( i in 1: nrow(ct_raw) ) {
                           pos <- ct_raw[i,'Pos']
                           # geneIdx <- hash::values(pos2idx,keys=pos)
                           geneIdx <- posmap$idx[posmap$pos == pos]
                           symbol <- schema1$Symbol[geneIdx]
                           if (!symbol %in% symbolList)
                             next
                           geneid <- schema1$Gene.ID[geneIdx]
                           primerid <- schema1$Primer.ID[geneIdx]
                           # sample_name <- unlist(samples_per_array[j])[hash::values(pos2smp,keys=pos)]
                           sample_name <- unlist(samples_per_array[(j-1) %% length(all_samples) + 1])[posmap$sample[posmap$pos == pos]]
                           # sample_name <- schema5$Sample[match(sample_name,schema5$id)]
                           ct <- ct_raw[i, 'Cp']
                           tm1 <- tm_raw[i, 'Tm1']
                           tm2 <- tm_raw[i, 'Tm2']
                           status <- ct_raw$Status[i]
                           qual <- 0
                           # Detector Call uncertain: 曲线异常
                           # Late Cp call: 最后起峰
                           if ( !is.na(status) &
                                grepl(pattern = "Detector Call uncertain|Late Cp call", x = status) )
                             qual <- 16
                           opt.tm <- NA
                           if ( !is.na(tm_raw[i,'Tm2'])) {
                             isdoublepeak <- TRUE
                           } else {
                             isdoublepeak <- FALSE
                           }
                           if ( symbol %in% schema2$Housekeeping.Gene.Symbol) {
                             ishousekeeping <- TRUE
                           } else {
                             ishousekeeping <- FALSE
                           }
                           dataTbl <-  insertRow(dataTbl, c(symbol,sample_name,geneid,primerid,pos,ct,tm1,tm2,
                                                            opt.tm,NA,NA,ishousekeeping,isdoublepeak,NA,NA,qual))
                         }
                         # setTxtProgressBar(pb, j)
                         incProgress(0.3/ nrow(schema3), "CT, TM data imported.")
                       }
                       dataTbl <- dataTbl[!is.na(dataTbl$sample),]
                       dataTbl$qual <- as.numeric(dataTbl$qual)
                       dataTbl$tm1 <- as.numeric(dataTbl$tm1)
                       dataTbl$tm2 <- as.numeric(dataTbl$tm2)
                       
                       con <- dbConnect(RMySQL::MySQL(), user = 'ctnet',
                                        password='ctnet', host='localhost',db='ctnet')
                       
                       for (i in 1:nrow(dataTbl)) {
                         istmoutlier1 <- NA
                         istmoutlier2 <- NA
                         opt.tm <- NA
                         outlimit2 <- c(NA,NA)
                         if( !is.na(dataTbl$tm1[i]) ) {
                           # determin is TM outlier in this experiment
                           opt.tm <- dataTbl$tm1[i]
                           tms <- as.numeric(unlist(dataTbl[dataTbl$symbol == dataTbl$symbol[i],
                                                            c('tm1','tm2')]))
                           iqr <- IQR(tms,na.rm=T)
                           outlimit2 <- c(quantile(tms,1/4,na.rm=T) - 1.5*iqr, quantile(tms,3/4,na.rm=T) + 1.5*iqr)
                           
                           if (outlimit2[2] - outlimit2[1] < min_CI) {
                             mean_limit2 = mean(outlimit2)
                             outlimit2[1] = mean_limit2 - 0.5*min_CI
                             outlimit2[2] = mean_limit2 + 0.5*min_CI
                           }
                           
                           istmoutlier2 <- TRUE
                           for ( tmv in dataTbl[i,c('tm1','tm2')] ) {
                             if (all(c(tmv >= outlimit2[1], tmv <= outlimit2[2], !is.na(tmv)) ) ) {
                               opt.tm <- tmv
                               istmoutlier2 <- FALSE
                             }
                           }
                           
                           # determine is TM a outlier compared to previous records
                           if ( !is.na(dataTbl$primerid[i]) ) {
                             res <- dbSendQuery(con, paste("SELECT tm1,tm2 FROM PCR_experiment
                                    WHERE primer_id = '",dataTbl$primerid[i],"'",sep=""))
                             tms <- as.numeric(na.omit(unlist(dbFetch(res))))
                             dbClearResult(res)
                             if (length(tms) > 0) {
                               iqr <- IQR(tms)
                               outlimit1 <- c(quantile(tms,1/4) - 1.5*iqr, quantile(tms,3/4) + 1.5*iqr)
                               istmoutlier1 <- FALSE
                               if ( opt.tm < outlimit1[1] || opt.tm > outlimit1[2] ) {
                                 istmoutlier1 <- TRUE
                               }
                             }
                           }
                         }
                         
                         qual <- 0
                         ct <- dataTbl$ct[i]
                         if ( dataTbl$symbol[i] == 'GDC' ) {
                           if ( !is.na(ct) && ct < 35 ) qual <- qual + 2
                         } else {
                           if ( is.na(ct) ) {
                             qual <- qual + 32
                           } else if ( ct > 35 ) {
                             qual <- qual + 2
                           }
                         }
                         if ( dataTbl$isdoublepeak[i] ) qual <- qual + 4
                         if ( !is.na(istmoutlier1) & istmoutlier1 ) qual <- qual + 1
                         if ( !is.na(istmoutlier2) & istmoutlier2 ) qual <- qual + 8
                         dataTbl$opt.tm[i] <- opt.tm
                         dataTbl$istmoutlier1[i] <- istmoutlier1
                         dataTbl$istmoutlier2[i] <- istmoutlier2
                         dataTbl$tmlowerlimit[i] <- outlimit2[1]
                         dataTbl$tmupperlimit[i] <- outlimit2[2]
                         dataTbl$qual[i] <- dataTbl$qual[i] + qual
                       }
                       dataTbl$sample <- as.character(dataTbl$sample)
                       dataTbl$ct <- as.numeric(dataTbl$ct)
                       dataTbl$tm1 <- as.numeric(dataTbl$tm1)
                       dataTbl$tm2 <- as.numeric(dataTbl$tm2)
                       dataTbl$opt.tm <- as.numeric(dataTbl$opt.tm)
                       dataTbl$tmlowerlimit <- as.numeric(dataTbl$tmlowerlimit)
                       dataTbl$tmupperlimit <- as.numeric(dataTbl$tmupperlimit)
                       
                       incProgress(0.2, "Raw data QC checked.")
                       
                       if (array_type == "gene") {
                         # retrive gene table list
                         geneTbl <- data.frame(Well=character(),Symbol=character(),"Gene ID"=numeric(),
                                               "Gene Name"=character(), "Species"=character(),
                                               Synonyms=character(),"Type of Gene"=character())
                         
                         for (i in rownames(schema1[!is.na(schema1$Gene.ID),])) {
                           if (!schema1[i,"Symbol"] %in% symbolList) next
                           if (is.na(schema1[i,"Gene.ID"])) next
                           sth <- dbSendQuery(con, paste("SELECT gene_symbol, gene_id,
                                                         gene_name,common,synonyms,type_of_gene FROM gene
                                                         LEFT join species on tax_id = id
                                                         WHERE gene_id = ",schema1[i,"Gene.ID"],sep=""))
                           res <- dbFetch(sth)
                           dbClearResult(sth)
                           well <- schema1[schema1$Symbol == res[[1]],"Well"]
                           geneTbl[i,] <- c(well, unlist(res))
                         }
                         # print("Gene table sheet created.")
                       }
                       
                       sort_col <- function(df) {
                         return(df[,c("symbol",naturalsort(colnames(df[,-1])))])
                       }
                       
                       is.outlier <- function(x) {
                         iqr <- IQR(x,na.rm = T)
                         y <- quantile(x,3/4,na.rm = T) + 1.5*iqr # 理论是1.5倍
                         ## meam gene qc >= 2* qc_cutoff
                         # y2 <- 2 * qc_cutoff * length(symbolList)
                         # x > min(c(y, y2))
                         x > y
                       }
                       
                       # Assay QC
                       assayQC <- aggregate(opt.tm ~ symbol, data=dataTbl, sd, na.rm=T)
                       assayQC <- merge(x = assayQC, by="symbol", all=T,
                                        y = aggregate(ct ~ symbol, data=dataTbl,
                                                      function(x){length(x[x<35])}))
                       assayQC <- merge(x = assayQC, by="symbol", all=T,
                                        y = aggregate(ct ~ symbol, data=dataTbl,
                                                      function(x){length(x[x>=35])}))
                       assayQC <- merge(x = assayQC, by="symbol", all=T,
                                        y = aggregate(ct ~ symbol, data=dataTbl,
                                                      function(x){length(all_samples) - length(x)}))
                       assayQC <- merge(assayQC, aggregate(isdoublepeak ~ symbol, data=dataTbl,
                                                           function(x){sum(as.logical(x))}), all=T)
                       assayQC <- merge(assayQC, aggregate(qual ~ symbol, data=dataTbl,sum), all=T)
                       assayQC$is.qc.outlier <- is.outlier(assayQC$qual)
                       colnames(assayQC) <- c("SYMBOL", "TM SD", "CT<35","CT>=35","CT NULL","DOUBLE PEAKS","QUAL","IS_OUTLIER")
                       assayQC$`CT NULL`[is.na(assayQC$`CT NULL`)] <- length(all_samples)
                       if (length(assayQC$SYMBOL[assayQC$IS_OUTLIER]) > 0) {
                         print(paste(
                           paste(assayQC$SYMBOL[assayQC$IS_OUTLIER], collapse = ", "),
                           "failed the QC test.", collapse = " "))
                       }
                       
                       # Sample QC
                       sampleQC <- aggregate(ct ~ sample, data=dataTbl, function(x){length(x[x<35])})
                       sampleQC <- merge(x = sampleQC, by="sample", all=T,
                                         y = aggregate(ct ~ sample, data=dataTbl,
                                                       function(x){length(x[x>=35])}))
                       sampleQC <- merge(x = sampleQC, by="sample", all=T,
                                         y = aggregate(ct ~ sample, data=dataTbl,
                                                       function(x){length(symbolList) - length(x)}))
                       sampleQC <- merge(sampleQC, aggregate(isdoublepeak ~ sample, data=dataTbl,
                                                             function(x){sum(as.logical(x))}), all=T)
                       sampleQC <- merge(sampleQC, aggregate(qual ~ sample, data=dataTbl,sum), all=T)
                       colnames(sampleQC) <- c("sample", "CT<35","CT>=35","CT NULL","DOUBLE PEAKS","QUAL_SUM")
                       sampleQC <- merge(sampleQC, aggregate(qual ~ sample, data=dataTbl,min), all=T)
                       sampleQC$is.qc.outlier <- is.outlier(sampleQC$QUAL_SUM)
                       colnames(sampleQC) <- c("SAMPLE", "CT<35","CT>=35","CT NULL","DOUBLE PEAKS","QUAL_SUM","QUAL_MIN", "IS_OUTLIER")
                       ## sample min qc >= qc_cutoff is set to be a outlier 2016-11-18
                       sampleQC$IS_OUTLIER[sampleQC$QUAL_MIN >= qc_cutoff] <- TRUE
                       ## sample average gene QC <= qc_cutoff * 0.5 is set to be normal 2017-1-16
                       sampleQC$IS_OUTLIER <- sampleQC$IS_OUTLIER &
                         sampleQC$QUAL_SUM > length(symbolList) * qc_cutoff * 0.5
                       if (length(sampleQC$SAMPLE[sampleQC$IS_OUTLIER]) > 0) {
                         print(paste(
                           paste(sampleQC$SAMPLE[sampleQC$IS_OUTLIER], collapse = ", "),
                           "failed the QC test.", collapse = " "))
                         sample_analysis[match(sampleQC$SAMPLE[sampleQC$IS_OUTLIER], all_samples)] <- FALSE
                       }
                       
                       # Data Table & QC
                       rawCt <- sort_col(cast(dataTbl, symbol~sample,value = "ct"))
                       rawTm <- sort_col(cast(dataTbl, symbol~sample,value = "opt.tm"))
                       rawQc <- sort_col(cast(dataTbl, symbol~sample,value = "qual"))
                       rawPos <- ddply(dataTbl, .(symbol), summarise,
                                       Pos=paste(unique(pos), collapse = ",") )
                       rawTbl <- cbind(rawPos,rawCt[,-1],rawTm[,-1],rawQc[,-1])
                       wellTbl <- schema1[,c("Symbol","Well")]
                       rawTbl <- merge(wellTbl,rawTbl,by.x = "Symbol",by.y= "symbol")
                       
                       incProgress(0.1, "Data & QC table sheet created.")
                       
                       # dataTblQc10 <- dataTbl[dataTbl$qual < qc_cutoff,]
                       dataTblQc10 <- dataTbl[dataTbl$qual < qc_cutoff & # QC 小于阈值
                                                !(dataTbl$sample %in% sampleQC$sample[sampleQC$is.qc.outlier]) &
                                                !(dataTbl$symbol %in% assayQC$symbol[assayQC$is.qc.outlier]),]
                       
                       rawCtQc10 <- cast(dataTblQc10, symbol~sample,value = "ct")
                       # 找到类似-1 -2 -3标志的技术重复，先合并。去掉QC不合格的结果。
                       # Update: 2016-03-14
                       is_tech_rep <- FALSE
                       if (all(grepl(pattern = "-\\d$", x = all_samples[sample_analysis]))) {
                         is_tech_rep <- TRUE
                         sreps <- matrix(unlist(strsplit(x = all_samples[sample_analysis], split = "-")),
                                         ncol = 2, byrow = T)
                         for (r in 1:nrow(sreps)) {
                           sreps[r,2] <- paste(sreps[r,], collapse = "-")
                         }
                         sreps <- cbind(sreps, all_groups[sample_analysis])
                         sreps.uniq <- unique(sreps[,c(1,3)])
                         all_samples.ori <- all_samples
                         all_groups.ori <- all_groups
                         all_samples <- c(all_samples, sreps.uniq[,1])
                         sample_analysis <- c(sample_analysis,
                                              setNames(rep(TRUE, length(sreps.uniq[,1])), sreps.uniq[,1]))
                         all_groups <- c(rep("", times = length(all_groups)), sreps.uniq[,2])
                         for (s in unique(sreps[,1])) {
                           reps <- sreps[sreps[,1]==s,2]
                           if (length(reps) == 1) {
                             rawCtQc10[,s] <- rawCtQc10[,reps]
                           } else {
                             rawCtQc10[,s] <- apply(rawCtQc10[, colnames(rawCtQc10) %in% reps], MARGIN = 1, FUN = mean,na.rm=T)
                           }
                         }
                         
                       }
                       
                       # delta-delta CT result sheet
                       # check HK
                       if (normalization.method == "HK") {
                         hks_valid <- array()
                         for (hks in schema2$Housekeeping.Gene.Symbol) {
                           if (is_tech_rep) {
                             is_valid <- TRUE
                             for (s in unique(sreps[,1])) {
                               reps <- sreps[sreps[,1]==s,2]
                               z <- dataTbl[dataTbl$symbol == hks & dataTbl$sample %in% reps,"qual"] < qc_cutoff
                               if (is.na(table(z)["TRUE"])) {
                                 is_valid <- FALSE
                                 break
                               }
                             }
                             if (is_valid)
                               hks_valid <- c(hks_valid,hks)
                           } else {
                             if (all(dataTbl[dataTbl$symbol == hks &
                                             dataTbl$sample %in% all_samples[sample_analysis],"qual"] < qc_cutoff))
                               hks_valid <- c(hks_valid,hks)
                           }
                         }
                         if (length(hks_valid) == 1)
                           stop("ERROR 4: All HK genes failed QC checking.")
                       } else if (normalization.method == "median") {
                         # use median normalization when no HK gene provided
                         valid_symbol <- intersect(na.omit(rawCt)$symbol, na.omit(rawTm)$symbol)
                         median_ct <- apply(rawCt[rawCt$symbol %in% valid_symbol,-1],MARGIN = 2,median)
                         names(median_ct) <- colnames(rawCt[,-1])
                       }
                       
                       # calculate delta CT for each sample
                       deltaCt <- data.frame(symbol=character(),sample=character(),delta_ct=numeric())
                       for (k in all_samples[sample_analysis] ) {
                         if (normalization.method == "HK") {
                           hks_avg_ct <- mean(rawCtQc10[rawCtQc10$symbol %in% hks_valid,k],na.rm=T)
                         } else if (normalization.method == "median") {
                           hks_avg_ct <- median_ct[k]
                         }
                         for (j in schema1$Symbol ) {
                           # skip HK genes
                           if (j %in% schema2$Housekeeping.Gene.Symbol)
                             next
                           if (j %in% c("GDC","PPC","RTC","PPC1","RTC1","PPC2","RTC2","PPC3","RTC3",
                                        "NEG1","NEG2","NEG3","NEG4") )
                             next
                           ct_raw <- rawCtQc10[rawCtQc10$symbol == j, k]
                           if (length(ct_raw) == 0)
                             next
                           delta_ct <- ct_raw - hks_avg_ct
                           deltaCt <- rbind(deltaCt, data.frame(symbol=j,sample=k,delta_ct))
                         }
                       }
                       rownames(deltaCt) <- NULL
                       deltaCtCasted <- sort_col(cast(deltaCt, symbol~sample,value = "delta_ct"))
                       
                       incProgress(0.1, "HK gene QC checked.")
                       
                       colIndex <- function(df, colId) {
                         colname <- colnames(df)
                         return(grep(colId,colname))
                       }
                       
                       # save data Table 
                       options("openxlsx.borderColour" = "#4F80BD")
                       options("openxlsx.borderStyle" = "thin")
                       modifyBaseFont(rv$wb, fontSize = 10, fontName = "Arial Narrow")
                       headSty <- createStyle(fgFill="#DCE6F1", halign="center",
                                              border = "TopBottomLeftRight")
                       
                       
                       # raw data sheet
                       sheetName <- "Raw Data and QC"
                       if (sheetName %in% names(rv$wb)) {
                         removeWorksheet(rv$wb, sheetName)
                       }
                       addWorksheet(rv$wb, sheetName, gridLines = FALSE, zoom = 150)
                       freezePane(rv$wb, sheet = sheetName, firstRow = TRUE, firstCol = TRUE)
                       ## freeze first row and column
                       writeDataTable(rv$wb, sheet = sheetName, x = dataTbl, colNames = TRUE,
                                      rowNames = FALSE, tableStyle = "TableStyleLight9")
                       
                       if (array_type == "gene") {
                         # gene sheet
                         sheetName <- "Gene Table"
                         if (sheetName %in% names(rv$wb)) {
                           removeWorksheet(rv$wb, sheetName)
                         }
                         addWorksheet(rv$wb, sheetName, gridLines = FALSE, zoom = 150)
                         freezePane(rv$wb, sheet = "Gene Table", firstRow = TRUE,
                                    firstCol = F) ## freeze first row and column
                         setColWidths(rv$wb, sheet = 2, cols = "D", widths = 50)
                         setColWidths(rv$wb, sheet = 2, cols = "F", widths = 20)
                         setColWidths(rv$wb, sheet = 2, cols = "G", widths = 13)
                         writeData(rv$wb, sheet = "Gene Table", x = geneTbl, startCol = "A", startRow=1,
                                   borders="rows", headerStyle = headSty)
                       }
                       
                       # raw sheet
                       sheetName <- "Data Table"
                       if (sheetName %in% names(rv$wb)) {
                         removeWorksheet(rv$wb, sheetName)
                       }
                       addWorksheet(rv$wb, sheetName, gridLines = FALSE, zoom = 150)
                       freezePane(rv$wb, sheet = "Data Table", firstActiveRow = 3,firstActiveCol = 'B')
                       ## freeze first row and column
                       writeData(rv$wb, "Data Table", x = rawTbl, startCol = "A", startRow=2, borders="rows",
                                 headerStyle = headSty)
                       writeData(rv$wb, "Data Table", x = "CT", startCol = 4, startRow = 1)
                       writeData(rv$wb, "Data Table", x = "TM", startCol = sum(schema3[,10]) + 4, startRow = 1)
                       writeData(rv$wb, "Data Table", x = "QC", startCol = 2*sum(schema3[,10]) + 4, startRow = 1)
                       s1 <- createStyle(fontSize=14, textDecoration=c("bold", "italic"))
                       addStyle(rv$wb, "Data Table", style = s1, rows=c(1,1,1), cols=(0:2) * sum(schema3[,9]) + 4)
                       
                       sheetName <- "Assay QC"
                       if (sheetName %in% names(rv$wb)) {
                         removeWorksheet(rv$wb, sheetName)
                       }
                       addWorksheet(rv$wb, sheetName, gridLines = FALSE, zoom = 150)
                       freezePane(rv$wb, sheet = "Assay QC", firstRow = T, firstCol = F)
                       writeData(rv$wb, sheet = "Assay QC", x = assayQC, startCol = "A", startRow=1,
                                 borders="rows", headerStyle = headSty)
                       
                       sheetName <- "Sample QC"
                       if (sheetName %in% names(rv$wb)) {
                         removeWorksheet(rv$wb, sheetName)
                       }
                       addWorksheet(rv$wb, sheetName = "Sample QC", gridLines = FALSE, zoom = 150)
                       freezePane(rv$wb, sheet = "Sample QC", firstRow = T, firstCol = F)
                       writeData(rv$wb, sheet = "Sample QC", x = sampleQC, startCol = "A", startRow=1,
                                 borders="rows", headerStyle = headSty)
                       
                       # ΔΔCT compare
                       for (i in 1:nrow(schema4)) {
                         if (nrow(schema4) == 0) break
                         A <- schema4$A[i]
                         B <- schema4$B[i]
                         
                         cmp_name <- paste(A,"vs",B,sep=" ")
                         sheet_name <- substr(cmp_name,1,31)
                         if (sheet_name %in% names(rv$wb)) {
                           removeWorksheet(rv$wb, sheet_name)
                         }
                         addWorksheet(rv$wb, sheetName = sheet_name, gridLines = FALSE, zoom = 150)
                         freezePane(rv$wb, sheet = sheet_name, firstRow = T, firstCol = F)
                         UpStyle <- createStyle(textDecoration = "bold", fontColour = "#9C0006")
                         DownStyle <- createStyle(textDecoration = "bold", fontColour = "#006100")
                         
                         # deltaTbl <- data.frame(symbol=character(),sample=character(),deltaCt=numeric())
                         plotxy <- data.frame()
                         
                         if (A %in% all_samples[sample_analysis] & B %in% all_samples[sample_analysis]) {
                           print("sample compare")
                           deltaTbl <- deltaCt[deltaCt$sample %in% c(A,B), ]
                           ddCt <- cast(deltaTbl, symbol~sample,value = "delta_ct")
                           ddCt$delta.delta.Ct <- NA
                           for ( t in 1:nrow(ddCt) ) {
                             ddCt[t,"delta.delta.Ct"] = ddCt[t, A] - ddCt[t, B]
                             ddCt[t, "ratio"] = 2 ^ (-1 * ddCt[t,"delta.delta.Ct"])
                             ddCt[t, "log ratio"] = -1 * ddCt[t,"delta.delta.Ct"]
                             ddCt[t, "fold change"] = ddCt[t,"ratio"]
                             if (!is.na(ddCt[t,"ratio"]))
                               if (ddCt[t,"ratio"] < 1)
                                 ddCt[t, "fold change"] = -1/ddCt[t,"ratio"]
                           }
                           ddCt <- ddCt[,c("symbol",A,B,"delta.delta.Ct", "ratio","log ratio","fold change")]
                           # plotxy <- data.frame(A = 2^-ddCt[, A], B = 2^-ddCt[, B], C = log2(2^-ddCt[, A] / 2^-ddCt[, B]))
                           plotxy <- data.frame(A = -ddCt[, A], B = -ddCt[, B],
                                                C = log2(2^-ddCt[, A] / 2^-ddCt[, B]))
                         }
                         else if (A %in% all_groups & B %in% all_groups) {
                           print("group compare")
                           sA <- all_samples[all_groups==A & sample_analysis]
                           sB <- all_samples[all_groups==B & sample_analysis]
                           
                           deltaTbl <- deltaCt[deltaCt$sample %in% c(sA,sB), ]
                           ddCt <- cast(deltaTbl, symbol~sample,value = "delta_ct")
                           # 样本名自然排序
                           ddCt <- ddCt[,c("symbol",naturalsort(colnames(ddCt[,-1])))]
                           print("calculate delta Ct")
                           for ( t in nrow(ddCt):1 ) {
                             if ( length(na.omit(as.numeric(ddCt[t, sA]))) < 2 |
                                  length(na.omit(as.numeric(ddCt[t, sB]))) < 2) {
                               ddCt <- ddCt[-t,]
                               next
                             }
                             ddCt[t,"delta.delta.Ct"] =  mean(as.numeric(ddCt[t, sA]), na.rm=T) -
                               mean(as.numeric(ddCt[t, sB]), na.rm=T)
                             ddCt[t, "ratio"] = 2 ^ (-1 * ddCt[t,"delta.delta.Ct"])
                             ddCt[t, "log ratio"] = -1 * ddCt[t,"delta.delta.Ct"]
                             ddCt[t, "fold change"] = ddCt[t,"ratio"]
                             if (ddCt[t,"ratio"] < 1)
                               ddCt[t, "fold change"] = -1/ddCt[t,"ratio"]
                             if (grepl(x = schema4$IsPaired[i], pattern = "Y", ignore.case = T) ) {
                               pdata <- data.frame(g1=as.numeric(ddCt[t, sA]),g2=as.numeric(ddCt[t, sB]) )
                               if (nrow(na.omit(pdata)) >= 2)
                                 pval <- t.test(pdata$g1, pdata$g2, paired = TRUE, var.equal = TRUE)$p.value
                               else
                                 pval <- NA
                             } else
                               pval <- t.test(as.numeric(ddCt[t, sA]), as.numeric(ddCt[t, sB]), paired = FALSE, var.equal = TRUE)$p.value
                             ddCt[t, "p value"] <- pval
                           }
                           # plotxy <- data.frame(A = 2^-apply(ddCt[, sA], 1,mean), B = 2^-apply(ddCt[, sB], 1,mean),
                           plotxy <- data.frame(A = -apply(ddCt[, sA], 1, mean, na.rm=T),
                                                B = -apply(ddCt[, sB], 1, mean, na.rm=T),
                                                C = log2(2^-apply(ddCt[, sA], 1,mean, na.rm=T) / 2^-apply(ddCt[, sB], 1,mean, na.rm=T)))
                           pv_col = colIndex(ddCt, "p value")
                           conditionalFormatting(rv$wb, sheet_name, cols=pv_col, rows = 2:nrow(ddCt),
                                                 rule="<0.05", style = UpStyle)
                         }
                         else {
                           print(paste("Compare",i,"is not supported.",sep=" "))
                         }
                         
                         setColWidths(rv$wb, sheet = sheet_name, cols = 1:ncol(ddCt), widths = 10)
                         writeData(rv$wb, sheet_name, x = ddCt[,1:ncol(ddCt)], startCol = "A", startRow=1,
                                   borders="rows", headerStyle = headSty)
                         
                         print("make scatter plot.")
                         d <- qplot(data=plotxy, x = B, y= A, xlab=B,ylab=A,colour= C,size=0.8)
                         p <- ggplot(plotxy, aes(B, A,color = plotxy$C)) +
                           geom_point( size = 1) +
                           geom_abline(intercept = 1, color="firebrick1") +
                           geom_abline(intercept = -1, color="limegreen") +
                           xlab(B) + ylab(A) +
                           scale_colour_gradient2("log2 ratio", midpoint = 0,#, limits=c(-2, 2)
                                                  low = muted("green"), mid = "snow3", high = muted("red")) +
                           theme_bw()
                         pngfile = paste(A,B,".png",sep="")
                         png(filename = pngfile,width=6,height=5,units="in",res=300)
                         print(p)
                         dev.off()
                         # insertPlot(wb, sheet = 3+i, startCol = ncol(ddCt) + 2)
                         insertImage(rv$wb, sheet = sheet_name, file = pngfile, width = 6, 
                                     height = 5, startRow = 2, startCol = ncol(ddCt) + 1, 
                                     units = "in", dpi = 300)
                         
                         if (length(symbolList) >= 384) {
                           # make volcano plot
                           dat1 <- data.frame(x=as.numeric(ddCt$`log ratio`), y=-log10(ddCt$`p value`), ID=ddCt$symbol)
                           dat2 <- na.omit(dat1)
                           if (array_type == "miRNA") {
                             dat2$ID <- sub(pattern = "^...-", replacement = "", x = dat2$ID,perl = T)
                           }
                           mask <-  with(dat2, y>-log10(0.05) & abs(x)>1)
                           cols <- ifelse(mask, "firebrick1", "grey")
                           p2 <- ggplot(dat2, aes(x, y, label= ID)) +
                             geom_point(color = cols, size = 0.8) +
                             geom_vline(xintercept = 1, color = "dodgerblue", linetype="longdash") + #add vertical line
                             geom_vline(xintercept = -1, color = "dodgerblue", linetype="longdash") + #add vertical line
                             geom_hline(yintercept = -log10(0.05), color = "deeppink", linetype="longdash") +  #add vertical line
                             labs(x="log2(Fold-change)", y="-log10(P.Value)") + 
                             scale_x_continuous("log2(Fold-change)") +
                             scale_y_continuous("-log10(P.Value)", limits = range(0,max(dat2$y)+0.2)) +
                             annotate("text", x=dat2$x[mask], y=dat2$y[mask], 
                                      label=dat2$ID[mask], size=dat2$y[mask], 
                                      vjust=-0.1, hjust=-0.1, color="lightsteelblue4") +
                             theme_bw()
                           pngfile2 = paste(A,B,".vp.png",sep="")
                           png(filename = pngfile2,width=5,height=5,units="in",res=300)
                           print(p2)
                           dev.off()
                           # insertPlot(wb, sheet = 3+i, startCol = ncol(ddCt) + 2)
                           insertImage(wb = rv$wb, sheet = sheet_name, file = pngfile2, width = 5, 
                                       height = 5, startRow = 30, startCol = ncol(ddCt) + 1, 
                                       units = "in", dpi = 300)
                         }
                         # conditional formatting
                         log_col = colIndex(ddCt, "log ratio")
                         fc_cf_col = colIndex(ddCt, "fold change")
                         conditionalFormatting(rv$wb, sheet_name, cols=log_col, rows = 1:nrow(ddCt)+1,
                                               rule=">=1", style = UpStyle)
                         conditionalFormatting(rv$wb, sheet_name, cols=log_col, rows = 1:nrow(ddCt)+1,
                                               rule="<=-1", style = DownStyle)
                         conditionalFormatting(rv$wb, sheet_name, cols=fc_cf_col, rows = 1:nrow(ddCt)+1,
                                               rule=">=2", style = UpStyle)
                         conditionalFormatting(rv$wb, sheet_name, cols=fc_cf_col, rows = 1:nrow(ddCt)+1,
                                               rule="<=-2", style = DownStyle)
                         
                         # number formatting
                         twodigit <- createStyle(numFmt = "0.00",border="Bottom")
                         addStyle(rv$wb, sheet_name, style = twodigit, cols = 2:fc_cf_col,
                                  rows = 1:nrow(ddCt)+1, gridExpand = T)
                         
                         # fig lengend
                         #note <- "上图是对两个样本间每个基因的相对表达比值(2-ΔCT)的LOG2转换值做散点图。每个点以该基因的LOG表达比值LOG2(ratio)用颜色表示其差异倍数。红色越深，图上越靠近左上方为上调倍数越大，绿色越深，图上越靠近右下方为下调倍数越大。颜色越浅， 差异倍数越小。注：未表达或表达异常的基因未包括在图中。"
                         #com <- createComment(comment = note, author = "CT Bioscience", style = NULL,
                         #              visible = TRUE, width = 7, height = 4)
                         #writeComment(wb = wb, sheet = sheet_name, col = ncol(ddCt)+2,row = 29, comment = com)
                       }
                       
                       print("Add note sheet.")
                       
                       sheetName <- "QC Plot"
                       if (sheetName %in% names(rv$wb)) {
                         removeWorksheet(rv$wb, sheetName)
                       }
                       addWorksheet(rv$wb, sheetName, gridLines = FALSE, zoom = 150)
                       writeData(rv$wb, sheet = "QC Plot", x = c("QC quality (sum of following conditions):",
                                                              "1  TM outlier compare to archive data",
                                                              "2  none GDC CT > 35 or GDC CT < 35",
                                                              "4  Double Peak",
                                                              "8  TM outlier among same batch data",
                                                              "16 Detector Call uncertain/Late Cp call",
                                                              "32 No Detect"))
                       
                       # check bad gene & bad sample
                       qc.matrix <- as.matrix(rawQc[,-1])
                       gene.qc <- apply(X = qc.matrix, MARGIN = 1, FUN = sum, na.rm=T)
                       
                       dataTbl$symbol <- factor(dataTbl$symbol, levels = rawQc$symbol[order(gene.qc)], ordered = T)
                       
                       # class(dataTbl$sample)
                       dataTbl$sample <- factor(dataTbl$sample, levels = naturalsort(unique(dataTbl$sample)))
                       p2 <- ggplot(dataTbl[order(dataTbl$symbol),], aes(sample, symbol, fill = qual)) +
                         geom_tile( colour = "white") +
                         labs(x = "Sample", y = "Gene") +
                         theme(axis.text.x = element_text(angle = 90)) + 
                         scale_fill_gradient(low = "white", high = "steelblue")
                       qcpngfile = "qcheatmap.png"
                       png(filename = qcpngfile,width = length(sample_analysis)/5 + 4, height = 11,units="in",res=300)
                       print(p2)
                       dev.off()
                       insertImage(wb = rv$wb, sheet = "QC Plot", file = qcpngfile,
                                   width = length(sample_analysis)/5 + 4, height = 11,
                                   startRow = 1, startCol = 3,  units = "in", dpi = 300)
                       
                       # Boxplot
                       sheetName <- "CT BOXPLOT"
                       if (sheetName %in% names(rv$wb)) {
                         removeWorksheet(rv$wb, sheetName)
                       }
                       addWorksheet(rv$wb, sheetName, gridLines = FALSE, zoom = 150)
                       p4 <- ggplot(dataTbl[order(dataTbl$symbol),], aes(x=sample, y=ct, fill=sample)) +
                         geom_boxplot(color="darkgray", alpha=0.1,outlier.shape = NA) +
                         geom_jitter(width = 0.5, color="lightcoral", alpha=0.7) +
                         labs(x = "Sample", y = "CT Value") +
                         theme_bw() + 
                         theme(axis.text.x = element_text(angle = 90)) +
                         guides(fill=FALSE)
                       boxpngfile = "boxplot.png"
                       png(filename = boxpngfile,width = length(sample_analysis)/5 + 4, height = 5,units="in",res=300)
                       print(p4)
                       dev.off()
                       insertImage(wb = rv$wb, sheet = "CT BOXPLOT", file = boxpngfile,
                                   width = length(sample_analysis)/5 + 4, height = 5,
                                   startRow = 1, startCol = 1,  units = "in", dpi = 300)
                       
                       # Heatmap
                       sheetName <- "HEATMAP PLOT"
                       if (sheetName %in% names(rv$wb)) {
                         removeWorksheet(rv$wb, sheetName)
                       }
                       addWorksheet(rv$wb, sheetName, gridLines = FALSE, zoom = 150)
                       if (normalization.method == "HK") {
                         writeData(rv$wb, sheet = "HEATMAP PLOT", c("Valid house-keeping gene:",na.omit(hks_valid)))
                       }
                       deltaCt$sample <- factor(deltaCt$sample, levels = naturalsort(unique(deltaCt$sample)))
                       p3 <- ggplot(deltaCt[order(deltaCt$symbol),], aes(sample, symbol, fill = delta_ct)) +
                         geom_tile( colour = "white") +
                         labs(x = "Sample", y = "Gene") +
                         theme(axis.text.x = element_text(angle = 90)) + 
                         guides(fill=guide_legend(title="Delta CT")) +
                         scale_fill_gradient2(low = "brown1", mid="white", high = "lightgreen",
                                              midpoint = median(deltaCt$delta_ct, na.rm = T))
                       dctpngfile = "dctheatmap.png"
                       png(filename = dctpngfile, width = length(sample_analysis)/5 + 4, height = 11,
                           units="in", res=300)
                       print(p3)
                       dev.off()
                       insertImage(wb = rv$wb, sheet = "HEATMAP PLOT", file = dctpngfile,
                                   width = length(sample_analysis)/5 + 4, height = 11,
                                   startRow = 1, startCol = 3,  units = "in", dpi = 300)

                       output$text <- renderPrint(paste("Job done.", Sys.time()))
                       output$plot <- renderPlot(p2)

                     } else if (input$task == "data_only") {
                       
                       ##########      仅提取数据       ##########
                       
                       dList <- list()
                       # if (!exists("input$files")) {stop("No files uploaded yet!")}
                       nfiles <- nrow(input$files)
                       for (i in 1:nfiles ) {
                         if (!grepl(pattern = "\\.txt", x=input$files$name[i])) {
                           # output$text <- renderPrint("Format Error")
                           next
                         } else {
                           txtFile <- input$files$datapath[i]
                           tbl <- read.table(txtFile, sep="\t",skip = 1,header=T, 
                                             fill = T, comment.char = "")
                           if (colnames(tbl)[5] == "Cp") {
                             colnames(tbl)[8] <- "CpStatus"
                             df <- tbl[,c("Pos","Cp","CpStatus")]
                           } else if (colnames(tbl)[5] == "Tm1") {
                             # Update: 2016-03-23
                             # 可能出现没有Tm2一列的情况
                             colnames(tbl)[ncol(tbl)] <- "TmStatus"
                             if (!"Tm2" %in% colnames(tbl))
                               tbl$Tm2 <- NA
                             df <- tbl[,c("Pos","Tm1","Tm2" ,"TmStatus")]
                           } else if (colnames(tbl)[5] == "Cycle.") {
                             next
                           } else {
                             # Unknown format
                             next
                           }
                           
                           fh <- file(txtFile)
                           first_line <- readLines(fh,n=1)
                           close(fh)
                           run_name <- sub("Experiment: ","",first_line)
                           run_name <- sub("  Selected Filter:.*","",run_name)
                           channel <- sub(".*\\(([0-9]+)-([0-9]+)\\)","X\\1.\\2",first_line,perl=T)
                           df$Run <- run_name
                           df$Channel <- channel
                           df$Row <- sub("([A-Z]).*","\\1",df$Pos)
                           df$Col <- as.numeric(sub("[A-Z]([0-9]+).*","\\1",df$Pos))
                           
                           if (run_name %in% names(dList)) {
                             # df0 <- merge(df0, df, all.x = T, all.y = T)
                             # df0 <- merge(df0, df, by = intersect(colnames(df),colnames(df0)))
                             # df0 <- merge(df0, df, by = c("Pos","Run","Channel","Col","Row"))
                             dList[[run_name]] <- merge(dList[[run_name]], df, all.x = T, all.y = T)
                             print(run_name)
                           } else {
                             dList[[run_name]] <- df
                             print(ncol(df))
                           }
                         }
                         incProgress(0.9/nfiles, message = "Loading files ...")
                       }
                       # print(dList)
                       df0 <- do.call("rbind",dList)
                       
                       if (!exists("df0")) {
                         print("NO Data FOUND.")
                         exit
                       }
                       
                       ## write to Excel
                       
                       modifyBaseFont(rv$wb, fontSize = 10, fontName = "Calibri")
                       sheetName <- "Cp TM Data"
                       if (sheetName %in% names(rv$wb)) {
                         removeWorksheet(rv$wb, sheetName)
                       }
                       color <- rgb(runif(1),runif(1),runif(1))
                       addWorksheet(rv$wb, sheetName, tabColour = color, gridLines = TRUE)
                       writeDataTable(rv$wb, sheet = sheetName, x = df0, colNames = TRUE,tableStyle="TableStyleLight9")

                       if ("Cp" %in% colnames(df0)) {
                         for (run in unique(df0$Run)) {
                           for (channel in unique(df0$Channel)) {
                             cp <- cast(df0[df0$Run == run & df0$Channel == channel,], Row~Col,value = "Cp")
                             # sheetname <- paste(substr(run,1,19),channel,"Cp")
                             sheetname <- paste(substrRight(run,19),channel,"Cp")
                             if (sheetname %in% names(rv$wb)) {
                               removeWorksheet(rv$wb, sheetname)
                             }
                             color <- rgb(runif(1),runif(1),runif(1))
                             addWorksheet(rv$wb, sheetName = sheetname, tabColour = color, gridLines = TRUE)
                             cp2 <- as.data.frame(cp)
                             writeDataTable(rv$wb, sheet = sheetname, x = cp2, colNames = TRUE,tableStyle="TableStyleLight2")
                           }
                         }
                       }

                       if ("Tm1" %in% colnames(df0) ) {
                         df0$Tm <- paste3(df0$Tm1,df0$Tm2)
                         for (run in unique(df0$Run)) {
                           for (channel in unique(df0$Channel)) {
                             cp <- cast(df0[df0$Run == run & df0$Channel == channel,], Row~Col,value = "Tm")
                             # sheetname <- paste(substr(run,1,19),channel,"Tm")
                             sheetname <- paste(substrRight(run,19),channel,"Tm")
                             if (sheetname %in% names(rv$wb)) {
                               removeWorksheet(rv$wb, sheetname)
                             }
                             color <- rgb(runif(1),runif(1),runif(1))
                             addWorksheet(rv$wb, sheetName = sheetname, tabColour = color, gridLines = TRUE)
                             cp2 <- as.data.frame(cp)
                             writeDataTable(rv$wb, sheet = sheetname, x = cp2, colNames = TRUE,tableStyle="TableStyleLight2")
                           }
                         }
                       }
                       
                       pctqc <- ggplot(df0, aes(x=Run, y=Cp, fill=Run)) +
                         geom_boxplot(color="darkgray", alpha=0.1,outlier.shape = NA) +
                         geom_jitter(width = 0.5, color="lightcoral", alpha=0.3) +
                         labs(x = "Run", y = "CT Value") +
                         theme_bw() + 
                         theme(axis.text.x = element_text(angle = 90)) +
                         guides(fill=FALSE)
                       
                       
                       
                       incProgress(0.1, "Job done.")
                       output$plot <- renderPlot(pctqc)
                       output$text <- renderPrint(paste("Job done.", Sys.time()))

                     } else if (input$task == "data_ready") {
                       
                       #########      提供格式化的数据        ##########
                       options(stringsAsFactors = FALSE)
                       
                       if (!"PCR_Layout_Template.xlsx" %in% input$files$name) {
                         stop(paste("ERROR 1:","PCR_Layout_Template.xlsx not exists.",sep = " "))
                       }
                       filepath <- function(x) {input$files$datapath[input$files$name == x]}
                       template_filepath <- filepath("PCR_Layout_Template.xlsx")
                       # HK genes
                       schema2 <- read.xlsx(template_filepath,sheet=2,colNames=T,
                                            cols=1:2)
                       # CT,TM datasheet
                       schema5 <- read.xlsx(template_filepath,sheet=5,colNames=T,
                                            cols=1:11)
                       # compare
                       schema4 <- read.xlsx(template_filepath,sheet=4,colNames=T,
                                            cols=2:4)
                       symbolList <- schema5$GENE[schema5$GENE!="[SKIP]"] %>% unique
                       
                       incProgress(0.1, "Experiment schema read.")

                       # all_samples <- unique(unlist(samples_per_array))
                       all_samples <- unique(schema5$SAMPLE)
                       
                       all_groups <- schema5$GROUP
                       names(all_groups) <- schema5$SAMPLE
                       all_groups <- all_groups[!duplicated(names(all_groups))]

                       # 确定需要进行数据分析的样本。不进行数据分析的样本，在进行看家基因选择时不考虑
                       sample_analysis <- rep(F,length(all_samples))
                       
                       # check compare name 必须同时是两组或两个样本比较
                       if ( !((all(schema4$A %in% all_samples) & all(schema4$B %in% all_samples)) |
                            (all(schema4$A %in% all_groups) & all(schema4$B %in% all_groups))) ) {
                         stop("Compare name defined error!")
                       }
                       
                       for (i in unique(unlist(schema4[,1:2])) ) {
                         if (i %in% all_samples) {
                           sample_analysis[all_samples == i] <- TRUE
                         }
                         if ( i %in% all_groups ) {
                           sample_analysis[all_samples %in% names(all_groups[all_groups==i])] <- TRUE
                         }
                         if ( ! i %in% all_samples && ! i %in% all_groups) {
                           stop(paste("ERROR 3:",i,"not declared.",sep = " "))
                         }
                       }
                       
                       # 判断是否是miRNA芯片
                       if ( any(grepl("\\w\\w\\w-\\w\\w\\w-\\d",schema5$GENE,perl=T)) ) {
                         array_type = "miRNA"
                       } else {
                         array_type = "gene"
                       }
                       if (nrow(schema2) > 0) {
                         normalization.method <- "HK"
                       } else {
                         normalization.method <- "median"
                       }
                       incProgress(0.2, "File check finish.")
                       
                       # 合并技术重复
                       schema5$CT <- apply(X = schema5[,grepl(pattern = "CT\\d",
                                      x = colnames(schema5))], MARGIN = 1,
                                      FUN = mean, na.rm = T)
                       
                       schema5$TM <- apply(X = schema5[,grepl(pattern = "TM\\d",x = colnames(schema5))], MARGIN = 1,
                             FUN = function(x) { strsplit(x %>% as.character, split = ", ") %>% unlist %>% as.numeric %>% median(na.rm=T)})

                       isDP <- apply(X = schema5[,grepl(pattern = "TM\\d",x = colnames(schema5))], MARGIN = 1,
                             FUN = function(x) { (strsplit(x %>% as.character, split = ", ") %>% lapply(FUN = length) %>% unlist > 1) %>% all})
                       
                       isHK <- schema5$GENE %in% schema2$Housekeeping.Gene.Symbol
                                              
                       dataTbl <- data.frame(symbol=schema5$GENE,sample=schema5$SAMPLE,geneid=schema5$GENE_ID,primerid=schema5$PRIMER_ID,
                                             pos=NA,ct=schema5$CT,tm1=NA,tm2=NA,opt.tm=schema5$TM,
                                             istmoutlier1=NA,istmoutlier2=NA,
                                             ishousekeeping=isHK,isdoublepeak=isDP,
                                             tmlowerlimit=NA,tmupperlimit=NA,
                                             qual=0)
                       
                       # 1   TM outlier compare to archive data
                       # 2   none GDC CT > 35 or GDC CT < 35
                       # 4	  double peak
                       # 8	  TM outlier among same batch data
                       # 16	Detector Call uncertain / Late Cp call
                       # 32	No CT
                       if (array_type == "miRNA") {
                         qc_cutoff <- 4
                         min_CI = 2 # min tm confidence interval
                       } else if (array_type == "gene") {
                         qc_cutoff <- 10
                         min_CI = 0.6 # min tm confidence interval
                       }
                       
                       con <- dbConnect(RMySQL::MySQL(), user = 'ctnet',
                                        password='ctnet', host='localhost',db='ctnet')
                       
                       for (i in 1:nrow(dataTbl)) {
                         istmoutlier1 <- NA
                         istmoutlier2 <- NA
                         outlimit2 <- c(NA,NA)
                         if( !is.na(dataTbl$opt.tm[i]) ) {
                           # determin is TM outlier in this experiment
                           tms <- dataTbl[dataTbl$symbol == dataTbl$symbol[i],"opt.tm"]
                           iqr <- IQR(tms,na.rm=T)
                           outlimit2 <- c(quantile(tms,1/4,na.rm=T) - 1.5*iqr, quantile(tms,3/4,na.rm=T) + 1.5*iqr)
                           
                           if (outlimit2[2] - outlimit2[1] < min_CI) {
                             mean_limit2 = mean(outlimit2)
                             outlimit2[1] = mean_limit2 - 0.5*min_CI
                             outlimit2[2] = mean_limit2 + 0.5*min_CI
                           }
                           
                           istmoutlier2 <- TRUE
                           opt.tm <- dataTbl$opt.tm[i]
                           if (all(c(opt.tm >= outlimit2[1], opt.tm <= outlimit2[2], !is.na(opt.tm)) ) ) {
                             istmoutlier2 <- FALSE
                           }
                           
                           # determine is TM a outlier compared to previous records
                           if ( !is.na(dataTbl$primerid[i]) ) {
                             res <- dbSendQuery(con, paste("SELECT tm1,tm2 FROM PCR_experiment
                                                           WHERE primer_id = '",dataTbl$primerid[i],"'",sep=""))
                             tms <- as.numeric(na.omit(unlist(dbFetch(res))))
                             dbClearResult(res)
                             if (length(tms) > 0) {
                               iqr <- IQR(tms)
                               outlimit1 <- c(quantile(tms,1/4) - 1.5*iqr, quantile(tms,3/4) + 1.5*iqr)
                               istmoutlier1 <- FALSE
                               if ( opt.tm < outlimit1[1] || opt.tm > outlimit1[2] ) {
                                 istmoutlier1 <- TRUE
                               }
                             }
                           }
                         }
                         
                         qual <- 0
                         ct <- dataTbl$ct[i]
                         if ( dataTbl$symbol[i] == 'GDC' ) {
                           if ( !is.na(ct) && ct < 35 ) qual <- qual + 2
                         } else {
                           if ( is.na(ct) ) {
                             qual <- qual + 32
                           } else if ( ct > 35 ) {
                             qual <- qual + 2
                           }
                         }
                         if ( dataTbl$isdoublepeak[i] ) qual <- qual + 4
                         if ( !is.na(istmoutlier1) & istmoutlier1 ) qual <- qual + 1
                         if ( !is.na(istmoutlier2) & istmoutlier2 ) qual <- qual + 8
                         dataTbl$istmoutlier1[i] <- istmoutlier1
                         dataTbl$istmoutlier2[i] <- istmoutlier2
                         dataTbl$tmlowerlimit[i] <- outlimit2[1]
                         dataTbl$tmupperlimit[i] <- outlimit2[2]
                         dataTbl$qual[i] <- dataTbl$qual[i] + qual
                       }

                       incProgress(0.2, "Raw data QC checked.")
                       
                       if (array_type == "gene") {
                         # retrive gene table list
                         geneTbl <- data.frame(Symbol=character(),"Gene ID"=numeric(),
                                               "Gene Name"=character(), "Species"=character(),
                                               Synonyms=character(),"Type of Gene"=character())
                         
                         for (s in schema5$GENE_ID %>% unique) {
                           sth <- dbSendQuery(con, paste("SELECT gene_symbol, gene_id,
                                                         gene_name,common,synonyms,type_of_gene FROM gene
                                                         LEFT join species on tax_id = id
                                                         WHERE gene_id = ", s, sep=""))
                           res <- dbFetch(sth)
                           dbClearResult(sth)
                           geneTbl <- rbind(geneTbl, res) 
                         }
                         colnames(geneTbl) <- toupper(colnames(geneTbl))
                         # print("Gene table sheet created.")
                       }
                       
                       sort_col <- function(df) {
                         return(df[,c("symbol",naturalsort(colnames(df[,-1])))])
                       }
                       
                       is.outlier <- function(x) {
                         iqr <- IQR(x,na.rm = T)
                         y <- quantile(x,3/4,na.rm = T) + 1.5*iqr # 理论是1.5倍
                         ## meam gene qc >= 2* qc_cutoff
                         # y2 <- 2 * qc_cutoff * length(symbolList)
                         # x > min(c(y, y2))
                         x > y
                       }
                       
                       # Assay QC
                       assayQC <- aggregate(opt.tm ~ symbol, data=dataTbl, sd, na.rm=T)
                       assayQC <- merge(x = assayQC, by="symbol", all=T,
                                        y = aggregate(ct ~ symbol, data=dataTbl,
                                                      function(x){length(x[x<35])}))
                       assayQC <- merge(x = assayQC, by="symbol", all=T,
                                        y = aggregate(ct ~ symbol, data=dataTbl,
                                                      function(x){length(x[x>=35])}))
                       assayQC <- merge(x = assayQC, by="symbol", all=T,
                                        y = aggregate(ct ~ symbol, data=dataTbl,
                                                      function(x){length(all_samples) - length(x)}))
                       assayQC <- merge(assayQC, aggregate(isdoublepeak ~ symbol, data=dataTbl,
                                                           function(x){sum(as.logical(x))}), all=T)
                       assayQC <- merge(assayQC, aggregate(qual ~ symbol, data=dataTbl,sum), all=T)
                       assayQC$is.qc.outlier <- is.outlier(assayQC$qual)
                       colnames(assayQC) <- c("SYMBOL", "TM SD", "CT<35","CT>=35","CT NULL","DOUBLE PEAKS","QUAL","IS_OUTLIER")
                       assayQC$`CT NULL`[is.na(assayQC$`CT NULL`)] <- length(all_samples)
                       if (length(assayQC$SYMBOL[assayQC$IS_OUTLIER]) > 0) {
                         print(paste(
                           paste(assayQC$SYMBOL[assayQC$IS_OUTLIER], collapse = ", "),
                           "failed the QC test.", collapse = " "))
                       }
                       
                       # Sample QC
                       sampleQC <- aggregate(ct ~ sample, data=dataTbl, function(x){length(x[x<35])})
                       sampleQC <- merge(x = sampleQC, by="sample", all=T,
                                         y = aggregate(ct ~ sample, data=dataTbl,
                                                       function(x){length(x[x>=35])}))
                       sampleQC <- merge(x = sampleQC, by="sample", all=T,
                                         y = aggregate(ct ~ sample, data=dataTbl,
                                                       function(x){length(symbolList) - length(x)}))
                       sampleQC <- merge(sampleQC, aggregate(isdoublepeak ~ sample, data=dataTbl,
                                                             function(x){sum(as.logical(x))}), all=T)
                       sampleQC <- merge(sampleQC, aggregate(qual ~ sample, data=dataTbl,sum), all=T)
                       colnames(sampleQC) <- c("sample", "CT<35","CT>=35","CT NULL","DOUBLE PEAKS","QUAL_SUM")
                       sampleQC <- merge(sampleQC, aggregate(qual ~ sample, data=dataTbl,min), all=T)
                       sampleQC$is.qc.outlier <- is.outlier(sampleQC$QUAL_SUM)
                       colnames(sampleQC) <- c("SAMPLE", "CT<35","CT>=35","CT NULL","DOUBLE PEAKS","QUAL_SUM","QUAL_MIN", "IS_OUTLIER")
                       ## sample min qc >= qc_cutoff is set to be a outlier 2016-11-18
                       sampleQC$IS_OUTLIER[sampleQC$QUAL_MIN >= qc_cutoff] <- TRUE
                       ## sample average gene QC <= qc_cutoff * 0.5 is set to be normal 2017-1-16
                       sampleQC$IS_OUTLIER <- sampleQC$IS_OUTLIER &
                         sampleQC$QUAL_SUM > length(symbolList) * qc_cutoff * 0.5
                       if (length(sampleQC$SAMPLE[sampleQC$IS_OUTLIER]) > 0) {
                         print(paste(
                           paste(sampleQC$SAMPLE[sampleQC$IS_OUTLIER], collapse = ", "),
                           "failed the QC test.", collapse = " "))
                         sample_analysis[match(sampleQC$SAMPLE[sampleQC$IS_OUTLIER], all_samples)] <- FALSE
                       }
                       
                       # Data Table & QC
                       rawCt <- sort_col(cast(dataTbl, symbol~sample,value = "ct"))
                       rawTm <- sort_col(cast(dataTbl, symbol~sample,value = "opt.tm"))
                       rawQc <- sort_col(cast(dataTbl, symbol~sample,value = "qual"))
                       rawPos <- ddply(dataTbl, .(symbol), summarise,
                                       Pos=paste(unique(pos), collapse = ",") )
                       rawTbl <- cbind(rawPos,rawCt[,-1],rawTm[,-1],rawQc[,-1])
                       # wellTbl <- schema1[,c("Symbol","Well")]
                       # rawTbl <- merge(wellTbl,rawTbl,by.x = "Symbol",by.y= "symbol")
                       
                       incProgress(0.1, "Data & QC table sheet created.")
                       
                       # dataTblQc10 <- dataTbl[dataTbl$qual < qc_cutoff,]
                       dataTblQc10 <- dataTbl[dataTbl$qual < qc_cutoff & # QC 小于阈值
                                                !(dataTbl$sample %in% sampleQC$sample[sampleQC$is.qc.outlier]) &
                                                !(dataTbl$symbol %in% assayQC$symbol[assayQC$is.qc.outlier]),]
                       
                       rawCtQc10 <- cast(dataTblQc10, symbol~sample,value = "ct")

                       # delta-delta CT result sheet
                       # check HK
                       if (normalization.method == "HK") {
                         hks_valid <- array()
                         for (hks in schema2$Housekeeping.Gene.Symbol) {
                           if (all(dataTbl[dataTbl$symbol == hks &
                                           dataTbl$sample %in% all_samples[sample_analysis],"qual"] < qc_cutoff))
                             hks_valid <- c(hks_valid,hks)
                         }
                         if (length(hks_valid) == 1)
                           stop("ERROR 4: All HK genes failed QC checking.")
                       } else if (normalization.method == "median") {
                         # use median normalization when no HK gene provided
                         valid_symbol <- intersect(na.omit(rawCt)$symbol, na.omit(rawTm)$symbol)
                         median_ct <- apply(rawCt[rawCt$symbol %in% valid_symbol,-1],MARGIN = 2,median)
                         names(median_ct) <- colnames(rawCt[,-1])
                       }
                       
                       # calculate delta CT for each sample
                       deltaCt <- data.frame(symbol=character(),sample=character(),delta_ct=numeric())
                       for (k in all_samples[sample_analysis] ) {
                         if (normalization.method == "HK") {
                           hks_avg_ct <- mean(rawCtQc10[rawCtQc10$symbol %in% hks_valid,k],na.rm=T)
                         } else if (normalization.method == "median") {
                           hks_avg_ct <- median_ct[k]
                         }
                         for (j in symbolList ) {
                           # skip HK genes
                           if (j %in% schema2$Housekeeping.Gene.Symbol)
                             next
                           if (j %in% c("GDC","PPC","RTC","PPC1","RTC1","PPC2","RTC2","PPC3","RTC3",
                                        "NEG1","NEG2","NEG3","NEG4") )
                             next
                           ct_raw <- rawCtQc10[rawCtQc10$symbol == j, k]
                           if (length(ct_raw) == 0)
                             next
                           delta_ct <- ct_raw - hks_avg_ct
                           deltaCt <- rbind(deltaCt, data.frame(symbol=j,sample=k,delta_ct))
                         }
                       }
                       rownames(deltaCt) <- NULL
                       deltaCtCasted <- sort_col(cast(deltaCt, symbol~sample,value = "delta_ct"))
                       
                       incProgress(0.1, "HK gene QC checked.")

                       colIndex <- function(df, colId) {
                         colname <- colnames(df)
                         return(grep(colId,colname))
                       }
                       
                       # save data Table 
                       options("openxlsx.borderColour" = "#4F80BD")
                       options("openxlsx.borderStyle" = "thin")
                       modifyBaseFont(rv$wb, fontSize = 10, fontName = "Arial Narrow")
                       headSty <- createStyle(fgFill="#DCE6F1", halign="center",
                                              border = "TopBottomLeftRight")
                       
                       
                       # raw data sheet
                       sheetName <- "Raw Data and QC"
                       if (sheetName %in% names(rv$wb)) {
                         removeWorksheet(rv$wb, sheetName)
                       }
                       addWorksheet(rv$wb, sheetName, gridLines = FALSE, zoom = 150)
                       freezePane(rv$wb, sheet = 1, firstRow = TRUE, firstCol = TRUE)
                       ## freeze first row and column
                       writeDataTable(rv$wb, sheet = 1, x = dataTbl, colNames = TRUE,
                                      rowNames = FALSE, tableStyle = "TableStyleLight9")
                       
                       if (array_type == "gene") {
                         # gene sheet
                         sheetName <- "Gene Table"
                         if (sheetName %in% names(rv$wb)) {
                           removeWorksheet(rv$wb, sheetName)
                         }
                         addWorksheet(rv$wb, sheetName, gridLines = FALSE, zoom = 150)
                         freezePane(rv$wb, sheet = "Gene Table", firstRow = TRUE,
                                    firstCol = F) ## freeze first row and column
                         setColWidths(rv$wb, sheet = 2, cols = "D", widths = 50)
                         setColWidths(rv$wb, sheet = 2, cols = "F", widths = 20)
                         setColWidths(rv$wb, sheet = 2, cols = "G", widths = 13)
                         writeData(rv$wb, sheet = "Gene Table", x = geneTbl, startCol = "A", startRow=1,
                                   borders="rows", headerStyle = headSty)
                       }
                       
                       # raw sheet
                       sheetName <- "Data Table"
                       if (sheetName %in% names(rv$wb)) {
                         removeWorksheet(rv$wb, sheetName)
                       }
                       addWorksheet(rv$wb, sheetName, gridLines = FALSE, zoom = 150)
                       freezePane(rv$wb, sheet = "Data Table", firstActiveRow = 3,firstActiveCol = 'B')
                       ## freeze first row and column
                       writeData(rv$wb, "Data Table", x = rawTbl, startCol = "A", startRow=2, borders="rows",
                                 headerStyle = headSty)
                       writeData(rv$wb, "Data Table", x = "CT", startCol = 4, startRow = 1)
                       writeData(rv$wb, "Data Table", x = "TM", startCol = length(all_samples) + 4, startRow = 1)
                       writeData(rv$wb, "Data Table", x = "QC", startCol = 2*length(all_samples) + 4, startRow = 1)
                       s1 <- createStyle(fontSize=14, textDecoration=c("bold", "italic"))
                       addStyle(rv$wb, "Data Table", style = s1, rows=c(1,1,1), cols=(0:2) * length(all_samples) + 4)
                       
                       sheetName <- "Assay QC"
                       if (sheetName %in% names(rv$wb)) {
                         removeWorksheet(rv$wb, sheetName)
                       }
                       addWorksheet(rv$wb, sheetName, gridLines = FALSE, zoom = 150)
                       freezePane(rv$wb, sheet = "Assay QC", firstRow = T, firstCol = F)
                       writeData(rv$wb, sheet = "Assay QC", x = assayQC, startCol = "A", startRow=1,
                                 borders="rows", headerStyle = headSty)
                       
                       sheetName <- "Sample QC"
                       if (sheetName %in% names(rv$wb)) {
                         removeWorksheet(rv$wb, sheetName)
                       }
                       addWorksheet(rv$wb, sheetName = "Sample QC", gridLines = FALSE, zoom = 150)
                       freezePane(rv$wb, sheet = "Sample QC", firstRow = T, firstCol = F)
                       writeData(rv$wb, sheet = "Sample QC", x = sampleQC, startCol = "A", startRow=1,
                                 borders="rows", headerStyle = headSty)
                       
                       # ΔΔCT compare
                       for (i in 1:nrow(schema4)) {
                         if (nrow(schema4) == 0) break
                         A <- schema4$A[i]
                         B <- schema4$B[i]
                         
                         cmp_name <- paste(A,"vs",B,sep=" ")
                         sheet_name <- substr(cmp_name,1,31)
                         if (sheet_name %in% names(rv$wb)) {
                           removeWorksheet(rv$wb, sheet_name)
                         }
                         addWorksheet(rv$wb, sheetName = sheet_name, gridLines = FALSE, zoom = 150)
                         freezePane(rv$wb, sheet = sheet_name, firstRow = T, firstCol = F)
                         UpStyle <- createStyle(textDecoration = "bold", fontColour = "#9C0006")
                         DownStyle <- createStyle(textDecoration = "bold", fontColour = "#006100")
                         
                         # deltaTbl <- data.frame(symbol=character(),sample=character(),deltaCt=numeric())
                         plotxy <- data.frame()
                         
                         if (A %in% all_samples[sample_analysis] & B %in% all_samples[sample_analysis]) {
                           print("sample compare")
                           deltaTbl <- deltaCt[deltaCt$sample %in% c(A,B), ]
                           ddCt <- cast(deltaTbl, symbol~sample,value = "delta_ct")
                           ddCt$delta.delta.Ct <- NA
                           for ( t in 1:nrow(ddCt) ) {
                             ddCt[t,"delta.delta.Ct"] = ddCt[t, A] - ddCt[t, B]
                             ddCt[t, "ratio"] = 2 ^ (-1 * ddCt[t,"delta.delta.Ct"])
                             ddCt[t, "log ratio"] = -1 * ddCt[t,"delta.delta.Ct"]
                             ddCt[t, "fold change"] = ddCt[t,"ratio"]
                             if (!is.na(ddCt[t,"ratio"]))
                               if (ddCt[t,"ratio"] < 1)
                                 ddCt[t, "fold change"] = -1/ddCt[t,"ratio"]
                           }
                           ddCt <- ddCt[,c("symbol",A,B,"delta.delta.Ct", "ratio","log ratio","fold change")]
                           # plotxy <- data.frame(A = 2^-ddCt[, A], B = 2^-ddCt[, B], C = log2(2^-ddCt[, A] / 2^-ddCt[, B]))
                           plotxy <- data.frame(A = -ddCt[, A], B = -ddCt[, B],
                                                C = log2(2^-ddCt[, A] / 2^-ddCt[, B]))
                         }
                         else if (A %in% all_groups & B %in% all_groups) {
                           print("group compare")
                           sA <- all_samples[all_groups==A & sample_analysis]
                           sB <- all_samples[all_groups==B & sample_analysis]
                           
                           deltaTbl <- deltaCt[deltaCt$sample %in% c(sA,sB), ]
                           ddCt <- cast(deltaTbl, symbol~sample,value = "delta_ct")
                           # 样本名自然排序
                           ddCt <- ddCt[,c("symbol",naturalsort(colnames(ddCt[,-1])))]
                           print("calculate delta Ct")
                           for ( t in nrow(ddCt):1 ) {
                             if ( length(na.omit(as.numeric(ddCt[t, sA]))) < 2 |
                                  length(na.omit(as.numeric(ddCt[t, sB]))) < 2) {
                               ddCt <- ddCt[-t,]
                               next
                             }
                             ddCt[t,"delta.delta.Ct"] =  mean(as.numeric(ddCt[t, sA]), na.rm=T) -
                               mean(as.numeric(ddCt[t, sB]), na.rm=T)
                             ddCt[t, "ratio"] = 2 ^ (-1 * ddCt[t,"delta.delta.Ct"])
                             ddCt[t, "log ratio"] = -1 * ddCt[t,"delta.delta.Ct"]
                             ddCt[t, "fold change"] = ddCt[t,"ratio"]
                             if (ddCt[t,"ratio"] < 1)
                               ddCt[t, "fold change"] = -1/ddCt[t,"ratio"]
                             if (grepl(x = schema4$IsPaired[i], pattern = "Y", ignore.case = T) ) {
                               pdata <- data.frame(g1=as.numeric(ddCt[t, sA]),g2=as.numeric(ddCt[t, sB]) )
                               if (nrow(na.omit(pdata)) >= 2)
                                 pval <- t.test(pdata$g1, pdata$g2, paired = TRUE, var.equal = TRUE)$p.value
                               else
                                 pval <- NA
                             } else
                               pval <- t.test(as.numeric(ddCt[t, sA]), as.numeric(ddCt[t, sB]), paired = FALSE, var.equal = TRUE)$p.value
                             ddCt[t, "p value"] <- pval
                           }
                           # plotxy <- data.frame(A = 2^-apply(ddCt[, sA], 1,mean), B = 2^-apply(ddCt[, sB], 1,mean),
                           plotxy <- data.frame(A = -apply(ddCt[, sA], 1, mean, na.rm=T),
                                                B = -apply(ddCt[, sB], 1, mean, na.rm=T),
                                                C = log2(2^-apply(ddCt[, sA], 1,mean, na.rm=T) / 2^-apply(ddCt[, sB], 1,mean, na.rm=T)))
                           pv_col = colIndex(ddCt, "p value")
                           conditionalFormatting(rv$wb, sheet_name, cols=pv_col, rows = 2:nrow(ddCt),
                                                 rule="<0.05", style = UpStyle)
                         }
                         else {
                           print(paste("Compare",i,"is not supported.",sep=" "))
                         }
                         
                         setColWidths(rv$wb, sheet = sheet_name, cols = 1:ncol(ddCt), widths = 10)
                         writeData(rv$wb, sheet_name, x = ddCt[,1:ncol(ddCt)], startCol = "A", startRow=1,
                                   borders="rows", headerStyle = headSty)
                         
                         print("make scatter plot.")
                         d <- qplot(data=plotxy, x = B, y= A, xlab=B,ylab=A,colour= C,size=0.8)
                         p <- ggplot(plotxy, aes(B, A,color = plotxy$C)) +
                           geom_point( size = 1) +
                           geom_abline(intercept = 1, color="firebrick1") +
                           geom_abline(intercept = -1, color="limegreen") +
                           xlab(B) + ylab(A) +
                           scale_colour_gradient2("log2 ratio", midpoint = 0,#, limits=c(-2, 2)
                                                  low = muted("green"), mid = "snow3", high = muted("red")) +
                           theme_bw()
                         pngfile = paste(A,B,".png",sep="")
                         png(filename = pngfile,width=6,height=5,units="in",res=300)
                         print(p)
                         dev.off()
                         # insertPlot(wb, sheet = 3+i, startCol = ncol(ddCt) + 2)
                         insertImage(rv$wb, sheet = sheet_name, file = pngfile, width = 6, 
                                     height = 5, startRow = 2, startCol = ncol(ddCt) + 1, 
                                     units = "in", dpi = 300)
                         
                         if (length(symbolList) >= 384) {
                           # make volcano plot
                           dat1 <- data.frame(x=as.numeric(ddCt$`log ratio`), y=-log10(ddCt$`p value`), ID=ddCt$symbol)
                           dat2 <- na.omit(dat1)
                           if (array_type == "miRNA") {
                             dat2$ID <- sub(pattern = "^...-", replacement = "", x = dat2$ID,perl = T)
                           }
                           mask <-  with(dat2, y>-log10(0.05) & abs(x)>1)
                           cols <- ifelse(mask, "firebrick1", "grey")
                           p2 <- ggplot(dat2, aes(x, y, label= ID)) +
                             geom_point(color = cols, size = 0.8) +
                             geom_vline(xintercept = 1, color = "dodgerblue", linetype="longdash") + #add vertical line
                             geom_vline(xintercept = -1, color = "dodgerblue", linetype="longdash") + #add vertical line
                             geom_hline(yintercept = -log10(0.05), color = "deeppink", linetype="longdash") +  #add vertical line
                             labs(x="log2(Fold-change)", y="-log10(P.Value)") + 
                             scale_x_continuous("log2(Fold-change)") +
                             scale_y_continuous("-log10(P.Value)", limits = range(0,max(dat2$y)+0.2)) +
                             annotate("text", x=dat2$x[mask], y=dat2$y[mask], 
                                      label=dat2$ID[mask], size=dat2$y[mask], 
                                      vjust=-0.1, hjust=-0.1, color="lightsteelblue4") +
                             theme_bw()
                           pngfile2 = paste(A,B,".vp.png",sep="")
                           png(filename = pngfile2,width=5,height=5,units="in",res=300)
                           print(p2)
                           dev.off()
                           # insertPlot(wb, sheet = 3+i, startCol = ncol(ddCt) + 2)
                           insertImage(wb = rv$wb, sheet = sheet_name, file = pngfile2, width = 5, 
                                       height = 5, startRow = 30, startCol = ncol(ddCt) + 1, 
                                       units = "in", dpi = 300)
                         }
                         # conditional formatting
                         log_col = colIndex(ddCt, "log ratio")
                         fc_cf_col = colIndex(ddCt, "fold change")
                         conditionalFormatting(rv$wb, sheet_name, cols=log_col, rows = 1:nrow(ddCt)+1,
                                               rule=">=1", style = UpStyle)
                         conditionalFormatting(rv$wb, sheet_name, cols=log_col, rows = 1:nrow(ddCt)+1,
                                               rule="<=-1", style = DownStyle)
                         conditionalFormatting(rv$wb, sheet_name, cols=fc_cf_col, rows = 1:nrow(ddCt)+1,
                                               rule=">=2", style = UpStyle)
                         conditionalFormatting(rv$wb, sheet_name, cols=fc_cf_col, rows = 1:nrow(ddCt)+1,
                                               rule="<=-2", style = DownStyle)
                         
                         # number formatting
                         twodigit <- createStyle(numFmt = "0.00",border="Bottom")
                         addStyle(rv$wb, sheet_name, style = twodigit, cols = 2:fc_cf_col,
                                  rows = 1:nrow(ddCt)+1, gridExpand = T)
                         
                         # fig lengend
                         #note <- "上图是对两个样本间每个基因的相对表达比值(2-ΔCT)的LOG2转换值做散点图。每个点以该基因的LOG表达比值LOG2(ratio)用颜色表示其差异倍数。红色越深，图上越靠近左上方为上调倍数越大，绿色越深，图上越靠近右下方为下调倍数越大。颜色越浅， 差异倍数越小。注：未表达或表达异常的基因未包括在图中。"
                         #com <- createComment(comment = note, author = "CT Bioscience", style = NULL,
                         #              visible = TRUE, width = 7, height = 4)
                         #writeComment(wb = wb, sheet = sheet_name, col = ncol(ddCt)+2,row = 29, comment = com)
                       }
                       
                       print("Add note sheet.")
                       
                       sheetName <- "QC Plot"
                       if (sheetName %in% names(rv$wb)) {
                         removeWorksheet(rv$wb, sheetName)
                       }
                       addWorksheet(rv$wb, sheetName, gridLines = FALSE, zoom = 150)
                       writeData(rv$wb, sheet = "QC Plot", x = c("QC quality (sum of following conditions):",
                                                                 "1  TM outlier compare to archive data",
                                                                 "2  none GDC CT > 35 or GDC CT < 35",
                                                                 "4  Double Peak",
                                                                 "8  TM outlier among same batch data",
                                                                 "16 Detector Call uncertain/Late Cp call",
                                                                 "32 No Detect"))
                       
                       # check bad gene & bad sample
                       qc.matrix <- as.matrix(rawQc[,-1])
                       gene.qc <- apply(X = qc.matrix, MARGIN = 1, FUN = sum, na.rm=T)
                       
                       dataTbl$symbol <- factor(dataTbl$symbol, levels = rawQc$symbol[order(gene.qc)], ordered = T)
                       
                       # class(dataTbl$sample)
                       dataTbl$sample <- factor(dataTbl$sample, levels = naturalsort(unique(dataTbl$sample)))
                       p2 <- ggplot(dataTbl[order(dataTbl$symbol),], aes(sample, symbol, fill = qual)) +
                         geom_tile( colour = "white") +
                         labs(x = "Sample", y = "Gene") +
                         theme(axis.text.x = element_text(angle = 90)) + 
                         scale_fill_gradient(low = "white", high = "steelblue")
                       qcpngfile = "qcheatmap.png"
                       png(filename = qcpngfile,width = length(sample_analysis)/5 + 4, height = 11,units="in",res=300)
                       print(p2)
                       dev.off()
                       insertImage(wb = rv$wb, sheet = "QC Plot", file = qcpngfile,
                                   width = length(sample_analysis)/5 + 4, height = 11,
                                   startRow = 1, startCol = 3,  units = "in", dpi = 300)
                       
                       # Boxplot
                       sheetName <- "CT BOXPLOT"
                       if (sheetName %in% names(rv$wb)) {
                         removeWorksheet(rv$wb, sheetName)
                       }
                       addWorksheet(rv$wb, sheetName, gridLines = FALSE, zoom = 150)
                       p4 <- ggplot(dataTbl[order(dataTbl$symbol),], aes(x=sample, y=ct, fill=sample)) +
                         geom_boxplot(color="darkgray", alpha=0.1,outlier.shape = NA) +
                         geom_jitter(width = 0.5, color="lightcoral", alpha=0.7) +
                         labs(x = "Sample", y = "CT Value") +
                         theme_bw() + 
                         theme(axis.text.x = element_text(angle = 90)) +
                         guides(fill=FALSE)
                       boxpngfile = "boxplot.png"
                       png(filename = boxpngfile,width = length(sample_analysis)/5 + 4, height = 5,units="in",res=300)
                       print(p4)
                       dev.off()
                       insertImage(wb = rv$wb, sheet = "CT BOXPLOT", file = boxpngfile,
                                   width = length(sample_analysis)/5 + 4, height = 5,
                                   startRow = 1, startCol = 1,  units = "in", dpi = 300)
                       
                       # Heatmap
                       sheetName <- "HEATMAP PLOT"
                       if (sheetName %in% names(rv$wb)) {
                         removeWorksheet(rv$wb, sheetName)
                       }
                       addWorksheet(rv$wb, sheetName, gridLines = FALSE, zoom = 150)
                       if (normalization.method == "HK") {
                         writeData(rv$wb, sheet = "HEATMAP PLOT", c("Valid house-keeping gene:",na.omit(hks_valid)))
                       }
                       deltaCt$sample <- factor(deltaCt$sample, levels = naturalsort(unique(deltaCt$sample)))
                       p3 <- ggplot(deltaCt[order(deltaCt$symbol),], aes(sample, symbol, fill = delta_ct)) +
                         geom_tile( colour = "white") +
                         labs(x = "Sample", y = "Gene") +
                         theme(axis.text.x = element_text(angle = 90)) + 
                         guides(fill=guide_legend(title="Delta CT")) +
                         scale_fill_gradient2(low = "brown1", mid="white", high = "lightgreen",
                                              midpoint = median(deltaCt$delta_ct, na.rm = T))
                       dctpngfile = "dctheatmap.png"
                       png(filename = dctpngfile, width = length(sample_analysis)/5 + 4, height = 11,
                           units="in", res=300)
                       print(p3)
                       dev.off()
                       insertImage(wb = rv$wb, sheet = "HEATMAP PLOT", file = dctpngfile,
                                   width = length(sample_analysis)/5 + 4, height = 11,
                                   startRow = 1, startCol = 3,  units = "in", dpi = 300)
                       
                       output$text <- renderPrint(paste("Job done.", Sys.time()))
                       output$plot <- renderPlot(p2)

                     }
                   })
    
    
    

  })
  
  # observeEvent(input$processData2, {
  #   
  #   sheetName <- "Sheet 2"
  #   if (sheetName %in% names(rv$wb)) {
  #     removeWorksheet(rv$wb, sheetName)
  #   }
  #   addWorksheet(rv$wb, sheetName, gridLines = FALSE, zoom = 150)
  #   writeDataTable(rv$wb, sheet = "Sheet 2", x = cars, colNames = TRUE,
  #                  rowNames = FALSE, tableStyle = "TableStyleLight9")
  #   output$contents <- renderPrint("OK2")
  #   
  # })
  
  output$downloadData <- downloadHandler(
    filename = paste("PCRDATA_", Sys.Date(), ".xlsx", sep=""),
    content = function(file) {
     saveWorkbook(rv$wb, file)
    }
  )
})