#!/bin/bash
##-------------
##Purin Wangkiratikant, MAR 2016
##Clinical Database Centre, Institute of Personalised Genomics and Gene Therapy (IPGG)
##Faculty of Medicine Siriraj Hospital, Mahidol University, Bangkok, Thailand
##-------------
##This script performs the entire variant-calling process upon one sample, following the Genome Analysis Toolkit (GATK)'s pipeline.
##
##How to run:
##i>    Change all the directories and files within Step0 of this script accordingly.
##ii>    Run the command 'bash /path/to/GATK_individual.sh [options] sample_name'
##-------------

# Update: 2017-12-27
# Author: Zhao
# adapt this script for current env.

##-------------
##Step0: Initialisation
##-------------

##-------------
##Step0-1: Directories
##-------------
CPUS=8
project_dir=`pwd`
ref_dir=/home/zhaorui/ct208/db/genome/gatk/hg38
bwa_dir=/home/zhaorui/ct208/tool/bwa/bwa-0.7.15
picard=/home/zhaorui/ct208/tool/picard/2.17.0/picard.jar
gatk_dir=/home/zhaorui/ct208/tool/GATK
fastq_dir=${project_dir}/data
out_dir=${project_dir}/gatk

##-------------
##Step0-2: References
##-------------
ref_genome=${ref_dir}/Homo_sapiens_assembly38.fasta
ref_gtf=/opt/data/db/gene/ensembl/human/Homo_sapiens.GRCh38.86.gtf
ref_gene=/opt/data/db/gene/ucsc/hg38_table/2017-12-24/refGene.txt
indel_1=${ref_dir}/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
indel_2=${ref_dir}/1000G_phase1.snps.high_confidence.hg38.vcf.gz
DBSNP=${ref_dir}/dbsnp_146.hg38.vcf.gz
# Use this option to perform the analysis over only part of the genome. This argument can be specified multiple times. You can use samtools-style intervals either explicitly on the command line (e.g. -L chr1 or -L chr1:100-200) or by loading in a file containing a list of intervals (e.g. -L myFile.intervals).
gene_bed=kidney.gene.intervals

##-------------
##Step0-3: Other Parametres
##-------------
java_mem=16g

##-------------
##Step0-4: Input Arguments
##-------------
no_summary=0
no_prompt=0
no_exec=0
no_geno=0
while test $# -gt 0 ; do
        case "$1" in
                -h|--help)
                        echo ""
                        echo "Usage: bash $0 [options] sample_name"
                        echo ""
                        echo "This script performs the entire variant-calling process upon one sample, following the Genome Analysis Toolkit (GATK)'s pipeline."
                        echo ""
                        echo "Options:"
                        echo "-h, --help                display this help and exit"
                        echo "-v, --version                display version of this script and exit"
                        echo "-XS, --no-summary            suppress the command summary before execution"
                        echo "-XP, --no-prompt            suppress the user prompt before execution, only when the command summary is displayed"
                        echo "-XX, --no-exec                suppress automatic execution, generating only script files"
                        echo "-e, --exome                call only exonic variants, drastically accelerating the Call Haplotype and the Genotype processes"
                        echo "-g, --genes                call only these genes' exonic variants, separated by space, quote with \", like -g \"geneA geneB\", only when the --exome is enabled"
                        echo "-a                    Sequence of an adapter ligated to the 3' end (paireddata: of the first read)."
                        echo "-A                    Sequence of an adapter ligated to the 3' end (paireddata: of the second read)."
                        echo ""
                        exit 0
                        ;;
                -v|--version)
                        echo ""
                        echo "GATK_individual.sh"
                        echo ""
                        echo "Created MAR 2016"
                        echo "Updated JUL 2016"
                        echo "by"
                        echo "PURIN WANGKIRATIKANT [purin.wan@mahidol.ac.th]"
                        echo "Clinical Database Centre, Institute of Personalised Genomics and Gene Therapy (IPGG)"
                        echo "Faculty of Medicine Siriraj Hospital, Mahidol University, Bangkok, Thailand"
                        echo ""
                        exit 0
                        ;;
                -XS|--no-summary)
                        no_summary=1
                        shift
                        ;;
                -XP|--no-prompt)
                        no_prompt=1
                        shift
                        ;;
                -XX|--no-exec)
                        no_exec=1
                        shift
                        ;;
                -XG|--no-genotyping)
                        no_geno=1
                        shift
                        ;;
                -e|--exome)
                        seq_type='EXOME'
                        bed_argument='-L '${gene_bed}
                        shift
                        ;;
                -g|--genes)
                        seq_type='EXOME'
                        bed_argument='-L '${gene_bed}
                        echo "Quering exons for following gene(s): $2"
                        unlink ${gene_bed}
                        for g in $2; do echo $g;grep -w "gene_name \"$g\"" $ref_gtf |grep -w gene|cut -f1,4,5|sort -u >> ${gene_bed};done
                        sed -i -s "s/^/chr/" ${gene_bed}
                        sed -i -s "s/\t/:/" ${gene_bed}
                        sed -i -s "s/\t/-/" ${gene_bed}
                        shift
                        ;;
                -a)
                        adapter1=$2
                        echo "read 1 adatper: $adapter1"
                        shift
                        ;;
                -A)
                        adapter2=$2
                        echo "read 2 adatper: $adapter2"
                        shift
                        ;;
                *)
                        sample_name=$1
                        shift
                        ;;
        esac
