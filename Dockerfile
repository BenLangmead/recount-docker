FROM scientificlinux/sl:7

# epel required for R
RUN yum update -y && yum install -y epel-release

# requirements for various R/Biocondfuctor packages
RUN yum install -y R libcurl-devel openssl-devel libxml2-devel tzdata

# so that R can keep track of installed packages
RUN mkdir -p /usr/share/doc/R-3.5.2/html

RUN R -e 'install.packages("BiocManager", repos="http://cran.us.r-project.org")'
RUN R -e 'BiocManager::install(update=T, ask=F)'
RUN R -e 'BiocManager::install(c("SummarizedExperiment"))'

# workaround for lack of rngtools in R 3.5.2
RUN R -e 'BiocManager::install(c("pkgmaker", "digest", "stringr"))'
RUN R -e 'download.file("https://cran.r-project.org/src/contrib/Archive/rngtools/rngtools_1.3.1.tar.gz", destfile="/tmp/rngtools_1.3.1.tar.gz"); install.packages("/tmp/rngtools_1.3.1.tar.gz", repos=NULL); file.remove("/tmp/rngtools_1.3.1.tar.gz")'

# install the rest
RUN R -e 'BiocManager::install(c("DESeq2", "regionReport", "BiocStyle", "GEOquery", "testthat", "TxDb.Hsapiens.UCSC.hg38.knownGene"))'
RUN R -e 'BiocManager::install(c("recount"))'

# install the script
COPY quickstart.R /root/quickstart.R

# run script at startup time
CMD ["/usr/bin/Rscript", "/root/quickstart.R"]
