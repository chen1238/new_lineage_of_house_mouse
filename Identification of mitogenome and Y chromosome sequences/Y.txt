gatk CombineGVCFs -R /media/rui/4t/Rgrcm38p6/grcm38.fa -V file.list -O Y.g.vcf.gz
 
gatk GenotypeGVCFs -R /media/rui/4t/Rgrcm38p6/grcm38.fa -V Y.g.vcf.gz -O Y.vcf

vcftools --vcf Y.vcf \
    --mac 1 \
    --max-alleles 2 \
    --min-alleles 2 \
    --min-meanDP 3 \
    --minQ 20 \
    --max-missing 0.8 \
    --out Y \
    --recode \
    --remove-indels 

bcftools view -t Y:1-3400000 Y.recode.vcf -o Y.recode.Yp.vcf

#mappability filter
bcftools view -T Y.bed Y.recode.Yp.vcf -o Y.recode.Yp.bed.vcf