done

##-------------
##Step0-5: Default Value Setting
##-------------
if [[ ! -v seq_type ]] ; then
        seq_type='GENOME'
fi

##-------------
##Step0-6: Input Verification
##-------------
if [[ ! -e ${fastq_dir}/${sample_name}_R1.fastq.gz ]] ; then
        echo
        echo 'Invalid SAMPLE NAME: '${sample_name}
        echo ${fastq_dir}/${sample_name}_R1.fastq.gz not found.
        echo 'Terminated.'
        echo
        exit 1
fi
if [[ ! -e ${fastq_dir}/${sample_name}_R2.fastq.gz ]] ; then
        echo
        echo 'Invalid SAMPLE NAME: '${sample_name}
        echo ${fastq_dir}/${sample_name}_R2.fastq.gz not found.
        echo 'Terminated.'
        echo
        exit 1
fi

##-------------
##Step0-7: Summarisation & User's Confirmation Prompt
##-------------
if [[ ${no_summary} != 1 ]] ; then
        echo
        echo '---------------------------------------'
        echo 'INDIVIDUAL VARIANT CALLING PROCESS'
        echo 'SAMPLE NAME =            '${sample_name}
        echo 'SEQUENCED DATA =        '${seq_type}
        echo '---------------------------------------'
        echo

        if [[ ${no_prompt} != 1 ]] ; then
                while true ; do
                        read -p "Are all the input arguments correct? (Y/N): " confirm
                        case ${confirm} in
                                Y|y)
                                        echo "Confirmed. Initiating..."
                                        echo
                                        break
                                        ;;
                                N|n)
                                        echo "Terminated."
                                        echo
                                        exit 1
                                        ;;
                                * )
                                        echo "Please enter Y or N."
                                        echo
                                        ;;
                        esac
                done
        fi
fi

##-------------
##Step0-8: Output Folders Creation
##-------------
mkdir -p ${out_dir}
mkdir -p ${out_dir}/${sample_name} ; mkdir -p ${out_dir}/${sample_name}/{Scripts,LOG,TEMP,SAM,BAM,BQSR,GVCF,VCF,QC,QC/FILTERED,Report,Read}


