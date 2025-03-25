library(readtext)
library(tidyverse)
library(commonmark)
library(quanteda)
library(quanteda.textstats)

# setting working directory to source file location?

source("1-text-preparation.R")

source("2-creating-df.R")

#source("3-analyses.R") (check also banned_categories.R, descriptives_COMPARE.R)
#source("3-visualizations.R")
#source("3-robustness-checks.R") - Chinese metrics are calculated in a python script, translation_comparison.R

#what else?
# - benchmarking readability? -> maybe analyses or visualization