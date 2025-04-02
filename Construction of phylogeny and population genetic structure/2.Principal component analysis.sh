#vcftools --vcf ../Autosome.vcf --recode --mac 3 --max-missing 0.9 --keep sample.txt --out autosome

python2 ./vcf2eigenstrat.py -v ./autosome.recode.vcf -o autosome

smartpca -p runningpca.conf.txt
