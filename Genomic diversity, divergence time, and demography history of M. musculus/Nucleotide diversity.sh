../angsd/angsd -bam GR.list -doSaf 1 -out GR -GL 2 -anc /media/rui/4t/Rgrcm38p6/grcm38.fa -minMapQ 20 -minQ 20


../angsd/misc/realSFS GR.saf.idx -fold 1 > GR.sfs


../angsd/misc/realSFS saf2theta -sfs GR.sfs GR.saf.idx -fold 1 -outname GR


../angsd/misc/thetaStat do_stat GR.thetas.idx -win 40000 -step 40000 -outnames GR.theta.windows
