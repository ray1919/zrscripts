library(sangerseqR)
for (ab1_file  in dir(pattern = "*.ab1") ){
  hetsangerseq <- readsangerseq(ab1_file)
  png_save = sub(pattern = ".ab1", replacement = ".png", x= ab1_file)
  png(filename = png_save, width = 1600, height = 1200, res = 120)
  Seq1 <- primarySeq(hetsangerseq)
  chromatogram(hetsangerseq, width = 100, trim5 = 0, trim3 = 0,
               showcalls = "primary",showhets = F)
  dev.off()
}
