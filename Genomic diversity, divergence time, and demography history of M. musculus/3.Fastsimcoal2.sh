#2D fold SFS
../angsd/angsd -bam DOM.list -doSaf 1 -out DOM -GL 2 -anc /media/rui/4t/Rgrcm38p6/grcm38.fa -minMapQ 20 -minQ 20
../angsd/angsd -bam MUS.list -doSaf 1 -out MUS -GL 2 -anc /media/rui/4t/Rgrcm38p6/grcm38.fa -minMapQ 20 -minQ 20

../angsd/misc/realSFS DOM.saf.idx MUS.saf.idx -fold 1 > 2D.sfs


#running fastsimcoal2 (best model), generate maximum likelihood (ML) parameters, _maxL.pv file and _maxL.par file
PREFIX=4pop
for i in {1..100}
 do
   mkdir run$i
   cp ${PREFIX}* ./run$i
   cd run$i
   ../../fsc2705 -t ${PREFIX}.tpl -e ${PREFIX}.est -n 200000 -m -M -L 50 -s0 -c 10
   cd ..
 done


#generate 1,000 bootstrap replicates (folded SFS) using _maxL.par file
../fsc2705 -i ${PREFIX}_maxL.par -n 1000 -j -m -s0 -x -I


#re-analyzed each replicate
../fsc2705 -t ${PREFIX}_maxL.tpl -e ${PREFIX}_maxL.est --initValues ${PREFIX}_maxL.pv -n 200000 -m -M -L 50 -s0 -c 10
