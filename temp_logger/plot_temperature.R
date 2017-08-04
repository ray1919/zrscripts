setwd("~/bin/temp_logger")

all.df <- data.frame()

for (file in tail(dir(pattern =  "*.temp.log"), 2) ) {
  day <- strsplit(file, split = "\\.")[[1]][1]
  dat <- read.table(file, sep = "\t", as.is = T)
  temp <- apply(dat[,2:6], 1, max)
  time <- paste(day, dat$V1)
  all.df <- rbind(all.df, data.frame(time, temp))
}

plot(all.df, type="l", ylim=c(20,100), xlab="Timepoint per 2 min", xaxt='n',
     ylab = "CPU Temperature" )
axis_seq <- seq(1,nrow(all.df),100)
axis_lbl <- gsub(pattern = ".*(..) (..)-(..)", replacement = "\\1-\\2:\\3", all.df$time[axis_seq])
axis(1, at=axis_seq, labels=NA)
text(x=axis_seq, y=par()$usr[3]-0.05*(par()$usr[4]-par()$usr[3]),
     labels=axis_lbl, srt=45, adj=1, xpd=TRUE)
abline(h=98, col = "red")
abline(h=80, col = "orange")
abline(h=40, col = "darkgreen")
