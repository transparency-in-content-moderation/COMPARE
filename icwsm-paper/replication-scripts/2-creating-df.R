
## 1. Determining Length & Complexity ####

# Creating the corpus
corpus<-corpus(text_df, docid_field = "platform", text_field = "text")

# Length
length<-textstat_summary(corpus)
length <- length %>% select (document,tokens)

# Readability 
readability<- textstat_readability(corpus, 
                                   "Flesch.Kincaid",
                                   remove_hyphens = TRUE,
                                   intermediate = FALSE)



# Combining length and readability
df <- length %>%
  inner_join(readability,by="document")

# Changing column names
colnames(df)<-c("platform","tokens","Flesch-Kincaid")

## 2. Importing datasets ####

# COMPARE
compare <-read.csv("../../data/COMPARE.csv")
compare <- compare %>%
  filter(comguide_true ==1) %>% 
  select(name,countrycode,monvisit,year,decentralized,alt_tech,type)


# Banned categories coding
categories <-read.csv("../replication-data/banned_categories.csv")
categories <- categories %>% 
  select(platform,banned_categories)


## 3. Creating final dataset

# Removing remaining white spaces to avoid problems
df$platform <- trimws(df$platform)
compare$name <- trimws(compare$name)
categories$platform <- trimws(categories$platform)

# Merging datasets
df <-df %>%
  inner_join(compare, by = c("platform" ="name")) %>%
  inner_join(categories, by = "platform") 

# Removing unnecessary objects
rm(length,readability,text_df,categories,corpus,compare)

## 4. Data preparation ####

# Recoding geographical areas
df$area[df$countrycode == "USA"]<- "USA"
df$area[df$countrycode == "CHN"]<- "China"
df$area[df$countrycode == "DEU" |df$countrycode == "FRA" | df$countrycode == "POL" | df$countrycode == "LVA" | df$countrycode == "LUX"] <- "EU"
df$area[is.na(df$area)]<- "Other"


# Recoding platform size
df$platform_size<-NA
df$platform_size[df$monvisit>=800000000]<-"very large"
df$platform_size[df$monvisit>=100000000 & df$monvisit <800000000]<-"large"
df$platform_size[df$monvisit>=1000000 & df$monvisit <100000000]<-"medium"
df$platform_size[df$monvisit>=100000 & df$monvisit <1000000]<-"small"
df$platform_size[df$monvisit<100000]<-"very small"

# Binning year
df <- df %>%
  mutate(year_bin = cut(year, breaks = 5, include.lowest = TRUE, right = FALSE)) 

levels(df$year_bin) <- gsub("\\[|\\]", "", levels(df$year_bin))
levels(df$year_bin) <- gsub("\\(|\\)", "", levels(df$year_bin))
levels(df$year_bin) <- gsub("\\,", "-", levels(df$year_bin))


