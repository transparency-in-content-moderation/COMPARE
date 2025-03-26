library(readtext)
library(tidyverse)
library(commonmark)
library(quanteda)
library(quanteda.textstats)
library(patchwork)
library(ggrepel)
library(here)

# Setting working directory
setwd(here("icwsm-paper/replication-scripts"))

source("1-text-preparation.R")

source("2-creating-df.R")

source("3-analyses.R") 

source("4-visualizations.R") 

#source("5-appendix.R") 
#- Chinese metrics are calculated in a python script, 
# -translation_comparison.R
# robustness_tests_reviews