##-------------
##Step0-9: Cut adapter
##-------------
cat << EOL > ${out_dir}/${sample_name}/Scripts/0_${sample_name}_clean.sh
#!/bin/bash
##-------------
##Step0-9: Cut adapter
##-------------
cutadapt -q 15 --trim-n -m 41 -j 4 \
    -a $adapter1 \
    -A $adapter2 \
    -o ${out_dir}/${sample_name}/Read/${sample_name}_R1.fastq.gz \
    -p ${out_dir}/${sample_name}/Read/${sample_name}_R2.fastq.gz \
    ${fastq_dir}/${sample_name}_R1.fastq.gz ${fastq_dir}/${sample_name}_R2.fastq.gz

EOL

##-------------
##Step1: Align
##-------------
string=`zcat ${out_dir}/${sample_name}/Read/${sample_name}_R1.fastq.gz |head -1`
IFS=':' read -r -a array <<< "$string"
RGID=${array[2]}.${array[3]}
RGPU=${RGID}.${array[9]}
cat << EOL > ${out_dir}/${sample_name}/Scripts/1_${sample_name}_align.sh
#!/bin/bash
##-------------
##Step1: Align
##-------------
${bwa_dir}/bwa mem -t 4 -R "@RG\tID:$RGID\tSM:${sample_name}\tPL:Illumina\tLB:${sample_name}\tPU:$RGPU" ${ref_genome} \
${out_dir}/${sample_name}/Read/${sample_name}_R1.fastq.gz ${out_dir}/${sample_name}/Read/${sample_name}_R2.fastq.gz > ${out_dir}/${sample_name}/SAM/${sample_name}_aligned.sam

EOL



##-------------
##Step2: Sort
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/2_${sample_name}_sort.sh
#!/bin/bash
##-------------
##Step2: Sort
##-------------
java -Xmx${java_mem} -jar ${picard} SortSam \
INPUT=${out_dir}/${sample_name}/SAM/${sample_name}_aligned.sam \
OUTPUT=${out_dir}/${sample_name}/BAM/${sample_name}_sorted.bam \
SORT_ORDER=coordinate \
TMP_DIR=${out_dir}/${sample_name}/TEMP

EOL



##-------------
##Step3: Deduplicate
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/3_${sample_name}_deduplicate.sh
#!/bin/bash
##-------------
##Step3: Deduplicate
##-------------
java -Xmx${java_mem} -jar ${picard} MarkDuplicates \
INPUT=${out_dir}/${sample_name}/BAM/${sample_name}_sorted.bam \
OUTPUT=${out_dir}/${sample_name}/BAM/${sample_name}_deduplicated.bam \
METRICS_FILE=${out_dir}/${sample_name}/Report/${sample_name}_deduplication_metrics.txt \
CREATE_INDEX=TRUE TMP_DIR=${out_dir}/${sample_name}/TEMP

EOL



##-------------
##Step4: Build Index
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/4_${sample_name}_build_index.sh
#!/bin/bash
##-------------
##Step4: Build Index
##-------------
java -Xmx${java_mem} -jar ${picard} BuildBamIndex \
INPUT=${out_dir}/${sample_name}/BAM/${sample_name}_deduplicated.bam \
TMP_DIR=${out_dir}/${sample_name}/TEMP

EOL



##-------------
##Step5: Indel Realignment
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/5_${sample_name}_realign_indels.sh
#!/bin/bash
##-------------
##Step5-1: Create Aligner Target
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T RealignerTargetCreator \
--disable_auto_index_creation_and_locking_when_reading_rods \
-known ${indel_1} \
-known ${indel_2} \
-R ${ref_genome} \
-I ${out_dir}/${sample_name}/BAM/${sample_name}_deduplicated.bam \
-dt NONE \
${bed_argument} \
-o ${out_dir}/${sample_name}/BAM/${sample_name}_indel_target_intervals.list \
-log ${out_dir}/${sample_name}/LOG/5-1_${sample_name}_indel_target_intervals.log

