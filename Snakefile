from snakemake.remote.S3 import RemoteProvider as S3RemoteProvider
S3 = S3RemoteProvider(
    access_key_id=config["key"], 
    secret_access_key=config["secret"],
    host=config["host"],
    stay_on_remote=False
)
prefix = config["prefix"]
filename = config["filename"]
data_source  = "https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Miao2-data/main/"

rule get_MultiAssayExp:
    input:
        S3.remote(prefix + "processed/CLIN.csv"),
        S3.remote(prefix + "processed/CNA_gene.csv"),
        S3.remote(prefix + "processed/CNA_seg.txt"),
        S3.remote(prefix + "processed/SNV.csv"),
        S3.remote(prefix + "processed/cased_sequenced.csv"),
        S3.remote(prefix + "annotation/Gencode.v40.annotation.RData")
    output:
        S3.remote(prefix + filename)
    shell:
        """
        Rscript -e \
        '
        load(paste0("{prefix}", "annotation/Gencode.v40.annotation.RData"))
        source("https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/get_MultiAssayExp.R");
        saveRDS(
            get_MultiAssayExp(study = "Miao.2", input_dir = paste0("{prefix}", "processed")), 
            "{prefix}{filename}"
        );
        '
        """

rule download_annotation:
    output:
        S3.remote(prefix + "annotation/Gencode.v40.annotation.RData")
    shell:
        """
        wget https://github.com/BHKLAB-Pachyderm/Annotations/blob/master/Gencode.v40.annotation.RData?raw=true -O {prefix}annotation/Gencode.v40.annotation.RData 
        """

rule format_snv:
    input:
        S3.remote(prefix + "download/SNV.txt.gz"),
        S3.remote(prefix + "processed/cased_sequenced.csv")
    output:
        S3.remote(prefix + "processed/SNV.csv")
    shell:
        """
        Rscript scripts/Format_SNV.R \
        {prefix}download \
        {prefix}processed \
        """

rule format_cna_seg:
    input:
        S3.remote(prefix + "processed/cased_sequenced.csv"),
        S3.remote(prefix + "download/CNA_seg.txt.gz")
    output:
        S3.remote(prefix + "processed/CNA_seg.txt")
    shell:
        """
        Rscript scripts/Format_CNA_seg.R \
        {prefix}download \
        {prefix}processed \
        """

rule format_cna_gene:
    input:
        S3.remote(prefix + "processed/cased_sequenced.csv"),
        S3.remote(prefix + "download/gistic/all_thresholded.by_genes.txt.gz")
    output:
        S3.remote(prefix + "processed/CNA_gene.csv")
    shell:
        """
        Rscript scripts/Format_CNA_gene.R \
        {prefix}download \
        {prefix}processed \
        """

rule format_clin:
    input:
        S3.remote(prefix + "processed/cased_sequenced.csv"),
        S3.remote(prefix + "download/CLIN.txt")
    output:
        S3.remote(prefix + "processed/CLIN.csv")
    shell:
        """
        Rscript scripts/Format_CLIN.R \
        {prefix}download \
        {prefix}processed \
        """

rule format_cased_sequenced:
    input:
        S3.remote(prefix + "download/CLIN.txt")
    output:
        S3.remote(prefix + "processed/cased_sequenced.csv")
    shell:
        """
        Rscript scripts/Format_cased_sequenced.R \
        {prefix}download \
        {prefix}processed \
        """

rule format_downloaded_data:
    input:
        S3.remote(prefix + "download/41588_2018_200_MOESM4_ESM.xlsx"),
        S3.remote(prefix + "download/41588_2018_200_MOESM6_ESM.txt"),
        S3.remote(prefix + "download/41588_2018_200_MOESM8_ESM.csv")
    output:
        S3.remote(prefix + "download/CLIN.txt"),
        S3.remote(prefix + "download/SNV.txt.gz"),
        S3.remote(prefix + "download/CNA_seg.txt.gz")
    shell:
        """
        Rscript scripts/format_downloaded_data.R \
        {prefix}download \
        """

rule download_data:
    output:
        S3.remote(prefix + "download/41588_2018_200_MOESM4_ESM.xlsx"),
        S3.remote(prefix + "download/41588_2018_200_MOESM6_ESM.txt"),
        S3.remote(prefix + "download/41588_2018_200_MOESM8_ESM.csv"),
        S3.remote(prefix + "download/gistic/all_thresholded.by_genes.txt.gz")
    shell:
        """
        wget -O {prefix}download/41588_2018_200_MOESM4_ESM.xlsx https://static-content.springer.com/esm/art%3A10.1038%2Fs41588-018-0200-2/MediaObjects/41588_2018_200_MOESM4_ESM.xlsx
        wget -O {prefix}download/41588_2018_200_MOESM6_ESM.txt https://static-content.springer.com/esm/art%3A10.1038%2Fs41588-018-0200-2/MediaObjects/41588_2018_200_MOESM6_ESM.txt
        wget -O {prefix}download/41588_2018_200_MOESM8_ESM.csv https://static-content.springer.com/esm/art%3A10.1038%2Fs41588-018-0200-2/MediaObjects/41588_2018_200_MOESM8_ESM.csv
        wget {data_source}gistic/all_thresholded.by_genes.txt.gz -O {prefix}download/gistic/all_thresholded.by_genes.txt.gz
        """ 