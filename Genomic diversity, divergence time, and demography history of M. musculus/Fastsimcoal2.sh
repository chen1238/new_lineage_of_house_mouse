#running fastsimcoal2
PREFIX=4pop
for i in {1..100}
 do
   mkdir run$i
   cp ${PREFIX}* ./run$i
   cd run$i
   ../../fsc2705 -t ${PREFIX}.tpl -e ${PREFIX}.est -n 200000 -m -M -L 50 -s0 -c 10
   cd ..
 done


#generate 1,000 bootstrap replicates
../fsc2705 -i ${PREFIX}_maxL.par -n 1000 -j -m -s0 -x -I


#re-analyzed each replicate
../fsc2705 -t ${PREFIX}_maxL.tpl -e ${PREFIX}_maxL.est --initValues ${PREFIX}_maxL.pv -n 200000 -m -M -L 50 -s0 -c 10
