# miRDeep2 Setup
Recommended to setup and install via conda environment:
```
conda create -n mirdeep2 -c conda-forge -c bioconda mirdeep2
```

Reference files:
1. Bowtie builds reference.
This can be sourced from https://www.gencodegenes.org/human/ . At time of writing most recent source is:
```
wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_50/GRCh38.primary_assembly.genome.fa.gz
```

gunzip this file and then run the following lines for processing chromosome labels for downstream compatability
```
sed '/^>/ s/ .*//' GRCh38.primary_assembly.genome.fa > GRCh38.clean.fa
grep '^>' GRCh38.clean.fa | head -3 
```

2. Reference hairpin and mature sequence files
This can be sourced from mirBase https://www.mirbase.org/download/README/ 
```
wget https://www.mirbase.org/download/hairpin.fa
wget https://www.mirbase.org/download/mature.fa
```

# MirDeep2 Guide
1. Run the bowtie indexing script 
```
sbatch bowtie.indexing.sh
```

2. Run the mirdeep2 preprocessing script on both your haipin and mature sequence references. 
```
python mirdeep2.preprocess.py
```

3. Depending on number of files, run the mirdeep2.sh or mirdeep2.slurm.array.sh scripts
```
sbatch mirdeep2.slurm.array.sh
```

Note, this step can be quite slow largely driven by the randfold & novel miRNA calling in the mirDeep2 pipeline.However if you are largely interested in known miRNAs, you can progress to merging once the "miRNAs_expressed_all_samples" files have been generated for each array (if running batch mode). 

4. Merge processed files with the merge script.
```
sbatch mirdeep2.merge.results.sh
```

This will produce three csv files: a list of config files used for name matching, a report file with summary statistics from the miRDeep2 run and a processed count file. 

5. Cleanup mirDeep2 output ready for expression analysis
```
sbatch mirdeep2.cleanup.sh
```

