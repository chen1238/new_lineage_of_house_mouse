#vcf to vcf.gz
bgzip 5pop.recode.vcf
tabix 5pop.recode.vcf.gz

#vcf2smc
for j in {1..19}
do
  sudo docker run --rm -v $PWD:/mnt terhorst/smcpp:latest vcf2smc --mask ./mask/chr${j}.mask.bed.gz ./5pop.recode.vcf.gz ./CAS1/CAS1-chr${j}.smc.gz $j CAS1:IN1,IN2,IN3,IN4,IN5,IN6,IN7,IN8,IN9,IN10
done

#estimate
sudo docker run --rm -v $PWD:/mnt terhorst/smcpp:latest estimate --spline cubic --knots 15 --timepoints 100 10000000 --cores 20  -o ./CAS1/estimate/ 4.1e-9 ./CAS1/CAS1-*.smc.gz

#plot
sudo docker run --rm -v $PWD:/mnt terhorst/smcpp:latest plot ./total.pdf ./*/estimate/*.final.json -g 0.5 --ylim 0 10000000 --xlim 1 1000000 -c

