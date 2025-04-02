vcftools --vcf ../Autosome.vcf \
	 --keep sample.txt \
	 --mac 1 \
	 --max-missing 0.9 \
	 --out autosome \
	 --recode 


mkdir data
plink --vcf ./autosome.recode.vcf --make-bed --out ./data/autosome --allow-extra-chr


