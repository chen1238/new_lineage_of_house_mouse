conda create -n gatk4
conda activate gatk4
conda install -c bioconda gatk4
conda install -c bioconda bwa-mem2


#建立索引
#bwa参考基因组
bwa-mem2 index grcm38.fa
#gatk参考基因组
gatk CreateSequenceDictionary -R grcm38.fa -O grcm38.fa.dict
#samtools参考基因组，可以查看各染色体长度
samtools faidx grcm38.fa
#gatk中参考snp数据集vcf.gz的索引(tbi)
gatk IndexFeatureFile -I mgp.v5.merged.snps_all.dbSNP142.vcf.gz
gatk IndexFeatureFile -I mgp.v5.merged.indels.dbSNP142.normed.vcf.gz


#1.构建文件夹
mkdir 1.raw_data 2.filter 3.bam 4.BQSR 5.g.vcf 6.vcf 7.vqsr_snp 8.vqsr_indel 9.final 10.vcf train_set


#2.filter，过滤原始数据
for i in `cut -f 3 sampleName_clientId.txt`
do 
fastp -i ./1.raw_data/${i}_good_1.fq.gz -o ./2.filter/${i}_filter_1.fq.gz \
-I ./1.raw_data/${i}_good_2.fq.gz -O ./2.filter/${i}_filter_2.fq.gz \
-w 12 -l 50 -n 6 -z 6 -f 15
done
#-q	质量分数阈值，默认15，判定为低质量碱基
#-l	read长度阈值，小于50，去除reads
#-u	低质量碱基占比阈值，默认大于40%，去除read
#-n	read中N的阈值，大于6，去除read
#-f	剪切read前多少个碱基，受限于测序技术，一般测序得到的read前15bp不靠谱，GC含量波动大。
#-w	fastp线程


#3.mapping，比对参考基因组，@RG信息记得填写
for i in `cut -f 3 sampleName_clientId.txt`
do
bwa-mem2 mem -t 12 -R "@RG\tID:${i}\tLB:${i}\tPL:ILLUMINA\tSM:${i}" /media/rui/4t/Rgrcm38p6/grcm38.fa \
./2.filter/${i}_filter_1.fq.gz ./2.filter/${i}_filter_2.fq.gz | samtools sort -@8 -m 8G -o ./3.bam/${i}.sorted.bam 
done
#-O 表示输出format，如BAM,SAM等，samtools默认根据-o输出名的后缀设置格式.bam，.sam，.cram


#4.rmdup，去除PCR重复
for i in `cut -f 3 sampleName_clientId-1.txt`
do
    gatk --java-options "-Xmx64G" MarkDuplicates \
    --REMOVE_DUPLICATES true \
    -I ./3.bam/${i}.sorted.bam \
    -O ./3.bam/${i}.sorted.markup.bam \
    -M ./3.bam/${i}.sorted.markup.txt
done


#5.BQSR (Recalibration Base Quality Score)，BQSR碱基质量分数矫正。
#建立相关性模型，产生重校准表( recalibration table)，输入已知的多态性位点数据库，用于屏蔽那些不需要重校准的部分，记得参考基因组要一一对应，没有已知snp数据可以跳过BQSR这一步。
for i in `cut -f 3 sampleName_clientId-1.txt`
do
    gatk  BaseRecalibrator \  #--java-options "-Xmx64g"
    -R /media/rui/4t/Rgrcm38p6/grcm38.fa \
    -I ./3.bam/${i}.sorted.markup.bam \
    --known-sites /media/rui/4t/Rgrcm38p6/mgp.v5.merged.snps_all.dbSNP142.vcf.gz \
    --known-sites /media/rui/4t/Rgrcm38p6/mgp.v5.merged.indels.dbSNP142.normed.vcf.gz \
    -O ./4.BQSR/${i}.table
done


#6.ApplyBQSR
for i in `cut -f 3 sampleName_clientId-1.txt`
do
   gatk  ApplyBQSR \
   --bqsr-recal-file ./4.BQSR/${i}.table \
   -R /media/rui/4t/Rgrcm38p6/grcm38.fa \
   -I ./3.bam/${i}.sorted.markup.bam \
   -O ./4.BQSR/${i}.sorted.markdup.bqsr.bam
done


