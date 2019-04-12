library(Biostrings)
library(GenomicRanges)
library(DBI)
library(dplyr)

# Genomic version hg38

PADDING = 30
setwd("~/ct208/db/sra/jx_201804_mix3")
con <- dbConnect(RMySQL::MySQL(), user = 'ucsc',
                 password='ucsc', host='localhost',db='ucsc_hg38')

target_list <- readLines("memo/rs.txt")

int_df <- data.frame()
for (s in target_list) {
  # start position is 0-based
  if (grepl("^rs\\d+$", x = s, ignore.case=T)) {
    query2 <- paste("SELECT chrom, chromStart, chromEnd from snp150 where chrom not like '%\\_%' and name = '", s, "'", sep="")
    res2 <- dbFetch(dbSendQuery(con, query2))
    int_df <- rbind(int_df, data.frame(chrom=res2$chrom[1], start=res2$chromStart - PADDING, end=res2$chromEnd[1] + PADDING, strand="+", name=s))
  }
}

grsnp <- as(int_df, "GRanges")

grred <- reduce(grsnp) # 0-based position

ol <- findOverlaps(grred, grsnp) %>% as.data.frame()

name <- c()
for (i in 1:length(grred)) {
  name[i] <- paste(grsnp$name[ol$subjectHits[ol$queryHits==i]], collapse = " ")
}

grred$name <- name
df <- as.data.frame(grred)

write(paste(df$seqnames, df$start, df$end, df$name, sep = "\t"), "memo/snp141.bed") # 0-based position
