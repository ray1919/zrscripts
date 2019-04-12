# Date: 2017-10-27
# Author: Zhao
# Purpose: 获取基因所有外显子及所有200bp内含子序列，并标记常见SNP位点。

library(DBI)
library(GenomicRanges)
library(BSgenome.Hsapiens.UCSC.hg38)
library(Biostrings)
library(BSgenome)
library(dplyr)
Hsapiens <- BSgenome.Hsapiens.UCSC.hg38

setwd("~/ct208/tmp/2017-10-20_geneid_to_exon_seq")
INTRON_FLANK_SIZE = 200

snp_inject <- function(SEQ, CHR, START, WIDTH, STRAND) {
  # default to plut strand
  # START 1 based
  # iupac_code <- names(IUPAC_CODE_MAP)
  # names(iupac_code) <- IUPAC_CODE_MAP
  con <- dbConnect(RMySQL::MySQL(), user = 'ucsc',
                   password='ucsc', host='localhost',db='ucsc_hg38')
  
  query2 <- paste("SELECT chromEnd, observed, strand, alleles, alleleFreqs from
                  snp147Common where class = 'single' and chromEnd >= ", START,
                  " and chromEnd <= ", (START + WIDTH - 1), " and chrom = '", CHR, "'", sep="")
  res2 <- dbFetch(dbSendQuery(con, query2))
  # code <- character()
  dbDisconnect(con)
  # if (nrow(res2) > 0) {
  #   for (i in 1:nrow(res2)) {
  #     if (res2$alleles[i] != "") {
  #       observed <- res2$alleles[i]
  #     } else {
  #       observed <- res2$observed[i]
  #     }
  #     nt <- strsplit(x = observed, split = "\\W+", perl = T) %>% unlist %>% sort %>% paste(collapse="")
  #     if (res2$strand[i] == "+") {
  #       code_i <- iupac_code[nt]
  #     } else {
  #       code_i <- iupac_code[nt] %>% DNAString %>% reverseComplement %>% toString
  #     }
  #     code <- c(code, code_i)
  #   }
  # }
  # relative position
  res2$relPos <- res2$chromEnd - START + 1
  if (STRAND == "-") {
    res2$relPos <- WIDTH - res2$relPos + 1
  }
  return <- list()
  # return$injected <- replaceLetterAt(x = SEQ, at = res2$chromEnd - START + 1, letter = code)
  return$poss <- res2$relPos
  return$relPos <- res2
  return(return)
}
# snp_inject(DNAString("ATCGATCGAT"), "chr1", 13111, 10)

subchar2lower <- function(string, pos) { 
  for(i in pos) { 
    string <- gsub(paste("^(.{", i-1, "})(.)", sep=""), "\\1\\L\\2", string, perl = T) 
  } 
  string 
}

