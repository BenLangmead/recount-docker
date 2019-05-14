#!/usr/bin/env R

## Load libraries
library('recount')
library('SummarizedExperiment')

## Find a project of interest
project_info <- abstract_search('GSE32465')

## Download the gene-level RangedSummarizedExperiment data
download_study(project_info$project)

## Load the data
load(file.path(project_info$project, 'rse_gene.Rdata'))

## Find the GEO accession ids
# (NCBI connection closed can happen error here sometimes)
geoids <- sapply(colData(rse_gene)$run, find_geo)

## Get the sammple information from GEO
geoinfo <- lapply(geoids, function(x) { geo_info(x, destdir=paste0('/tmp')) })

## Extract the sample characteristics
geochar <- lapply(geoinfo, geo_characteristics)

## Note that the information for this study is a little inconsistent, so we
## have to fix it.
geochar <- do.call(rbind, lapply(geochar, function(x) {
    if('cells' %in% colnames(x)) {
        colnames(x)[colnames(x) == 'cells'] <- 'cell.line'
        return(x)
    } else {
        return(x)
    }
}))

## We can now define some sample information to use
sample_info <- data.frame(
    run = colData(rse_gene)$run,
    group = sapply(geoinfo, function(x) { ifelse(grepl('uninduced', x$title),
        'uninduced', 'induced') }),
    gene_target = sapply(geoinfo, function(x) { strsplit(strsplit(x$title,
        'targeting ')[[1]][2], ' gene')[[1]][1] })
)

## Scale counts by taking into account the total coverage per sample
rse <- scale_counts(rse_gene)

## Add sample information for DE analysis
colData(rse)$group <- sample_info$group
colData(rse)$gene_target <- sample_info$gene_target

## Perform differential gene expression analysis with DESeq2
library('DESeq2')

## Specify design and switch to DESeq2 format
dds <- DESeqDataSet(rse, ~ gene_target + group)

# Workaround for: https://support.bioconductor.org/p/111792/
mcols(dds)$symbol <- unlist(lapply(mcols(dds)$symbol, paste, collapse=","))

## Perform DE analysis
dds <- DESeq(dds, test = 'LRT', reduced = ~ gene_target, fitType = 'local')
# dds <- DESeq(dds, test = 'LRT', reduced = ~ gene_target, fitType = 'local', parallel=T)
res <- results(dds)