#Haplotypecaller for chromosomes separation
#call snp三部曲
#7.HaplotypeCaller 
for i in `cut -f 3 sampleName_clientId-1.txt`
do
  mkdir ./5.g.vcf/${i}
  for j in {1..19}
  do
     gatk  HaplotypeCaller \
     -ERC GVCF \               #不加该选项默认输出单样本vcf文件，适合单样本。GVCF输出突变，非突变以区间呈现，为了合并多个样本。BP_RESOLUTION输出突变和非突变的所有位点。
     -R /media/rui/4t/Rgrcm38p6/grcm38.fa \
     -I ./4.BQSR/$i.sorted.markdup.bqsr.bam \
     #--dbsnp /media/rui/4t/Rgrcm38p6/mgp.v5.merged.snps_all.dbSNP142.vcf.gz \
     -L $j \
     -O ./5.g.vcf/${i}/${i}-chr${j}.gvcf.gz     #得到每个样本的单个染色体的gvcf文件,实现染色体拆分
   done
done


#8.CombingGVCFs
#gvcf会记录每一个位点到情况，包括有无突变，vcf只记录突变位点情况
for i in {1..19}
do
    gatk CombineGVCFs  \
    -R /media/rui/4t/Rgrcm38p6/grcm38.fa \
    -V samples1.${i}.g.vcf.gz  \
    -V samples2.${i}.g.vcf.gz  \
    -V samples3.${i}.g.vcf.gz  \
    -O ./5.g.vcf/${i}.gvcf.gz
	#合并所有样本，得到所有样本的单个染色体的gvcf文件
	#样本过多-V samples.list列表输入
done                


#9.GenotypeGVCFs，-all-sites可以保留所有位点
for i in {1..19}
do
	gatk GenotypeGVCFs \
	-R /media/rui/4t/Rgrcm38p6/grcm38.fa \
	-V ./5.g.vcf/${i}.g.vcf.gz \
	-O ./6.vcf/genotypevcf.${i}.vcf.gz
done


#10.SelectVariants,分别选择SNP和INDEL
for i in {1..19}
do
	gatk SelectVariants \
	-V ./6.vcf/genotypevcf.${i}.vcf.gz \
	-select-type SNP \
	--restrict-alleles-to BIALLELIC \
	-O snp.${i}.vcf.gz
done

for i in {1..19}
do
	gatk SelectVariants \
	-V ./6.vcf/genotypevcf.${i}.vcf.gz \
	-select-type INDEL \
	--max-indel-size 50 \
	--restrict-alleles-to BIALLELIC \
	-O indel.${i}.vcf.gz
done

-sn	sample，提取指定样本
-L	chromosome，提取指定染色体

#11.VariantFiltration，分别硬过滤
for i in {1..19}
do
	gatk VariantFiltration \
    -V snp.${i}.vcf.gz \
    --filter-expression "QUAL < 30 || QD < 2.0 || MQ < 40.0 || FS > 60.0 || SOR > 3.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0" \
    --filter-name "Filter" \
    --cluster-window-size 10  --cluster-size 3 --missing-values-evaluate-as-failing \  #如果多个snp聚在一起，则视为snp簇，可用可不用
    -O ./train_set/hard.snp.${i}.vcf.gz
done

for i in {1..19}
do
	gatk VariantFiltration \
	-V indel.${i}.vcf.gz \
	--filter-expression "QUAL<30 || QD < 2.0 || FS > 200.0 || SOR > 10.0 || InbreedingCoeff < -0.8 || ReadPosRankSum < -20.0" \
	--filter-name "Filter" \
	-O ./train_set/hard.indel.${i}.vcf.gz
done


#12.保留过滤后的位点，如果仅仅硬过滤这一步已经是最后一步，如果要软过滤则需要用硬过滤去训练数据集。
for i in {1..19}
do
	gatk SelectVariants -V ./train_set/hard.snp.${i}.vcf.gz --exclude-filtered -O ./train_set/hard.pass.snp.${i}.vcf.gz
	#awk '/^#/||$7=="PASS"' hard.snp.${i}.vcf > hard.pass.snp.${i}.vcf
	gatk SelectVariants -V ./train_set/hard.indel.${i}.vcf.gz --exclude-filtered -O ./train_set/hard.pass.indel.${i}.vcf.gz
done


#13.VariantRecalibrator,SNP
#输入文件为第9步得到的genotypevcf
#训练集为硬过滤vcf文件及dbsnp数据库的数据，需要注意数据集用到的参考基因组版本要对应。
for i in {1..19}
do
	gatk VariantRecalibrator \
	-R /media/rui/4t/Rgrcm38p6/grcm38.fa \
	-V ./6.vcf/genotypevcf.${i}.vcf.gz \
	-resource:HARD,known=false,training=true,truth=true,prior=10.0 ./train_set/hard.pass.snp.${i}.vcf.gz \
	-resource:dbsnp,known=false,training=true,truth=false,prior=12.0 /media/rui/4t/Rgrcm38p6/mgp.v5.merged.snps_all.dbSNP142.vcf.gz \
	-an DP -an QD -an FS -an SOR -an ReadPosRankSum -an MQRankSum \
	-mode SNP \
	-tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 95.0 -tranche 90.0 \
	--rscript-file ./7.vqsr_snp/${i}.snp.plots.R \
	--tranches-file ./7.vqsr_snp/${i}.snp.tranches \
	-O ./7.vqsr_snp/${i}.snp.recal