##-------------
##Step5-2: Realign Indels
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T IndelRealigner \
--disable_auto_index_creation_and_locking_when_reading_rods \
-known ${indel_1} \
-known ${indel_2} \
-I ${out_dir}/${sample_name}/BAM/${sample_name}_deduplicated.bam \
-R ${ref_genome} \
-targetIntervals ${out_dir}/${sample_name}/BAM/${sample_name}_indel_target_intervals.list \
-dt NONE \
${bed_argument} \
-o ${out_dir}/${sample_name}/BAM/${sample_name}_realigned.bam \
-log ${out_dir}/${sample_name}/LOG/5-2_${sample_name}_indel_realigned.log

EOL



##-------------
##Step6: Base Quality Score Recalibration
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/6_${sample_name}_recalibrate_base.sh
#!/bin/bash
##-------------
##Step6-1: Perform Base Recalibration
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T BaseRecalibrator \
--disable_auto_index_creation_and_locking_when_reading_rods \
-R ${ref_genome} \
-knownSites ${indel_1} \
-knownSites ${indel_2} \
-knownSites ${DBSNP} \
-I ${out_dir}/${sample_name}/BAM/${sample_name}_realigned.bam \
${bed_argument} \
-o ${out_dir}/${sample_name}/BQSR/${sample_name}_perform_bqsr.table \
-log ${out_dir}/${sample_name}/LOG/6-1_${sample_name}_perform_bqsr.log

##-------------
##Step6-2: Generate Post-BQSR Table
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T BaseRecalibrator \
--disable_auto_index_creation_and_locking_when_reading_rods \
-R ${ref_genome} \
-knownSites ${indel_1} \
-knownSites ${indel_2} \
-knownSites ${DBSNP} \
-I ${out_dir}/${sample_name}/BAM/${sample_name}_realigned.bam \
${bed_argument} \
-BQSR ${out_dir}/${sample_name}/BQSR/${sample_name}_perform_bqsr.table \
-o ${out_dir}/${sample_name}/BQSR/${sample_name}_after_bqsr.table \
-log ${out_dir}/${sample_name}/LOG/6-2_${sample_name}_after_bqsr.log

##-------------
##Step6-3: Plot Base Recalibration
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T AnalyzeCovariates \
-R ${ref_genome} \
${bed_argument} \
-before ${out_dir}/${sample_name}/BQSR/${sample_name}_perform_bqsr.table \
-after ${out_dir}/${sample_name}/BQSR/${sample_name}_after_bqsr.table \
-plots ${out_dir}/${sample_name}/Report/${sample_name}_bqsr.pdf \
-log ${out_dir}/${sample_name}/LOG/6-3_${sample_name}_plot_bqsr.log ;

##-------------
##Step6-4: Print Reads
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T PrintReads \
-R ${ref_genome} \
--disable_auto_index_creation_and_locking_when_reading_rods \
-I ${out_dir}/${sample_name}/BAM/${sample_name}_realigned.bam \
-BQSR ${out_dir}/${sample_name}/BQSR/${sample_name}_perform_bqsr.table \
-dt NONE \
-EOQ \
${bed_argument} \
-o ${out_dir}/${sample_name}/BAM/${sample_name}_GATK.bam \
-log ${out_dir}/${sample_name}/LOG/6-4_${sample_name}_final_bam.log

EOL



##-------------
##Step7: Call Haplotype
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/7_${sample_name}_call_haplotype.sh
#!/bin/bash
##-------------
##Step7: Call Haplotype
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T HaplotypeCaller \
-R ${ref_genome} \
--input_file ${out_dir}/${sample_name}/BAM/${sample_name}_GATK.bam \
--emitRefConfidence GVCF \
--variant_index_type LINEAR \
--variant_index_parameter 128000 \
${bed_argument} \
-A DepthPerSampleHC \
-A ClippingRankSumTest \
-A MappingQualityRankSumTest \
-A ReadPosRankSumTest \
-A FisherStrand \
-A GCContent \
-A AlleleBalanceBySample \
-A AlleleBalance \
-A QualByDepth \
-pairHMM VECTOR_LOGLESS_CACHING \
-o ${out_dir}/${sample_name}/GVCF/${sample_name}_GATK.g.vcf \
-log ${out_dir}/${sample_name}/LOG/7_${sample_name}_haplotype_caller.log

