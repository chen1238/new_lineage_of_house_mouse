java -Xss5m -Xmx256g -jar beagle.28Jun21.220.jar gt=../autosome.recode.vcf out=autosome


#XP-EHH
for i in {1..19}
do
  vcftools --gzvcf autosome.vcf.gz --chr $i --recode --out ./data/CP-$i --keep CP.txt
  vcftools --gzvcf autosome.vcf.gz --chr $i --recode --out ./data/GR-$i --keep JL.txt
  plink --vcf ./data/CP-$i.recode.vcf --recode --out ./map/$i
  awk '$3=$4*0.00000057' ./map/$i.map > ./map/$i-cM.map
done


for i in {1..19}
do 
    selscan --xpehh --vcf ./data/GR-$i.recode.vcf --vcf-ref ./data/CP-$i.recode.vcf --map ./map/$i-cM.map --threads 6 --out selscan-$i
done


for i in {1..19}
do
Rscript Sliding_window.R  -i ./selscan-$i.xpehh.out -w 40000 -s 20000 -o chr$i
done