retrive_exon_seqs <- function (gene_name) {
  con <- dbConnect(RMySQL::MySQL(), user='ucsc', password='ucsc',
                   dbname='ucsc_hg38', host='localhost')
  query <- paste("select * from refGene where name2 = '", gene_name, "';",
                 sep = "")
  retVal <- dbGetQuery(con, query)
  dbDisconnect(con)
  gl <- GRangesList()
  save_file <- paste(gene_name, ".fasta", sep = "")
  unlink(save_file)
  for (i in 1:nrow(retVal)) {
    Acc = retVal$name[i]
    strand <- retVal$strand[i]
    exon_starts <- strsplit(retVal$exonStarts[i], split = ",") %>% unlist %>% as.integer() + 1
    exon_ends <- strsplit(retVal$exonEnds[i], split = ",") %>% unlist %>% as.integer()
    exon_num <- length(exon_starts)
    exon_id = 1:exon_num
    if (strand == "-") {
      exon_id = exon_num:1
    #   exon_starts <- rev(exon_starts)
    #   exon_ends <- rev(exon_ends)
    }
    
    # if (strand == "+") {
    intron_len <- exon_starts[-1] - exon_ends[-exon_num] - 1
    # } else {
    #   intron_len <- exon_starts[-exon_num] - exon_ends[-1] - 1
    # }
    
    # exon ranges

    gr <- GRanges(seqnames = retVal$chrom[i],
                  ranges = IRanges(start = exon_starts,
                                   end = exon_ends),
                  strand = strand,
                  exon_id = exon_id,
                  intron_len = c(intron_len, 0))

    # flank ranges
    flank_width_start <- c(INTRON_FLANK_SIZE,
                           apply(data.frame(intron_len, INTRON_FLANK_SIZE),
                                 MARGIN = 1, min))
    flank_width_end <- c(apply(data.frame(intron_len, INTRON_FLANK_SIZE),
                                 MARGIN = 1, min), INTRON_FLANK_SIZE)
    if (retVal$strand[i] == "+") {
      flank_start <- flank(gr, width = flank_width_start, start = T)
      flank_end <- flank(gr, width = flank_width_end, start = F)
    } else {
      flank_start <- flank(gr, width = flank_width_end, start = T)
      flank_end <- flank(gr, width = flank_width_start, start = F)
    }
    
    # get seq
    
    exon_seqs <- getSeq(Hsapiens, gr)
    names(exon_seqs) <- paste(Acc, exon_id, sep = "_exon")
    
    flank_start_seq <- getSeq(Hsapiens, flank_start)
    names(flank_start_seq) <- paste(Acc, exon_id, sep = "_FL")
    
    flank_end_seq <- getSeq(Hsapiens, flank_end)
    names(flank_end_seq) <- paste(Acc, exon_id, sep = "_FR")
    
    # snp makr up
    gl_df <- as.data.frame(gl)
    for (j in exon_id) {
      
      if (nrow(gl_df[gl_df$start == start(gr)[j] & gl_df$end == end(gr)[j] & gl_df$seqnames == retVal$chrom[i], ]) > 0) {
        next
      }
      
      exon_ds_j <- exon_seqs[[j]]
      inject_exon <- snp_inject(SEQ = exon_ds_j,
                                CHR = retVal$chrom[i],
                                START = start(gr)[j],
                                WIDTH = width(exon_seqs)[j],
                                STRAND = retVal$strand[i])
      exon_poss <- inject_exon$poss
      exon_seq_j <- subchar2lower(exon_ds_j, exon_poss)
      
      # left flank seq
      FL_ds_j <- flank_start_seq[[j]]
      inject_FL <- snp_inject(SEQ = FL_ds_j,
                              CHR = retVal$chrom[i],
                              START = start(flank_start)[j],
                              WIDTH = width(flank_start_seq)[j],
                              STRAND = retVal$strand[i])
      FL_poss <- inject_FL$poss
      FL_seq_j <- subchar2lower(FL_ds_j, FL_poss)
      
      # right flank seq
      FR_ds_j <- flank_end_seq[[j]]
      inject_FR <- snp_inject(SEQ = FR_ds_j,
                              CHR = retVal$chrom[i],
                              START = start(flank_end)[j],
                              WIDTH = width(flank_end_seq)[j],
                              STRAND = retVal$strand[i])
      FR_poss <- inject_FR$poss
      FR_seq_j <- subchar2lower(FR_ds_j, FR_poss)
      
      # final flanked_exon_seq
      flanked_exon_seq <- paste(FL_seq_j, exon_seq_j, FR_seq_j, sep = "")

      
      # test if it is right
      if (retVal$strand[i] == "+") {
        mp <- matchPattern(pattern = flanked_exon_seq, subject = Hsapiens[[retVal$chrom[i]]])
        if (length(mp) == 1 &
            start(mp) == start(flank_start)[j] &
            end(mp) == end(flank_end)[j]) {
          # print("Matched")
        } else {
          print("Not match")
        }
      } else {
        mp <- matchPattern(pattern = reverseComplement(DNAString(flanked_exon_seq)), subject = Hsapiens[[retVal$chrom[i]]])
        if (length(mp) == 1 &
            start(mp) == start(flank_end)[j] &
            end(mp) == end(flank_start)[j]) {
          # print("Matched")
        } else {
          print("Not match")
        }
      }
      
      write(x = paste(">", names(exon_seqs)[j], " ", width(flank_start_seq)[j],
                      " ", width(exon_seqs)[j], " ", width(flank_end_seq)[j],
            sep = ""), file = save_file, append = T)
      write(x = paste(FL_seq_j, exon_seq_j, FR_seq_j), file = save_file,
            append = T)
      write(x = "\n", file = save_file, append = T)
    }
    gl[[Acc]] <- gr
    
  }
  return(gl)
}

retrive_exon_seqs("EGFR")
