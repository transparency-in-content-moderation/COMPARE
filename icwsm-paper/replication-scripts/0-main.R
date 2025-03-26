library(readtext)
library(tidyverse)
library(commonmark)
library(quanteda)
library(quanteda.textstats)
library(patchwork)

# Setting working directory
setwd("~/Documents/TCM/COMPARE/github/COMPARE/icwsm-paper/replication-scripts")
setwd("ADD-FILE_PATH/COMPARE/icwsm-paper/replication-scripts")

source("1-text-preparation.R")

source("2-creating-df.R")

source("3-analyses.R") 

source("4-visualizations.R") 
#source("3-appendix.R") - Chinese metrics are calculated in a python script, translation_comparison.R

#what else?
# - benchmarking readability? -> maybe analyses or visualization