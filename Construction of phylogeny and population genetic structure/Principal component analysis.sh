#vcftools --vcf ../Autosome.vcf --recode --mac 3 --max-missing 0.9 --keep sample.txt --out Autosome
python2 ./vcf2eigenstrat.py -v ./Autosome.recode.vcf -o autosome

smartpca -p runningpca.conf.txt
