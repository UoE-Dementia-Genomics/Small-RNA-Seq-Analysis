#######################################
######### Run miRNA processed count preprocessing #########
#######################################
# This script assumes you have run the miRDeep2 pipeline
############################## Setup


#set up system
library(stringr)
library(reshape2)
library(ggplot2)

args <- commandArgs(T)

pheno_location <- trimws(args[1])
output_location <- trimws(args[2])
count_location <- trimws(args[3])
technical_replicates <- as.logical(trimws(args[4]))
nameCol <- trimws(args[5])
remove_controls <- as.logical(trimws(args[6]))
control_idents <- trimws(str_split_1(trimws(args[7]),pattern = ","))


# 1. Load data
counts <- read.csv(count_location,header = T)
pheno <- read.csv(pheno_location,header = T)

# 2. Process miRNA names and merge and duplicates
counts$merged_id <- paste(gsub("-","_",counts$miRNA),
                            gsub("-","_",counts$Precursor),sep = "_") # paste mirna and precursor for unique identifiers
dupID <- counts$merged_id[duplicated(counts$merged_id)] #check for duplicate ID's
idCols <- c("miRNA","Precursor","merged_id")

if(length(dupID) == 0){
    message("No duplicate miRNA - precursors identified")
    
}else if(length(dupID) >= 1){
    message("The following miRNA - precursor ID's are duplicated and will be merged:")
    message(paste("     -",dupID,"\n"))
    tempMerge <- counts[counts$merged_id %in% dupID,]
    tempMerge[,!colnames(tempMerge) %in% idCols] <- NA
    tempMerge <- tempMerge[!duplicated(tempMerge),]
    for(t in unique(dupID)){
        tempMerge[tempMerge$merged_id == t,!colnames(tempMerge) %in% idCols] <- 
                                        colSums(counts[counts$merged_id == t,!colnames(counts) %in% idCols])                                        
    }
    counts <- counts[!counts$merged_id %in% dupID,]
    counts <- rbind(counts,tempMerge)
    rm(tempMerge)
}

# 3. Process expected sample names
sample_names <- pheno[,nameCol] 
if(any(str_detect(sample_names,"/"))){
    message("Slashes in sample names, fixing")
    sample_names <- gsub("/","_",sample_names)
}

assay_names <- colnames(counts)[!colnames(counts) %in% idCols]

nameFrame <- data.frame(sample_names = "",assay_names = "")
nameFrame <-nameFrame[-1,]

for(t in sample_names){
    if(any(grepl(t,assay_names))){

    match_samples <- assay_names[grep(t,assay_names)]
    tempFrame <- data.frame(sample_names = t,assay_names = match_samples)

    nameFrame <- rbind(nameFrame,tempFrame)

    }else{

    tempFrame <- data.frame(sample_names = t,assay_names = NA)
    nameFrame <- rbind(nameFrame,tempFrame)

    }
}

leftovers <- assay_names[!assay_names %in% nameFrame$assay_names]
if(length(leftovers >= 1)){
    tempFrame <- data.frame(sample_names = NA,assay_names = leftovers)
    nameFrame <- rbind(nameFrame,tempFrame)
}

message(paste("Of",length(sample_names),"expected pheno sample IDs &",
                   length(assay_names), "assayed samples:"))
message(paste("   -",length(unique(na.omit(nameFrame$sample_names[!is.na(nameFrame$assay_names)]))),
                    "pheno ID samples where matched to assay data"))
message(paste("   -",length(is.na(nameFrame$assay_names[is.na(nameFrame$sample_names)])),
                    "assayed samples could not be matched to pheno data IDs"))                    
message(paste("   -",length(which(duplicated(nameFrame$sample_names))),
                    "pheno ID samples have multiple matching assay data (technical replicates?)"))    

write.csv(nameFrame, file = paste0(output_location,"/name.matching.csv"),row.names = FALSE)

# 4. Control Handling

if(remove_controls == TRUE){
    message("Removing controls")
    contId <- c()
    for(x in control_idents){
        contId<- append(contId,grep(x,colnames(counts),ignore.case = TRUE))
    }

    message(paste("Removing the following",length(contId), "controls"))
    message(paste("     -",colnames(counts)[contId],"\n"))
    counts <- counts[,-contId]  

}

# 5. Technical replicate handling

if(technical_replicates == TRUE){
    message("Assessing and concatenating technical replicates")

    # filter counts for top 15% variable IDs 
    temp_counts <- counts[,!colnames(counts) %in% idCols]
    row_mads_base <- apply(temp_counts, 1, mad)
    temp_counts <- temp_counts[row_mads_base > quantile(row_mads_base,probs = .85),]
    #correlate
    quickCor <- melt(cor(temp_counts))
    quickCor <- quickCor[-which(quickCor$Var1 == quickCor$Var2),]
    #define technical replicates
    technical_rep_samples <- na.omit(nameFrame$sample_names[duplicated(nameFrame$sample_names)])
    technical_rep_ids <- nameFrame[which(nameFrame$sample_names %in% technical_rep_samples),"assay_names"]

    quickCor$techRep <- FALSE
    for(x in technical_rep_samples){
        rep_ids <- nameFrame[which(nameFrame$sample_names == x),"assay_names"]
        quickCor[which(quickCor$Var1 %in% rep_ids & quickCor$Var2 %in% rep_ids),"techRep"] <- TRUE
    }

    if(min(quickCor[which(quickCor$techRep == TRUE),"value"]) < max(quickCor[which(quickCor$techRep == FALSE),"value"])){
        message("CAUTION! The technical replicates do not show better inter-sample correlation than expected background. \n",
                "         Recommended to assess technical replicates")
    }

    message(paste("Maximum background inter-sample correlation:",max(quickCor[which(quickCor$techRep == FALSE),"value"])))
    message(paste("Minimum inter-replicate correlation:",min(quickCor[which(quickCor$techRep == TRUE),"value"])))

    write.csv(quickCor[which(quickCor$techRep == TRUE),],file = paste0(output_location,"/technical.replicates.csv"))

    pdf(paste0(output_location,"/technicalReplicateCorrelations.pdf"),width = 5, height = 5)
    ggplot(quickCor, aes(x = techRep, y = value))+
        geom_boxplot()+labs(x = "Technical replicate?", y = "Correlation value")
    dev.off()

    #Concatenate replicates

    count_subset <- counts[,!colnames(counts) %in% idCols]
    count_unique <- count_subset[,!colnames(count_subset) %in% technical_rep_ids]
    colnames(count_unique) <- nameFrame[match(colnames(count_unique),nameFrame$assay_names),"sample_names"]
    count_id <- counts[,colnames(counts) %in% idCols]

    for(x in technical_rep_samples){
        ids <- nameFrame[which(nameFrame$sample_names == x),"assay_names"]
        count_id[,x] <-rowSums(counts[,ids])
    }

    counts_processed <- cbind(count_id,count_unique)

}else if(technical_replicates == TRUE){
    message("Cleaning names")
    count_subset <- counts[,!colnames(counts) %in% idCols]
    colnames(count_subset) <- nameFrame[match(colnames(count_subset),nameFrame$assay_names),"sample_names"]
}                    


write.csv(counts_processed,file = paste0(output_location,"/mirdeep2.count.processed.csv"),row.names = F)

message(paste("Complete! Processed file written to:", paste0(output_location,"/mirdeep2.count.processed.csv") ))

#####@JH Probably worth also adding in a sample metadata merging step here too?