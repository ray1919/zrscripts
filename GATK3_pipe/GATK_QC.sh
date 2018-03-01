#!/bin/bash
##-------------
##Purin Wangkiratikant, MAR 2016
##Clinical Database Centre, Institute of Personalised Genomics and Gene Therapy (IPGG)
##Faculty of Medicine Siriraj Hospital, Mahidol University, Bangkok, Thailand
##-------------
##This script performs the post-calling process quality reports upon one sample.
##BQSR Plot and Deduplication Metrics have been integrated into the main variant-calling flow.
##
##How to run:
##i>	Change all the directories and files within Step0 of this script accordingly.
##ii>	Check if the individual GATK process for every sample has been accomplished.
##iii>	Run the command 'bash /path/to/GATK_QC.sh [options] sample_name'
##-------------





##-------------
##Step0: Initialisation
##-------------

##-------------
##Step0-1: Directories
##-------------
project_dir=/opt/data/db/sra/16s_pku
ref_dir=/home/zhaorui/ct208/db/genome/gatk/hg38
bed_dir=./
out_dir=${project_dir}/gatk

##-------------
##Step0-2: References
##-------------
ref_genome=${ref_dir}/Homo_sapiens_assembly38.fasta
target_bed=${bed_dir}/kidney.target.bed
bait_bed=${bed_dir}/kidney.bait.bed
exon_bed=${bed_dir}/kidney.bait.bed
# gene_bed=kidney.gene.intervals
# gene_list=kidney.gene_list.txt

##-------------
##Step0-3: Tools
##-------------
picard_dir=~/ct208/tool/picard/2.17.0/picard.jar
gatk_dir=/home/zhaorui/ct208/tool/GATK
samtools_dir=/usr/local/bin/

##-------------
##Step0-4: Other Parametres
##-------------
java_mem=20g

##-------------
##Step0-5: Input Arguments
##-------------
while test $# -gt 0 ; do
        case "$1" in
                -h|--help)
						echo ""
                        echo "Usage: bash $0 [options] sample_name"
                        echo ""
                        echo "This script performs the post-calling process quality reports upon one sample."
						echo "BQSR Plot and Deduplication Metrics have been integrated into the main variant-calling flow."
                        echo ""
                        echo "Options:"
                        echo "-h, --help				display this help and exit"
						echo "-v, --version				display version of this script and exit"
						echo "-XS, --no-summary			suppress the command summary before execution"
						echo "-XP, --no-prompt			suppress the user prompt before execution, only when the command summary is displayed"
						echo "-XX, --no-exec				suppress automatic execution, generating only script files"
						echo ""
                        exit 0
                        ;;
				-v|--version)
						echo ""
						echo "GATK_QC.sh"
                        echo ""
						echo "Created MAR 2016"
						echo "Updated JAN 2018"
						echo "Fork by"
						echo "ZHAO RUI [zhaorui@ctbioscience.com]"
						echo "Ct Bioscience Inc."
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
				*)
						sample_name=$1
						shift
						;;
		esac
done

##-------------
##Step0-6: Input Verification
##-------------
if [[ ! -e ${out_dir}/${sample_name}/BAM/${sample_name}_GATK.bam ]] ; then
		echo
		echo 'Invalid SAMPLE NAME: '${sample_name}
		echo ${out_dir}/${sample_name}/BAM/${sample_name}_GATK.bam not found.
		echo 'Terminated.'
		echo
		exit 1
fi
if [[ ! -e ${out_dir}/${sample_name}/QC/FILTERED/${sample_name}_CLEAN_SNV+INDEL.vcf ]] ; then
		echo
		echo 'Invalid SAMPLE NAME: '${sample_name}
		echo ${out_dir}/${sample_name}/QC/FILTERED/${sample_name}_CLEAN_SNV+INDEL.vcf not found.
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
		echo 'INDIVIDUAL POST-CALL QUALITY REPORT'
		echo 'SAMPLE NAME =			'${sample_name}
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
mkdir -p ${out_dir}/${sample_name}/{TEMP,Report,Scripts/QC,LOG/QC}

