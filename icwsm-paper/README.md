# Written for Lawyers or Users? Mapping the Complexity of Community Guidelines

This repository contains the [data](replication-data) and [scripts](replication-scripts) for replicating the results of our ICWSM paper 
[Written for Lawyers or Users? Mapping the Complexity of Community Guidelines](ADD LINK).

+ [**0-main.R**](replication-scripts/0-main.R) installs and loads libraries, sets the working directory, and executes all of the following scripts
+ [**1-text-preparation.R**](replication-scripts/1-text-preparation.R) reads the community guidelines in one dataframe (text_df) and performs the text cleaning
+ [**2-creating-df.R**](replication-scripts/2-creating-df.R) determines the metrics for length and readability and combines this with the platform information from COMPARE
+ [**3-analyses.R**](replication-scripts/3-analyses.R) contains all descriptive statistics mentioned in the paper
+ [**4-visualizations.R**](replication-scripts/4-visualizations.R) produces the visualizations of all Figures
+ [**5-appendix.R**](replication-scripts/5-appendix.R) can be used to replicate the results from the Appendix