EOL



##-------------
##Step8: Genotype
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/8_${sample_name}_genotype_gvcf.sh
#!/bin/bash
##-------------
##Step8: Genotype
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T GenotypeGVCFs \
-R ${ref_genome} \
--variant ${out_dir}/${sample_name}/GVCF/${sample_name}_GATK.g.vcf \
--disable_auto_index_creation_and_locking_when_reading_rods \
${bed_argument} \
-o ${out_dir}/${sample_name}/VCF/${sample_name}_RAW.vcf \
-log ${out_dir}/${sample_name}/LOG/8_${sample_name}_genotype_gvcf.log

EOL



##-------------
##Step9: SNV Quality Control
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/9_${sample_name}_SNV_quality_control.sh
#!/bin/bash
##-------------
##Step9-1-1: Extract SNPs
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T SelectVariants \
-R ${ref_genome} \
--variant ${out_dir}/${sample_name}/VCF/${sample_name}_RAW.vcf \
--disable_auto_index_creation_and_locking_when_reading_rods \
-selectType SNP \
--excludeFiltered \
-o  ${out_dir}/${sample_name}/QC/${sample_name}_RAW_SNV.vcf \
-log ${out_dir}/${sample_name}/LOG/9-1-1_${sample_name}_QC_select_snv.log

##-------------
##Step9-1-2: Extract Indels
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T SelectVariants \
-R ${ref_genome} \
--variant ${out_dir}/${sample_name}/VCF/${sample_name}_RAW.vcf \
--disable_auto_index_creation_and_locking_when_reading_rods \
-selectType INDEL \
-selectType MNP \
-selectType MIXED \
-selectType SYMBOLIC \
--excludeFiltered \
-o ${out_dir}/${sample_name}/QC/${sample_name}_RAW_INDEL.vcf \
-log ${out_dir}/${sample_name}/LOG/9-1-2_${sample_name}_QC_select_INDEL.log

##-------------
##Step9-2-1: Annotate SNPs
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T VariantAnnotator \
-R ${ref_genome} \
--variant ${out_dir}/${sample_name}/QC/${sample_name}_RAW_SNV.vcf \
--disable_auto_index_creation_and_locking_when_reading_rods \
--dbsnp ${DBSNP} \
-L ${out_dir}/${sample_name}/QC/${sample_name}_RAW_SNV.vcf \
-A GCContent \
-A VariantType \
-dt NONE \
-o ${out_dir}/${sample_name}/QC/${sample_name}_RAW_SNV_ANNOTATED.vcf \
-log ${out_dir}/${sample_name}/LOG/9-2-1_${sample_name}_QC_snv_annotation.log

##-------------
##Step9-3-1: Filter SNPs
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T VariantFiltration \
-R ${ref_genome} \
--variant ${out_dir}/${sample_name}/QC/${sample_name}_RAW_SNV_ANNOTATED.vcf \
--disable_auto_index_creation_and_locking_when_reading_rods \
--filterExpression 'QD < 2.0' \
--filterName 'QD' \
--filterExpression 'MQ < 30.0' \
--filterName 'MQ' \
--filterExpression 'FS > 40.0' \
--filterName 'FS' \
--filterExpression 'MQRankSum < -12.5' \
--filterName 'MQRankSum' \
--filterExpression 'ReadPosRankSum < -8.0' \
--filterName 'ReadPosRankSum' \
--filterExpression 'DP < 8.0' \
--filterName 'DP' \
--logging_level ERROR \
-o ${out_dir}/${sample_name}/QC/${sample_name}_FILTERED_SNV.vcf \
-log ${out_dir}/${sample_name}/LOG/9-3-1_${sample_name}_QC_filter_snv.log

