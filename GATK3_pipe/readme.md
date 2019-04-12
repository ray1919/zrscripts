# 靶向高通量测序GATK3分析流程
### 2018-01-22
### 赵锐

1. 工具&数据库
----
1.1 GATK v3.8、R、picard、[SnpEff](http://snpeff.sourceforge.net/download.html)、bwa、cutadapt
1.2 dnsnp146 下载自gatk bundle hg38 <ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg38/>
1.3 dbNSFP 下载自官方站点 <https://sites.google.com/site/jpopgen/dbNSFP>
```
> wget ftp://dbnsfp:dbnsfp@dbnsfp.softgenetics.com/dbNSFPv3.5c.zip
> unzip dbNSFPv3.5c.zip
> head -n1 dbNSFP3.5c_variant.chr1 > h
> cat dbNSFP*chr* | grep -v ^#chr | cat h - | bgzip -c > dbNSFP.gz
> tabix -s 1 -b 2 -e 2 dbNSFP.gz>
```
1.4 gwascatalog 下载自： <http://www.genome.gov/admin/gwascatalog.txt>
1.5 PHASTCONS <http://hgdownload.soe.ucsc.edu/goldenPath/hg38/phastCons100way/hg38.100way.phastCons/>
1.6 CLINVAR 下载器NCBI FTP clinvar/vcf <ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh38/clinvar_20171231.vcf.gz>
1.7 参考基因组 来自GATK bundle hg38

2. 流程
----
2.1 GATK_individual.sh: 单个样本分析
需要设定所有工具目录、数据目录。默认项目文件夹为当前文件夹，数据在data文件夹，结果在gatk文件夹。
```
./GATK_individual.sh -e -g "NPHS1 NPHS2 WT1" -a ATAPTER1 -A ATAPTER2 Sample1
```

根据GATK的帖子，靶向片段测序可以略过deduplication这一步，所以添加跳过deduplication的参数，并比较下两者结果的差异。
[原帖地址]<https://gatkforums.broadinstitute.org/gatk/discussion/5847/remove-duplicates-from-targetted-sequencing-using-amplicon-approach>

2.2 [GATK_QC.sh]: 单个样本质控
这个步骤不影响后续步骤，需要提供测序的target和bait区域位置bed文件。

2.3 GATK_joint.sh: 合并各个样本结果
将各个样本的GVCF合并成一个文件

2.4 GATK_annotate.sh: 注释所有位点
用6个数据库的信息注释结果

2.5 GATK_vcf_report.sh: 将合并的结果整理成最后报告
这一步骤会过滤内含子等不重要的结果，只保留造成基因产品变化的位点。有long和wide两个格式。
过滤后没有结果会出错