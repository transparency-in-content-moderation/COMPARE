## 1. Descriptives ####

### 1.1 COMPARE ####

# Country distribution 
table(compare$countrycode) 

# Platform size distribution
summary(compare$monvisit)

# Platform age distribution
summary(compare$year)

# Distribution of decentralized and alt_tech platforms
table(compare$decentralized)
table(compare$alt_tech)

### 1.2 Availability of content moderation links ####

# Recoding 0 to "no" and 1 to "yes"
compare$privacy_b[!is.na(compare$privacy)] <- "yes"
compare$privacy_b[is.na(compare$privacy)] <- "no"

compare$tos_b[!is.na(compare$tos)] <- "yes"
compare$tos_b[is.na(compare$tos)] <- "no"

# Only keeping true comguides
compare$comguide_b[!is.na(compare$comguide) & compare$comguide_true == 1] <- "yes"
compare$comguide_b[is.na(compare$comguide) | compare$comguide_true == 0] <- "no"

compare$trarep_b[!is.na(compare$trarep)] <- "yes"
compare$trarep_b[is.na(compare$trarep)] <- "no"

compare$enfopt_b[!is.na(compare$enfopt)] <- "yes"
compare$enfopt_b[is.na(compare$enfopt)] <- "no"

compare$cmpro_b[!is.na(compare$cmpro)] <- "yes"
compare$cmpro_b[is.na(compare$cmpro)] <- "no"


# Counting frequencies of available links
links_freq <- list()
links_freq$privacy_b <- table(compare$privacy_b)
links_freq$tos_b <- table(compare$tos_b)
links_freq$comguide_b <- table(compare$comguide_b)
links_freq$trarep_b <- table(compare$trarep_b)
links_freq$enfopt_b <- table(compare$enfopt_b)
links_freq$cmpro_b <- table(compare$cmpro_b)


# Combining frequencies and renaming columns
links <- do.call(cbind, links_freq) %>% as.data.frame()
colnames(links)<-c("Privacy","ToS","Guidelines","Transparency","Enforcement","Process")
links$row <- rownames(links)

# Creating long dataset and renaming columns
available_cm_links <- pivot_longer(links, cols = -row, names_to = "column", values_to = "value") %>% select("column","row","value")
colnames(available_cm_links) <- c("info","URL","count")

# Removing unnecessary objects
rm(links,links_freq)

### 1.3 Complexity metrics ####

# Length
summary(df$tokens)

# Readability
summary(df$Flesch_Kincaid)

# Semantic complexity
summary(df$banned_categories)

## 2. ANOVAS for group based comparisons ####

#### 2.1 Length ####
# Only size is significant

# Area
anova_length_area<-aov(tokens ~ area, data = df)
summary(anova_length_area)

# Size
anova_length_size<-aov(tokens ~ platform_size, data = df)
summary(anova_length_size)
TukeyHSD(anova_length_size)

# Age 
anova_length_age<-aov(tokens ~ year_bin, data = df)
summary(anova_length_age)

# Type
anova_length_type<-aov(tokens ~ type, data = df)
summary(anova_length_type)

### 2.2  Readability ####
# Area & Type (Forum) are significant

# Area
anova_read_area<-aov(Flesch_Kincaid ~ area, data = df)
summary(anova_read_area)
TukeyHSD(anova_read_area)

# Size 
anova_read_size<-aov(Flesch_Kincaid ~ platform_size, data = df)
summary(anova_read_size)

# Age 
anova_read_age<-aov(Flesch_Kincaid ~ year_bin, data = df)
summary(anova_read_age)

# Type
anova_read_type<-aov(Flesch_Kincaid ~ type, data = df)
summary(anova_read_type)
TukeyHSD(anova_read_type)

### 2.3  Semantic Complexity ####
# Size is significant

# Area
anova_cat_area<-aov(banned_categories~ area, data = df)
summary(anova_cat_area)

# Size 
anova_cat_size<-aov(banned_categories~ platform_size , data = df)
summary(anova_cat_size)
TukeyHSD(anova_cat_size)

# Age (year_bin)
anova_cat_age<-aov(banned_categories~ year_bin, data = df)
summary(anova_cat_age)

# Type
anova_cat_type<-aov(banned_categories~ type, data = df)
summary(anova_cat_type)

rm(anova_length_age,anova_length_area,anova_length_size,anova_length_type,
   anova_read_age,anova_read_area,anova_read_size,anova_read_type,
   anova_cat_age,anova_cat_area,anova_cat_size,anova_cat_type)
   
## 3. Correlations ####

# Calculating log 10 of tokens
df$log_tokens<-log10(df$tokens)  

# Correlation between length and readability
cor_len_read<-cor(df$log_tokens,df$Flesch_Kincaid)
cor_len_read

# Correlation between length and semantic complexity
cor_len_cat<-cor(df$log_tokens,df$banned_categories)
cor_len_cat

# Correlation between readability and semantic complexity
cor_read_cat<-cor(df$Flesch_Kincaid,df$banned_categories)
cor_read_cat