##-------------
##Step0-9: Picard Bed Files
##-------------
if [[ ! -e ${bed_dir}/OnTarget.picard.bed ]] ; then
		(${samtools_dir}/samtools view -H ${out_dir}/${sample_name}/BAM/${sample_name}_GATK.bam | grep "@SQ" ; sed 's/\r//g' ${target_bed} | awk '{print $1,($2+1),$3,"+",$1"_"($2+1)"_"$3}' | sed 's/ /\t/g' ) >| ${bed_dir}/OnTarget.picard.bed
fi
if [[ ! -e ${bed_dir}/OnBait.picard.bed ]] ; then
		(${samtools_dir}/samtools view -H ${out_dir}/${sample_name}/BAM/${sample_name}_GATK.bam | grep "@SQ" ; sed 's/\r//g' ${bait_bed} | awk '{print $1,($2+1),$3,"+",$1"_"($2+1)"_"$3}' | sed 's/ /\t/g' ) >| ${bed_dir}/OnBait.picard.bed
fi



##-------------
##Step1: Ti/Tv 
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/QC/01_${sample_name}_TiTv.sh
#!/bin/bash
##-------------
##Step1-1: Prepare SNPs
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T SelectVariants \
-R ${ref_genome} \
--excludeFiltered \
--variant ${out_dir}/${sample_name}/QC/FILTERED/${sample_name}_CLEAN_SNV+INDEL.vcf \
-o ${out_dir}/${sample_name}/TEMP/${sample_name}_QC_FILTERED_TiTv_SNV.vcf \
-log ${out_dir}/${sample_name}/LOG/QC/01-1_${sample_name}_prepare_snps.log

##-------------
##Step1-2-1: Select Known Variants
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T SelectVariants \
-R ${ref_genome} \
--variant ${out_dir}/${sample_name}/QC/FILTERED/${sample_name}_CLEAN_SNV+INDEL.vcf \
--excludeFiltered \
--concordance ${ref_dir}/dbsnp_146.hg38.vcf.gz \
-o ${out_dir}/${sample_name}/TEMP/${sample_name}_QC_FILTERED_TiTv_SNV_KNOWN.vcf \
-log ${out_dir}/${sample_name}/LOG/QC/01-2-1_${sample_name}_select_known_var.log

##-------------
##Step1-2-2: Select Novel Variants
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T SelectVariants \
-R ${ref_genome} \
--variant ${out_dir}/${sample_name}/QC/FILTERED/${sample_name}_CLEAN_SNV+INDEL.vcf \
--excludeFiltered \
--discordance ${ref_dir}/dbsnp_146.hg38.vcf.gz \
-o ${out_dir}/${sample_name}/TEMP/${sample_name}_QC_FILTERED_TiTv_SNV_NOVEL.vcf \
-log ${out_dir}/${sample_name}/LOG/QC/01-2-2_${sample_name}_select_novel_var.log

##-------------
##Step1-3-1: Calculate TiTv of Known Variants
##-------------
vcfutils.pl qstats ${out_dir}/${sample_name}/TEMP/${sample_name}_QC_FILTERED_TiTv_SNV_KNOWN.vcf \
> ${out_dir}/${sample_name}/Report/${sample_name}_TiTv_Known.txt

##-------------
##Step1-3-2: Calculate TiTv of Novel Variants
##-------------
vcfutils.pl qstats ${out_dir}/${sample_name}/TEMP/${sample_name}_QC_FILTERED_TiTv_SNV_NOVEL.vcf \
> ${out_dir}/${sample_name}/Report/${sample_name}_TiTv_Novel.txt

EOL



