# Installing and loading packages
required <- c("readtext", "tidyverse", "commonmark", "quanteda", "quanteda.textstats",
              "patchwork", "ggrepel", "here")

# Check if packages are already installed, and install if missing
new_packages <- required[!(required %in% installed.packages()[, "Package"])]
if (length(new_packages)) install.packages(new_packages)


library(readtext) # version 0.91
library(tidyverse) # version 2.0.0
library(commonmark) # version 1.9.1
library(quanteda) # version 4.0.2
library(quanteda.textstats) # version 0.97
library(patchwork) # version 1.2.0
library(ggrepel) # version 0.9.5
library(gridExtra) # version 2.3

# Removing unnecessary objects
rm (required, new_packages)

# Setting working directory - please adjust your path
#setwd("~/ADJUST-PATH-HERE/COMPARE/icwsm-paper/replication-scripts")

source("1-text-preparation.R")

source("2-creating-df.R")

source("3-analyses.R") 

source("4-visualizations.R") 

source("5-appendix.R") 

