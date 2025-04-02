library(optparse)

option_list = list( 
  make_option(c("-w", "--windows"), type="numeric", default=1e4, 
              help="Window size (default=10k)"),
  make_option(c("-s", "--step"), type="numeric", default=5e3,
              help="Step size (default=5k)"),
  make_option(c("-n", "--num"), type="numeric", default=30,
              help="minimum number of snps (default=50)"),
  make_option(c("-i", "--input"), type="character",
              help="input file (xp-ehh out file)"),
  make_option(c("-o", "--output"), type="character",
              help="prefix of output")           
)

args <- parse_args(OptionParser(option_list=option_list))           #参数列表传递到列表中


windows_mean <- function(target, W = 1e4, S = 1e3, N = 30) {
  colnames(target) <- c('V1', 'V2')
  target <- target[order(target$V1),]
  len <- max(target$V1)
  data <- data.frame(start = NA, end = NA, value = NA, num = NA)
  i <- 1
  start <- 1
  while (start < len) {
    sub_target <- target$V2[start <= target$V1 & target$V1 <= (start + W - 1)]
    if (length(sub_target) < N) {
      data[i, 1:4] <- c(start, start + W - 1, NA, length(sub_target))
    } else {
      data[i, 1:4] <- c(start, start + W - 1, mean(sub_target), length(sub_target))
    }
    i <- i + 1
    start <- start + S
  }
  return(data)
}


x <- read.table(file = args$i, header = TRUE)
x1 <- x[, c(2, 8)]
x1$pos <- as.numeric(x1$pos)
out <- windows_mean(x1, W = args$w, S = args$s, N = args$n)
colnames(out) <- c('Start', 'End', 'Mean_xpehh', 'Num_snps')
#out$Norm_xpehh <- scale(out$Mean_xpehh)
write.table(out, file = paste0(args$o, '.window-', args$w / 1e3, 'k.step-', args$s / 1e3, 'k.mean.out'), row.names = FALSE, quote = FALSE, sep = '\t')


