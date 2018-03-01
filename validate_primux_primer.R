# Date: 2017-11-23
# Author: Zhao
# Purpose: validate primux primer - sequences

library(Biostrings)
library(dplyr)

min_amplicon_length=50
max_amplicon_length=400

primers <- readDNAStringSet("sigs.max.0.fa")
primers

sequences <- readDNAStringSet("fasta")
# sequences <- readDNAStringSet("../../s.citri/GCF_001886855.1_ASM188685v1_genomic.fna")
sequences <- readDNAStringSet("../representative_genomes.fasta")
names(sequences) <- sub(pattern = " .*", replacement = "", names(sequences))

vm <- data.frame()
for (i in 1:length(primers)) {
  primer_name <- names(primers)[i]
  # if (grepl(pattern = "F", x = primer_name) ) {
  #   vm1 <- vmatchPattern(pattern = primers[[i]], subject = sequences, max.mismatch = 0) %>% as.data.frame()
  # } else if (grepl(pattern = "R", x = names(primers)[i]) ) {
  #   vm1 <- vmatchPattern(pattern = primers[[i]] %>% reverseComplement, subject = sequences, max.mismatch = 0) %>% as.data.frame()
  # } else {
  #   stop("primer name error")
  # }
  vmf <- vmatchPattern(pattern = primers[[i]], subject = sequences, max.mismatch = 0, fixed = F) %>% as.data.frame()
  vmr <- vmatchPattern(pattern = primers[[i]] %>% reverseComplement, subject = sequences, max.mismatch = 0, fixed = F) %>% as.data.frame()
  if (nrow(vmf) > 0)
    vmf$strand <- "F"
  if (nrow(vmr) >0 )
    vmr$strand <- "R"
  vm1 <- rbind(vmf, vmr)
  if (nrow(vm1) == 0)
    next
  vm1$primer = primer_name
  vm1$sequence <- names(sequences)[vm1$group]
  vm <- rbind(vm, vm1)
}

primer_match <- data.frame()
for (g in unique(vm$group)) {
  vmf <- filter(vm, group == g & strand == "F")
  vmr <- filter(vm, group == g & strand == "R")
  if (nrow(vmf) == 0 | nrow(vmr) == 0)
    next
  for (i in 1:nrow(vmf)) {
    for (j in 1:nrow(vmr)) {
      amp_len <- vmr$end[j] - vmf$start[i]
      if (amp_len >= min_amplicon_length & amp_len <= max_amplicon_length) {
        primer_match <- rbind(primer_match, data.frame(group = g,
                   SEQ = vmf$sequence[i], FP_NAME = vmf$primer[i], 
                   RP_NAME = vmr$primer[j], FP_START = vmf$start[i], FP_END = vmf$end[i],
                   RP_START = vmr$start[j], RP_END = vmr$end[j], amp_len))
      }
    }
  }
}
primer_match
