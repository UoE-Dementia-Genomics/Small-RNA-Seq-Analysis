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

#Description
# This script takes the output of the mirdeep2 merge script and runs a sample cleanup on it for the following:
# 1. Process sample names to match pheno files.
# 2. Assess and merge technical replicates.
# 3. Handle duplicate mirna - precursor pairs.

# Regarding sample names: mirdeep2.merge outputs a file with filename identifiers for collumn names.
# This script matches pheno IDs in a supplied file (which should be present within the filenames processed by mirDeep2)
# and assigns them to the collumn IDs of the count matrix. 

ScriptDir="/lustre/projects/Research_Project-T112069/FAD/Scripts/Small-RNA-Seq-Analysis/mirdeep2"
pheno_file="/lustre/projects/Research_Project-T112069/FAD/1_metadata/1_2_All_Pheno_Grouped.csv"
out_dir="/lustre/projects/Research_Project-T112069/FAD/3_RNA/3_1_RNA/3_2_1_mirdeep2/merged"
count_file="/lustre/projects/Research_Project-T112069/FAD/3_RNA/3_1_RNA/3_2_1_mirdeep2/merged/merged_mirdeep2.count.csv"
technical_replicates="TRUE" #Are there technical replicates?
name_collumn="InternalID" #pheno name ID collumn to be matched to collumn names of count matrix 
remove_controls="TRUE" #should controls be removed?
control_idents="h2o,negative" #naming patterns to identify controls

########################################################################

#Change this to your relevant conda environment, you must have stringr, reshape2 and ggplot installed
conda activate rna_env

Rscript ${ScriptDir}/mirdeep2.cleanup.R $pheno_file $out_dir $count_file $technical_replicates $name_collumn $remove_controls $control_idents