##-------------
##Step9-4-1: Clean SNPs
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T SelectVariants \
-R ${ref_genome} \
--variant ${out_dir}/${sample_name}/QC/${sample_name}_FILTERED_SNV.vcf \
--disable_auto_index_creation_and_locking_when_reading_rods \
--excludeFiltered \
-o  ${out_dir}/${sample_name}/QC/FILTERED/${sample_name}_CLEAN_SNV.vcf \
-log ${out_dir}/${sample_name}/LOG/9-4-1_${sample_name}_QC_clean_snv.log

##-------------
##Step9-5: Combine SNVs + Indels
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T CombineVariants \
-R ${ref_genome} \
--variant ${out_dir}/${sample_name}/QC/FILTERED/${sample_name}_CLEAN_SNV.vcf \
--variant ${out_dir}/${sample_name}/QC/${sample_name}_RAW_INDEL.vcf \
--disable_auto_index_creation_and_locking_when_reading_rods \
--genotypemergeoption UNSORTED \
-o ${out_dir}/${sample_name}/QC/FILTERED/${sample_name}_CLEAN_SNV+INDEL.vcf \
-log ${out_dir}/${sample_name}/LOG/9-5_${sample_name}_QC_combine_variants.log

EOL





##-------------
##MASTER SCRIPT
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/${sample_name}_GATK.sh
#!/bin/bash
##-------------
##${sample_name}'s Preprocessing
##-------------
(bash ${out_dir}/${sample_name}/Scripts/0_${sample_name}_clean.sh) 2>&1 | tee ${out_dir}/${sample_name}/LOG/0_${sample_name}_clean.log
##-------------
##${sample_name}'s Vaiant Calling
##-------------
(bash ${out_dir}/${sample_name}/Scripts/1_${sample_name}_align.sh) 2>&1 | tee ${out_dir}/${sample_name}/LOG/1_${sample_name}_alignment.log
(bash ${out_dir}/${sample_name}/Scripts/2_${sample_name}_sort.sh) 2>&1 | tee ${out_dir}/${sample_name}/LOG/2_${sample_name}_sort.log
(bash ${out_dir}/${sample_name}/Scripts/3_${sample_name}_deduplicate.sh) 2>&1 | tee ${out_dir}/${sample_name}/LOG/3_${sample_name}_deduplication.log
(bash ${out_dir}/${sample_name}/Scripts/4_${sample_name}_build_index.sh) 2>&1 | tee ${out_dir}/${sample_name}/LOG/4_${sample_name}_building_index.log

if [[ -e ${out_dir}/${sample_name}/BAM/${sample_name}_deduplicated.bam ]] ; then
        rm ${out_dir}/${sample_name}/SAM/${sample_name}_aligned.sam
fi

bash ${out_dir}/${sample_name}/Scripts/5_${sample_name}_realign_indels.sh
bash ${out_dir}/${sample_name}/Scripts/6_${sample_name}_recalibrate_base.sh

if [[ -e ${out_dir}/${sample_name}/BAM/${sample_name}_GATK.bam ]] ; then
        rm ${out_dir}/${sample_name}/BAM/${sample_name}_{deduplicated,sorted,realigned}.{bam,bai}
fi

bash ${out_dir}/${sample_name}/Scripts/7_${sample_name}_call_haplotype.sh

if [[ ${no_geno} != 1 ]] ; then
        bash ${out_dir}/${sample_name}/Scripts/8_${sample_name}_genotype_gvcf.sh
        bash ${out_dir}/${sample_name}/Scripts/9_${sample_name}_SNV_quality_control.sh
fi

EOL





##-------------
##EXECUTION
##-------------
if [[ ${no_exec} != 1 ]] ; then
        bash ${out_dir}/${sample_name}/Scripts/${sample_name}_GATK.sh
fi
