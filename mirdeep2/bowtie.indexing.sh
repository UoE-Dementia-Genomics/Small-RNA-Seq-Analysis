#!/bin/bash
#SBATCH -A Research_Project-T112069 # research project to submit under.
#SBATCH --export=ALL # export all environment variables to the batch job.
#SBATCH -D . # set working directory to .
#SBATCH -p mrcq
#SBATCH --time=5:00:00 # Maximum wall time for the job
#SBATCH --nodes=1 # specify number of nodes.
#SBATCH --ntasks-per-node=16 # specify number of processors.
#SBATCH --mail-type=END # send email at job completion
#SBATCH --mail-user=j.d.harvey@exeter.ac.uk # email address

out_dir=/lustre/projects/Research_Project-T112069/FAD/3_RNA/3_1_RNA/3_2_1_mirdeep2/bowtie-index/
genome_file=/lustre/projects/Research_Project-T112069/Reference/Genomes/GRCh38.clean.fa
index_prefix=${out_dir}/hg38_index

conda activate mirdeep2

if [ ! -f "${index_prefix}.1.ebwt" ]
then
  echo "Generating bowtie index..."
  mkdir -p "${out_dir}"
  bowtie-build "${genome_file}" "${index_prefix}"
fi

