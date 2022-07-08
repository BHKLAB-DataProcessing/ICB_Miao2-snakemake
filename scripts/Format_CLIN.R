library(stringr)

args <- commandArgs(trailingOnly = TRUE)
input_dir <- args[1]
output_dir <- args[2]

source("https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/Get_Response.R")
source("https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/format_clin_data.R")

clin_original = read.csv( file.path(input_dir, "CLIN.txt"), stringsAsFactors=FALSE , sep="\t" , dec=',')
selected_cols <- c( "pair_id","cancer_type","age_start_io","sex","RECIST","os_days","os_censor","pfs_days","pfs_censor","histology","drug_type" )
clin = cbind( clin_original[ , selected_cols ], NA, NA, NA, NA, NA )
colnames(clin) = c( "patient" , "primary" , "age" , "sex" , "recist" , "t.os"  ,"os","t.pfs", "pfs" , "histo" , "drug_type" , "stage" , "dna" , "rna" , "response.other.info" , "response")

clin$drug_type = ifelse( clin$drug_type %in% "anti-CTLA-4" , "CTLA4" , 
					ifelse( clin$drug_type %in% "anti-CTLA-4 + anti-PD-1/PD-L1", "Combo" , "PD-1/PD-L1" ))
clin$sex = ifelse(clin$sex %in% "FEMALE" , "F" , "M")

clin$t.os = clin$t.os/30.5
clin$t.pfs = clin$t.pfs/30.5

clin$recist[ clin$recist %in% "X" ] = NA 
clin$response = Get_Response( data=clin )

clin$patient = sapply( clin$patient , function(x){ paste( unlist( strsplit( as.character( x ) , "-" , fixed=TRUE )) , collapse=".") })
clin_original$pair_id <- str_replace_all(clin_original$pair_id, '-', '.')

case = read.csv( file.path(output_dir, "cased_sequenced.csv"), stringsAsFactors=FALSE , sep=";" )
clin$dna[ clin$patient %in% case[ case$snv %in% 1 , ]$patient ] = "wes"

clin = clin[ , c("patient" , "sex" , "age" , "primary" , "histo" , "stage" , "response.other.info" , "recist" , "response" , "drug_type" , "dna" , "rna" , "t.pfs" , "pfs" , "t.os" , "os" ) ]

clin$primary[ clin$primary %in% "Anal" ] = "Colon"
clin$primary[ clin$primary %in% "HNSCC" ] = "HNC"
clin$primary[ clin$primary %in% "Sarcoma" ] = "Other"

clin <- format_clin_data(clin_original, 'pair_id', selected_cols, clin)

write.table( clin , file=file.path(output_dir, "CLIN.csv") , quote=FALSE , sep=";" , col.names=TRUE , row.names=FALSE )

