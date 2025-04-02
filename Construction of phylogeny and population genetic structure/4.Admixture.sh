plink --vcf autosome.recode.vcf --make-bed --out autosome --allow-extra-chr

for i in {1..6}
do
admixture --cv ./autosome.bed $i -j10 | tee log-$i.out
done