##-------------
##Step2: Depth of Coverage
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/QC/02_${sample_name}_depth_of_coverage.sh
#!/bin/bash
##-------------
##Step2-1: Depth of Coverage on Exon
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T DepthOfCoverage \
-R ${ref_genome} \
-I ${out_dir}/${sample_name}/BAM/${sample_name}_GATK.bam \
-L ${exon_bed} \
-mmq 20 \
-mbq 10 \
--outputFormat csv \
-omitBaseOutput \
-o ${out_dir}/${sample_name}/Report/${sample_name}_coverage.exon \
-ct 8 \
-ct 15 \
-ct 20 \
-log ${out_dir}/${sample_name}/LOG/QC/02-1_${sample_name}_coverage_exon.log

##-------------
##Step2-2: Depth of Coverage on Bait
##-------------
java -Xmx${java_mem} -jar ${gatk_dir}/GenomeAnalysisTK.jar \
-T DepthOfCoverage \
-R ${ref_genome} \
-I ${out_dir}/${sample_name}/BAM/${sample_name}_GATK.bam \
-L ${bait_bed} \
-mmq 20 \
-mbq 10 \
--outputFormat csv \
-omitBaseOutput \
-o ${out_dir}/${sample_name}/Report/${sample_name}_coverage.bait \
-ct 8 \
-ct 15 \
-ct 20 \
-log ${out_dir}/${sample_name}/LOG/QC/02-2_${sample_name}_coverage_bait.log

##-------------
##Step2-3: Adding Suffixes
##-------------
rename 's/$/.csv/' ${out_dir}/${sample_name}/Report/${sample_name}_coverage*

EOL



##-------------
##Step3: Alignment Summary Metrics
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/QC/03_${sample_name}_alignment_summary_metrics.sh
#!/bin/bash
##-------------
##Step3: Alignment Summary Metrics
##-------------
java -jar ${picard_dir} CollectAlignmentSummaryMetrics \
INPUT=${out_dir}/${sample_name}/BAM/${sample_name}_GATK.bam \
OUTPUT=${out_dir}/${sample_name}/Report/${sample_name}_alignment_summary_metrics.txt \
R=${ref_genome} \
VALIDATION_STRINGENCY=SILENT

EOL



##-------------
##Step4: Quality Score Distribution
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/QC/04_${sample_name}_quality_score_distribution.sh
#!/bin/bash
##-------------
##Step4: Quality Score Distribution
##-------------
java -jar ${picard_dir} QualityScoreDistribution \
INPUT=${out_dir}/${sample_name}/BAM/${sample_name}_GATK.bam \
OUTPUT=${out_dir}/${sample_name}/Report/${sample_name}_quality_score_distribution.txt \
CHART=${out_dir}/${sample_name}/Report/${sample_name}_quality_score_distribution_chart.pdf \
R=${ref_genome} \
VALIDATION_STRINGENCY=SILENT \
INCLUDE_NO_CALLS=true

EOL



##-------------
##Step5: GC Bias Metrics
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/QC/05_${sample_name}_gc_bias_metrics.sh
#!/bin/bash
##-------------
##Step5: GC Bias Metrics
##-------------
java -jar ${picard_dir} CollectGcBiasMetrics \
INPUT=${out_dir}/${sample_name}/BAM/${sample_name}_GATK.bam \
OUTPUT=${out_dir}/${sample_name}/Report/${sample_name}_gc_bias_metrics.txt \
CHART_OUTPUT=${out_dir}/${sample_name}/Report/${sample_name}_gc_bias_metrics.pdf \
SUMMARY_OUTPUT=${out_dir}/${sample_name}/Report/${sample_name}_gc_bias_summary.txt \
R=${ref_genome} \
VALIDATION_STRINGENCY=SILENT

EOL



##-------------
##Step6: Insert Size Metrics
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/QC/06_${sample_name}_insert_size_metrics.sh
#!/bin/bash
##-------------
##Step6: Insert Size Metrics
##-------------
java -jar ${picard_dir} CollectInsertSizeMetrics \
INPUT=${out_dir}/${sample_name}/BAM/${sample_name}_GATK.bam \
OUTPUT=${out_dir}/${sample_name}/Report/${sample_name}_insert_size_metrics.txt \
H=${out_dir}/${sample_name}/Report/${sample_name}_insert_size_metrics_histogram.pdf \
R=${ref_genome} \
VALIDATION_STRINGENCY=SILENT