done

#Apply recalibration,SNP
for i in {1..19}
do
	gatk ApplyVQSR \
	-R /media/rui/4t/Rgrcm38p6/grcm38.fa \
	-V ./6.vcf/genotypevcf.${i}.vcf.gz \
	--truth-sensitivity-filter-level 95.0 \
	--tranches-file ./7.vqsr_snp/${i}.snp.tranches \
	--recal-file ./7.vqsr_snp/${i}.snp.recal \
	-mode SNP \
	-O ./7.vqsr_snp/${i}.vqsr.snp.vcf.gz
done

#VariantRecalibrator,INDEL，输入文件为上一步得到的vcf文件，gatk可以通过"-mode"选项分别对snp和indel进行VQSR
for i in {1..19}
do
	gatk VariantRecalibrator \
	-R /media/rui/4t/Rgrcm38p6/grcm38.fa \
	-V ./7.vqsr_snp/${i}.vqsr.snp.vcf.gz \
	-resource:HARD,known=false,training=true,truth=true,prior=10.0 ./train_set/hard.pass.indel.${i}.vcf.gz \
	-resource:dbsnp,known=false,training=true,truth=false,prior=12.0 /media/rui/4t/Rgrcm38p6/mgp.v5.merged.indels.dbSNP142.normed.vcf.gz \
	-an DP -an QD -an FS -an SOR -an ReadPosRankSum -an MQRankSum \
	-mode INDEL \
	-tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 95.0 -tranche 90.0 \
	--rscript-file ./8.vqsr_indel/${i}.indel.plots.R \
	--tranches-file ./8.vqsr_indel/${i}.indel.tranches \
	-O ./8.vqsr_indel/${i}.indel.recal
done

#Apply recalibration,INDEL
for i in {1..19}
do
	gatk ApplyVQSR \
	-R /media/rui/4t/Rgrcm38p6/grcm38.fa \
	-V ./7.vqsr_snp/${i}.vqsr.snp.vcf.gz \
	--truth-sensitivity-filter-level 95.0 \
	--tranches-file ./8.vqsr_indel/${i}.indel.tranches \
	--recal-file ./8.vqsr_indel/${i}.indel.recal \
	-mode INDEL \
	-O ./9.final/${i}.vqsr.vcf.gz
done

#14.gatk GatherVcfs，合并染色体
gatk GatherVcfs \
 -R /media/rui/4t/Rgrcm38p6/grcm38.fa \
 -I ./9.final/1.vqsr.vcf.gz -I ./9.final/2.vqsr.vcf.gz \
 -I ./9.final/3.vqsr.vcf.gz -I ./9.final/4.vqsr.vcf.gz \
 -I ./9.final/5.vqsr.vcf.gz -I ./9.final/6.vqsr.vcf.gz \
 -I ./9.final/7.vqsr.vcf.gz -I ./9.final/8.vqsr.vcf.gz \
 -I ./9.final/9.vqsr.vcf.gz -I ./9.final/10.vqsr.vcf.gz \
 -I ./9.final/11.vqsr.vcf.gz -I ./9.final/12.vqsr.vcf.gz \
 -I ./9.final/13.vqsr.vcf.gz -I ./9.final/14.vqsr.vcf.gz \
 -I ./9.final/15.vqsr.vcf.gz -I ./9.final/16.vqsr.vcf.gz \
 -I ./9.final/17.vqsr.vcf.gz -I ./9.final/18.vqsr.vcf.gz \
 -I ./9.final/19.vqsr.vcf.gz \
 -O ./10.vcf/autosome.raw.vcf
 
 
#15.remove filter
#gatk SelectVariants -V ./10.vcf/autosome.raw.vcf --exclude-filtered -O autosome.pass.vcf

awk '/^#/||$7=="PASS"' ./10.vcf/autosome.raw.vcf > autosome.pass.vcf

gatk SelectVariants \
	-V autosome.pass.vcf \
	-select-type SNP \
	--restrict-alleles-to BIALLELIC \
	-O autosome.pass.snp.vcf

 
