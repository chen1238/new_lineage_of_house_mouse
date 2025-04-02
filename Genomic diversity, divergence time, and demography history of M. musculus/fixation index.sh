vcftools --vcf ../Autosome.vcf \
     --keep sample.txt \
     --mac 1 \
     --max-missing 0.9 \
     --out autosome \
     --recode 


vcftools --vcf ./autosome.recode.vcf --weir-fst-pop DOM.txt --weir-fst-pop MUS.txt --fst-window-size 40000 --out DOM-MUS