EOL



##-------------
##Step7: Mean Quality by Cycle
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/QC/07_${sample_name}_mean_quality_by_cycle.sh
#!/bin/bash
##-------------
##Step7: Mean Quality by Cycle
##-------------
java -jar ${picard_dir} MeanQualityByCycle \
INPUT=${out_dir}/${sample_name}/BAM/${sample_name}_GATK.bam \
OUTPUT=${out_dir}/${sample_name}/Report/${sample_name}_mean_quality_by_cycle.txt \
CHART=${out_dir}/${sample_name}/Report/${sample_name}_mean_quality_by_cycle_chart.pdf \
R=${ref_genome} \
VALIDATION_STRINGENCY=SILENT

EOL



##-------------
##Step8: Hybridization Selection Metrics
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/QC/08_${sample_name}_hybridization_selection_metrics.sh
#!/bin/bash
##-------------
##Step8: Hybridization Selection Metrics
##-------------
java -jar ${picard_dir} CalculateHsMetrics \
INPUT=${out_dir}/${sample_name}/BAM/${sample_name}_GATK.bam \
OUTPUT=${out_dir}/${sample_name}/Report/${sample_name}_hybridization_selection_metrics.txt \
PER_TARGET_COVERAGE=${out_dir}/${sample_name}/Report/${sample_name}_per_target_coverage.txt \
R=${ref_genome} \
BI=${bed_dir}/OnBait.picard.bed \
TI=${bed_dir}/OnTarget.picard.bed \
VALIDATION_STRINGENCY=SILENT

EOL





##-------------
##MASTER SCRIPT
##-------------
cat <<EOL > ${out_dir}/${sample_name}/Scripts/QC/${sample_name}_QC.sh
#!/bin/bash
##-------------
##${sample_name}'s Post-Calling Quality Control
##-------------
bash ${out_dir}/${sample_name}/Scripts/QC/01_${sample_name}_TiTv.sh
bash ${out_dir}/${sample_name}/Scripts/QC/02_${sample_name}_depth_of_coverage.sh
(bash ${out_dir}/${sample_name}/Scripts/QC/03_${sample_name}_alignment_summary_metrics.sh) 2>&1 | tee ${out_dir}/${sample_name}/LOG/QC/03_${sample_name}_alignment_summary.log
(bash ${out_dir}/${sample_name}/Scripts/QC/04_${sample_name}_quality_score_distribution.sh) 2>&1 | tee ${out_dir}/${sample_name}/LOG/QC/04_${sample_name}_quality_distribution.log
(bash ${out_dir}/${sample_name}/Scripts/QC/05_${sample_name}_gc_bias_metrics.sh) 2>&1 | tee ${out_dir}/${sample_name}/LOG/QC/05_${sample_name}_gc_bias.log
(bash ${out_dir}/${sample_name}/Scripts/QC/06_${sample_name}_insert_size_metrics.sh) 2>&1 | tee ${out_dir}/${sample_name}/LOG/QC/06_${sample_name}_insert_size.log
(bash ${out_dir}/${sample_name}/Scripts/QC/07_${sample_name}_mean_quality_by_cycle.sh) 2>&1 | tee ${out_dir}/${sample_name}/LOG/QC/07_${sample_name}_mean_quality.log
(bash ${out_dir}/${sample_name}/Scripts/QC/08_${sample_name}_hybridization_selection_metrics.sh) 2>&1 | tee ${out_dir}/${sample_name}/LOG/QC/08_${sample_name}_hybridization_selection.log

EOL





##-------------
##EXECUTION
##-------------
if [[ ${no_exec} != 1 ]] ; then
		bash ${out_dir}/${sample_name}/Scripts/QC/${sample_name}_QC.sh
fi
