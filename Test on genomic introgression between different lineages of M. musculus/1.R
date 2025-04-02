rm(list=ls())
library(admixtools)
library(tidyverse)


prefix='./data/autosome'


DOM=read.table('DOM.txt')$V1
BAC=read.table('BAC.txt')$V1
Target=read.table('Target.txt')$V1
SPR=c("SP1","SP4")

#BABA-ABBA reverse
a=f4('./data/autosome',c(BAC,Target),BAC,DOM,SPR,f4mode=FALSE)
write.csv(a,file='BABA-ABBA-T-BAC-DOM.csv',row.names=F)

