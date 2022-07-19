library(readxl) 
library(data.table)

args <- commandArgs(trailingOnly = TRUE)
work_dir <- args[1]

source("https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/format_excel_functions.R")

# CLIN.txt
clin <- read_excel(file.path(work_dir, '41588_2018_200_MOESM4_ESM.xlsx'))
write.table( clin , file=file.path(work_dir, 'CLIN.txt') , quote=FALSE , sep="\t" , col.names=TRUE , row.names=FALSE )

# SNV.txt.gz
snv = as.data.frame( fread( file.path(work_dir, '41588_2018_200_MOESM6_ESM.txt') , stringsAsFactors=FALSE , sep="\t", fill = TRUE))
gz <- gzfile(file.path(work_dir, 'SNV.txt.gz'), "w")
write.table( snv , file=gz , quote=FALSE , sep="\t" , col.names=TRUE , row.names=FALSE )
close(gz)

# CNA_seg.txt.gz
cna_seg <- read.csv(file.path(work_dir, '41588_2018_200_MOESM8_ESM.csv'))
colnames(cna_seg) <- cna_seg[1, ]
cna_seg <- cna_seg[-1, ]
gz <- gzfile(file.path(work_dir, 'CNA_seg.txt.gz'), "w")
write.table( cna_seg , file=gz , quote=FALSE , sep="\t" , col.names=TRUE , row.names=FALSE )
close(gz)

# To DO
# Download and process CNA data gistic file