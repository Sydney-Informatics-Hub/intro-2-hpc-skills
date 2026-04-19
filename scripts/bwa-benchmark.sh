#!/bin/bash

################################################
### INSTRUCTIONS
################################################

# Don't run this script directly, it is launched by the paired <tool>_benchmark_run.sh script 
# Edits are required: 
#	- Edit -P PBS directive to your NCI project
#	- Edit -lstorage PBS directive to your required NCI storage paths
#	- Edit walltime to be sufficient for the lowest-resourced run of your job
#	- Add your sript body (including module loads) between 'YOUR SCRIPT HERE' and 'END YOUR SCRIPT' headers
#	- Ensure you have left the last line 'end_test=end' intact
# 	- Use the variables 'outfile_prefix' and 'outdir' for IO within your script
#       - Variable 'prefix' may be used for inputs, if relevant

################################################
### PBS DIRECTIVES
################################################

#PBS -P qc03
#PBS -l walltime=02:00:00
#PBS -q normal
#PBS -W umask=022
#PBS -l wd
#PBS -lstorage=scratch/qc03+gdata/qc03

################################################
### FOR TEST RUN
################################################

if [[ $test == 'true' ]]
then
	printf "* ${script} has received the following parameters for the first benchmark run at ${ncpus} NCPUS:\n\n"
	printf "\t- Job name: ${job_name}\n\t- PBS o log: ${dot_o}\n\t- PBS e log: ${dot_e}\n"
	printf "\t- \$prefix: ${prefix}\n\t- \$outdir: ${outdir}\n\t- \$outfile_prefix: ${outfile_prefix}\n";
	printf "\n* Please ensure ${script} uses the variables \"\$outdir\" and \"\$outfile_prefix\" for outputs generated\n" 
	printf "\n* Variable \"\$prefix\" can be used to import inputs, as required/relevant for your job\n\n"
	printf "* Here is your script for ${ncpus} NCPUS:\n\n\t- Please review variables carefully before proceeding to run without 'test' mode\n\n"
	sed -n "/^begin_test/,/^end_test/{p;/^end/q}" ${script} | sed '1d' | head -n -1 
	exit
fi

begin_test=begin

################################################
### YOUR SCRIPT HERE 
################################################

# Include all the commands required to run your job
# Use ${outdir} for output directory path
# Use ${outfile_prefix} for output file prefix

# Load modules
module load bwa/0.7.17
module load samtools/1.19
module load samblaster/0.1.24

ref=/g/data/qc03/tests/reference/hg38_chromosomesOnly.fa

SAMPLE=subset_10K
fq1=../assets/NA12877_R1_10k.fq.gz
fq2=../assets/NA12877_R2_10k.fq.gz

bwa mem -M -t ${ncpus} $ref \
    -R "@RG\tID:${SAMPLE}_1\tPL:ILLUMINA\tSM:${SAMPLE}\tLB:1\tCN:KCCG" \
    $fq1 $fq2  \
    | samblaster -M -e --addMateTags \
    -d ${outdir}/${outfile_prefix}.disc.sam \
    -s ${outdir}/${outfile_prefix}.split.sam \
    | samtools sort -@ ${ncpus} -m 1G -o ${outdir}/${outfile_prefix}.dedup.sort.bam  -

################################################
### END YOUR SCRIPT
################################################
end_test=end