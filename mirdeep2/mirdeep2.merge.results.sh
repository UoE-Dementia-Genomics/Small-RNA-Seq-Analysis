#!/bin/bash
#SBATCH -A Research_Project-T112069 # research project to submit under.
#SBATCH --export=ALL # export all environment variables to the batch job.
#SBATCH -D . # set working directory to .
#SBATCH -p mrcq # submit to the parallel test queue
#SBATCH --time=1:00:00 # Maximum wall time for the job
#SBATCH --nodes=1 # specify number of nodes.
#SBATCH --ntasks-per-node=16 # specify number of processors.
#SBATCH --mail-type=END # send email at job completion
#SBATCH --mail-user=j.d.harvey@exeter.ac.uk # email address
#SBATCH --output=%x.%j.out
#########################################################################

results_dir="/lustre/projects/Research_Project-T112069/FAD/3_RNA/3_1_RNA/3_2_1_mirdeep2/results"
out_prefix="/lustre/projects/Research_Project-T112069/FAD/3_RNA/3_1_RNA/3_2_1_mirdeep2/merged"

ScriptDir="/lustre/projects/Research_Project-T112069/FAD/Scripts/Small-RNA-Seq-Analysis/mirdeep2"

########################################################################

conda activate rna_env

Rscript ${ScriptDir}/mirdeep2.merge.results.R $results_dir $out_prefix 


