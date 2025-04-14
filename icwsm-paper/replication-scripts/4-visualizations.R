## Figure 1 ####
# This is just a visualization of our workflow

## Figure 2 ####
# Available content moderation links in COMPARE

# Setting order
desired_order <- c("Transparency","Guidelines","Process", "Enforcement","Privacy","ToS")
available_cm_links$info <- factor(available_cm_links$info, levels = desired_order)

# Creating graph
figure_2 <- ggplot(data = available_cm_links, aes(x = info, y = count, fill = URL)) +
  geom_col(position = "stack", color = "white") +
  theme_bw(base_size = 14) +
  xlab("") +
  ylab("") +
  ggtitle("") +
  coord_flip() +
  geom_text(aes(label = count), position = position_stack(vjust = 0.5), colour="white") + 
  scale_fill_manual(values = c("#808080", "#0072b2"))

# Displaying graph
figure_2

# Removing unnecessary objects
rm(desired_order,available_cm_links)

## Figure 3 ####
# Availability of community guidelines by platform characteristics

# Creating new column with yes/no strings
compare <- compare %>% 
  mutate(comguide_true_str = recode(comguide_true, `0` = "no", `1` = "yes")) 
  
### 3.1 Area ####

# Calculate availability of comguides by area
comguide_area <- compare %>% 
  group_by(area) %>% 
  count(comguide_true_str)
comguide_area$comguide_true_str <- as.factor(comguide_area$comguide_true_str)

# Create graph
graph_cg_av_area <- ggplot(data = comguide_area, aes(x = area, y = n, fill = comguide_true_str)) +
  geom_col(position = "stack", color = "white") +
  theme_bw(base_size = 14) +
  ggtitle("Geographical Area")+
  theme(plot.title = element_text(hjust = 0.5))+
  xlab("") +
  ylab("") +
  geom_text(aes(label = ifelse(n < 5, "", n)), position = position_stack(vjust = 0.5), colour = "white",size=3) +
  scale_fill_manual(values = c("#808080", "#0072b2")) +
  labs(fill = "Community Guidelines Available") +
  theme(text = element_text(size = 12),
        legend.position = "bottom",
        legend.direction = "horizontal",
        axis.text.x = element_text(angle = 45, hjust = 1))+
  coord_cartesian(ylim=c(0,65))

### 3.2 Size ####

# Setting order
order <- c("very small", "small","medium","large","very large")
compare$platform_size <- factor(compare$platform_size, levels = order)

# Calculate availability of comguides by size
comguide_size <- compare %>%
  group_by(platform_size) %>%
  count(comguide_true_str)

comguide_size$comguide_true_str <- as.factor(comguide_size$comguide_true_str)

# Create graph
graph_cg_av_size <- ggplot(data = comguide_size, aes(x = platform_size, y = n, fill = comguide_true_str)) +
  geom_col(position = "stack", color = "white") +
  theme_bw(base_size = 14) +
  ggtitle("Platform Size")+
  theme(plot.title = element_text(hjust = 0.5))+
  xlab("") +
  ylab("") +
  geom_text(aes(label = ifelse(n < 5, "", n)), position = position_stack(vjust = 0.5), colour = "white",size=3) +
  scale_fill_manual(values = c("#808080", "#0072b2")) +
  labs(fill = "Community Guidelines Available") +
  theme(text = element_text(size = 12),
        legend.position = "bottom",
        legend.direction = "horizontal",
        axis.text.x = element_text(angle = 45, hjust = 1))+
  coord_cartesian(ylim=c(0,65))

### 3.3 Age ####

# Binning years and calculating availability of comguides by age
comguide_year <- compare %>%
  mutate(year_bin = cut(year, breaks = 5, include.lowest = TRUE, right = FALSE)) %>%
  group_by(year_bin) %>%
  count(comguide_true_str) %>%
  mutate(year_bin = as.factor(year_bin),
         comguide_true_str = as.factor(comguide_true_str))

# Changing name of bins
levels(comguide_year$year_bin) <- gsub("\\[|\\]", "", levels(comguide_year$year_bin))
levels(comguide_year$year_bin) <- gsub("\\(|\\)", "", levels(comguide_year$year_bin))
levels(comguide_year$year_bin) <- gsub("\\,", "-", levels(comguide_year$year_bin))

# Removing NAs
comguide_year <- comguide_year %>%
  filter(!is.na(year_bin), !is.na(n))

# Creating graph
graph_cg_av_year_binned <- ggplot(data = comguide_year, aes(x = year_bin, y = n, fill = comguide_true_str)) +
  geom_col(position = "stack", color = "white") +
  theme_bw(base_size = 14) +
  ggtitle("Platform Age")+
  theme(plot.title = element_text(hjust = 0.5))+
  xlab("") +
  ylab("") +
  geom_text(aes(label = ifelse(n < 5, "", n)), position = position_stack(vjust = 0.5), colour = "white",size=3) +
  scale_fill_manual(values = c("#808080", "#0072b2")) +
  labs(fill = "Community Guidelines Available") +
  theme(text = element_text(size = 12),
        legend.position = "bottom",
        legend.direction = "horizontal",
        axis.text.x = element_text(angle = 45, hjust = 1))+
  coord_cartesian(ylim=c(0,65))

### 3.4 Type ####

# Calculating availability of comguides by type
comguide_type <- compare %>% 
  group_by(type) %>% 
  count(comguide_true_str)
comguide_type$comguide_true_str <- as.factor(comguide_type$comguide_true_str)

# Creating graph
graph_cg_av_type <- ggplot(data = comguide_type, aes(x = type, y = n, fill = comguide_true_str)) +
  geom_col(position = "stack", color = "white") +
  theme_bw(base_size = 14) +
  ggtitle("Platform Type")+
  theme(plot.title = element_text(hjust = 0.5))+
  xlab("") +
  ylab("") +
  geom_text(aes(label = ifelse(n < 5, "", n)), position = position_stack(vjust = 0.5), colour = "white",size = 3) +
  scale_fill_manual(values = c("#808080", "#0072b2")) +
  labs(fill = "Community Guidelines Available") +
  theme(text = element_text(size = 12),
        legend.position = "bottom",
        legend.direction = "horizontal",
        axis.text.x = element_text(angle = 45, hjust = 1))+
  coord_cartesian(ylim=c(0,65))

# Grouping plots together
figure_3 <- (graph_cg_av_area | graph_cg_av_size) /
  (graph_cg_av_year_binned | graph_cg_av_type) +
  plot_layout(guides = "collect") & 
  theme(legend.position = "bottom")

# Displaying graph
figure_3

# Removing unnecessary objects
rm(comguide_area,comguide_size,comguide_type,comguide_year,graph_cg_av_area,graph_cg_av_size,graph_cg_av_type,graph_cg_av_year_binned,order)

## Figure 4 ####
# Length by platform characteristics

### 4.1 Area ####

# Creating graph
graph_length_area <- ggplot(df, aes(y=tokens, x=area)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2",width=0.5 ) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Geographical Area")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Length") +
  geom_hline(yintercept=mean(df$tokens), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,20000))

### 4.2 Size ####

# Setting order
df$platform_size <- factor(df$platform_size, levels = c("very small", "small", "medium", "large", "very large"))

# Creating graph
graph_length_size <- ggplot(df, aes(y=tokens, x=platform_size)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2",width=0.5 ) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Size")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Length") +
  geom_hline(yintercept=mean(df$tokens), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,20000))

### 4.3 Age ####

# Filter out platforms without year
data_wo_NA<- df %>% 
  filter(!is.na(tokens) & !is.na(year_bin))

# Creating graph
graph_length_age <- ggplot(data_wo_NA, aes(y=tokens, x=year_bin)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2", width=0.5) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Age")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Length") +
  geom_hline(yintercept=mean(df$tokens), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,20000))

### 4.4 Type ####

# Crating graph
graph_length_type<- ggplot(df, aes(y=tokens, x=type)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2", width=0.5) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Type")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Length") +
  geom_hline(yintercept=mean(df$tokens), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,20000))

# Grouping graphs together
figure_4 <- (graph_length_area | graph_length_size) /
  (graph_length_age |graph_length_type) +
  plot_layout(guides = "collect")

# Displaying graph
figure_4

# Removing unnecessary objects
rm(graph_length_area,graph_length_age,graph_length_size,graph_length_type)   

## Figure 5 ####
# Readability by platform characteristics

### 5.1 Area ####

# Creating graph
graph_readability_area <- ggplot(df, aes(y=Flesch_Kincaid, x=area)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2",width=0.5 ) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Geographical Area")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Flesch-Kincaid") +
  geom_hline(yintercept=mean(df$Flesch_Kincaid), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,15))

### 5.2 Size ####

# Creating graph
graph_readability_size <- ggplot(df, aes(y=Flesch_Kincaid, x=platform_size)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2",width=0.5 ) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Size")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Flesch-Kincaid") +
  geom_hline(yintercept=mean(df$Flesch_Kincaid), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,15))

### 5.3 Age ####

# Creating graph
graph_readability_age<- ggplot(data_wo_NA, aes(y=Flesch_Kincaid, x=year_bin)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2", width=0.5) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Age")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Flesch-Kincaid") +
  geom_hline(yintercept=mean(df$Flesch_Kincaid), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,15))

### 5.4 Type ####

# Creating graph
graph_readability_type<- ggplot(df, aes(y=Flesch_Kincaid, x=type)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2", width=0.5) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Type")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Flesch-Kincaid") +
  geom_hline(yintercept=mean(df$Flesch_Kincaid), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,15))

# Grouping graphs
figure_5 <- (graph_readability_area | graph_readability_size) /
  (graph_readability_age |graph_readability_type) +
  plot_layout(guides = "collect")

# Displaying graph
figure_5

# Removing unnecessary objects
rm(graph_readability_age,graph_readability_area,graph_readability_size,graph_readability_type)

## Figure 6 ####
# Benchmarking readability

# Reading in benchmarking scores
benchmarking_readability_scores <-read.csv("../replication-data/benchmarking_readability_scores.csv")
benchmarking_readability_scores$X <- NULL

# Scores for abstracts and newspaper articles are replicated based on data and scripts from Rauh (2023) 
# (see here: https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/UGGXUF)
# The score for the Tweets is based on data from Özdemir and Rauh (2022) and the score for the
# Privacy Policies was extracted from Jensen and Potts(2004). For full references please consult the paper.


# Calculating stats for community guidelines
stats_comguides <- df %>% 
  summarise(
    text_type = "Community Guidelines",
    mean_readability = mean(Flesch_Kincaid, na.rm = TRUE),
    sd_readability = sd(Flesch_Kincaid, na.rm = TRUE),
    n = sum(!is.na(Flesch_Kincaid)),  
    se_readability = sd_readability / sqrt(n),  
    lower_ci = mean_readability - qt(0.975, df = n - 1) * se_readability,  
    upper_ci = mean_readability + qt(0.975, df = n - 1) * se_readability  
  )

# Binding rows together
benchmarking_readability_scores<-rbind(benchmarking_readability_scores,stats_comguides)

# Creating graph
figure_6<-ggplot(benchmarking_readability_scores, aes(x = reorder(text_type, mean_readability), y = mean_readability)) +
  geom_point(size = 3, color = "#0072b2") + 
  geom_errorbar(aes(ymin = lower_ci,ymax = upper_ci), width = 0.2) + 
  ylab('Average Flesch-Kincaid Grade Score')+
  xlab("")+
  theme_bw(base_size = 14) +
  coord_flip() 

# Displaying graph
figure_6

# Removing unneccessary objects
rm(benchmarking_readability_scores,stats_comguides)

## Figure 7 ####
# Heatmap with banned categories

# Reading in data with all categories and platforms
categories<-read.csv("../replication-data/banned_categories_all.csv")

# Setting rownames and removing column
rownames(categories) <- categories$Category  
categories$Category <- NULL  

# Aggregating categories to groups
category_map <- list(
  Child_Sexual_Exploitation = c("Child Sexual Exploitation","Minors Sexualization","Child Nudity","Child Exploitation Imagery"),
  Criminal_Behavior = c("Criminal Behavior", "Vandalism","Scams","Human Trafficking","Celebrating Own Crime","Theft"),
  Depiction_of_Dangerous_Behavior_Risking_Imitation = c("Depiction of Dangerous Behavior Risking Imitation", "Dangerous Challenges", "Suicide Depiction","Self-injury Depiction","Incitement to Dangerous Behavior","Eating Disorder Depiction"),
  Glorifying_Violent_Events = c("Glorifying Violent Groups/ Events", "Incitement to Violence","Terrorist Propaganda","Mass Murder Support","Hate Group Propaganda","Criminal Group Propaganda"),
  Graphic_Violence = c("Graphic Violence","Sexual Violence","Violence against Humans","Child Abuse","Animal Abuse"),
  Harassment = c("Harassment","Non-Consensual Intimate Imagery Threat", "Bullying", "Non-Consensual Sexual Touching","Repeated Unwanted Advances"),
  Hate_Speech = c("Hate Speech","Slurs","Inferiority","Hateful Images and Symbols","Exclusion/Segregation","Dehumanization"),
  Inauthentic_Behavior =c("Inauthentic Behavior","Fake Profiles","Spam","Engagement Abuse"),
  Misinformation =c("Misinformation","Interference with Elections","Propagading Conspiracy Theories","Health Related Misinformation","Fake News","Denying well Documented Historical Events","Denying Climate Change"),
  Nudity =c("Nudity","Adult Non-Sexual Nudity","Adult Non-Consensual Intimate Imagery"),
  Intellectual_Property_Infringement =c("Intellectual Property Infringement"),
  Political_Content =c("Political Content","Distorting Historical Narratives","Criticizing the Government/ Authorities","National Interests","National Unity","National Security"),
  Privacy_Violations =c("Privacy Violations","Impersonation","Exposure of Personal Information"),
  Platform_Security =c("Platform Security","Sharing Malicious Software","Interrupting Platform Services"),
  Sexual_Content =c("Sexual Content","Sexually Explicit Language","Sexual Solicitation","Sexual Activity","Prostitution"),
  Sale_of_Illegal_Goods =c("Sale of Illegal or Regulated Goods", "Pharmaceutical Sales", "Non-medical Drug Sale","Marijuana Sales","Live Animal Sale","Human Organ Sale","Firearm Sales","Endangered Species Sale",
                           "Counterfeit Products or Documents Sale", "Alcohol and Tobacco Sale")
)


# Create an empty data frame and sets column- and rownames
aggregated_categories <- data.frame(matrix(ncol = ncol(categories), nrow = length(category_map)))
colnames(aggregated_categories) <- colnames(categories)
rownames(aggregated_categories) <- names(category_map)

# Iterate over each category in 'category_map', aggregates the rows, and sums across rows
for (category in names(category_map)) {
  aggregated_categories[category, ] <- colSums(categories[category_map[[category]], , drop = FALSE])
}

# Removing column X.1
aggregated_categories$X.1<- NULL

# Removing weird x in names starting with a number
colnames(aggregated_categories)[colnames(aggregated_categories) == "X4chan"] <- "4chan"
colnames(aggregated_categories)[colnames(aggregated_categories) == "X6.cn"] <- "6.cn"
colnames(aggregated_categories)[colnames(aggregated_categories) == "X8kun"] <- "8kun"
colnames(aggregated_categories)[colnames(aggregated_categories) == "X9gag"] <- "9gag"

# Removing dots from platforms names - necessary to avoid NAs
colnames(aggregated_categories)[colnames(aggregated_categories) == "Sound.Cloud"] <- "Sound Cloud"
colnames(aggregated_categories)[colnames(aggregated_categories) == "Hive.Social"] <- "Hive Social"
colnames(aggregated_categories)[colnames(aggregated_categories) == "Steam.Community"] <- "Steam Community"
colnames(aggregated_categories)[colnames(aggregated_categories) == "Stack.Exchange"] <- "Stack Exchange"
colnames(aggregated_categories)[colnames(aggregated_categories) == "Hacker.News"] <- "Hacker News"

# Creating a long format df
aggregated_categories_long <- aggregated_categories %>%
  as_tibble(rownames = "Category") %>%  
  pivot_longer(cols = -Category, names_to = "Platform", values_to = "Count")


# Normalizing categories per group
aggregated_categories_long$categories_total[aggregated_categories_long$Category == "Child_Sexual_Exploitation"] <-  4
aggregated_categories_long$categories_total[aggregated_categories_long$Category == "Criminal_Behavior"] <-  6
aggregated_categories_long$categories_total[aggregated_categories_long$Category == "Depiction_of_Dangerous_Behavior_Risking_Imitation"] <-  6
aggregated_categories_long$categories_total[aggregated_categories_long$Category == "Glorifying_Violent_Events"] <-  6
aggregated_categories_long$categories_total[aggregated_categories_long$Category == "Graphic_Violence"] <-  5
aggregated_categories_long$categories_total[aggregated_categories_long$Category == "Harassment"] <-  5
aggregated_categories_long$categories_total[aggregated_categories_long$Category == "Hate_Speech"] <-  6
aggregated_categories_long$categories_total[aggregated_categories_long$Category == "Inauthentic_Behavior"] <-  4
aggregated_categories_long$categories_total[aggregated_categories_long$Category == "Misinformation"] <-  7
aggregated_categories_long$categories_total[aggregated_categories_long$Category == "Sale_of_Illegal_Goods"] <-  10
aggregated_categories_long$categories_total[aggregated_categories_long$Category == "Privacy_Violations"] <-  3
aggregated_categories_long$categories_total[aggregated_categories_long$Category == "Sexual_Content"] <-  5
aggregated_categories_long$categories_total[aggregated_categories_long$Category == "Nudity"] <-  3
aggregated_categories_long$categories_total[aggregated_categories_long$Category == "Platform_Security"] <-  3
aggregated_categories_long$categories_total[aggregated_categories_long$Category == "Intellectual_Property_Infringement"] <-  1
aggregated_categories_long$categories_total[aggregated_categories_long$Category == "Political_Content"] <-  6

aggregated_categories_long <- aggregated_categories_long %>%
  mutate(normalized_count = Count / categories_total)

# Renaming labels to lower case letters
category_labels <- c(
  "Child_Sexual_Exploitation" = "child sexual exploitation",
  "Criminal_Behavior" = "criminal behavior",
  "Depiction_of_Dangerous_Behavior_Risking_Imitation" = "dangerous behavior",
  "Glorifying_Violent_Events" ="glorifying violent events",
  "Graphic_Violence" = "graphic violence",
  "Harassment" = "harassment",
  "Hate_Speech" ="hate speech",
  "Inauthentic_Behavior"= "inauthentic behavior",
  "Misinformation"="misinformation",
  "Nudity"="nudity",
  "Intellectual_Property_Infringement" = "intellectual property infringement",
  "Political_Content" ="political content",
  "Privacy_Violations" ="privacy violations",
  "Platform_Security" = "platform security",
  "Sexual_Content"="sexual content",
  "Sale_of_Illegal_Goods"="sale of illegal goods")

# Determining order of categories
category_order <- aggregated_categories_long %>%
  group_by(Category) %>%
  summarise(mean_normalized_count = mean(normalized_count, na.rm = TRUE)) %>%
  arrange(mean_normalized_count) %>%
  pull(Category)

aggregated_categories_long$Category <- factor(aggregated_categories_long$Category, levels = category_order)



# Determining order of platforms by frequency
category_counts <- colSums(categories[, -1] > 0)  
category_counts <- categories %>%
  summarise(across(everything(), ~ sum(. > 0))) 

platform_order <- category_counts %>%
  pivot_longer(cols = everything(), names_to = "Platform", values_to = "NumberOfBannedCategories") %>%
  arrange(desc(NumberOfBannedCategories)) %>%
  pull(Platform)

# Fix platform names again in order to avoid NAs
platform_order[platform_order == "X4chan"] <- "4chan"
platform_order[platform_order == "X6.cn"] <- "6.cn"
platform_order[platform_order == "X8kun"] <- "8kun"
platform_order[platform_order == "X9gag"] <- "9gag"
platform_order[platform_order == "Sound.Cloud"] <- "Sound Cloud"
platform_order[platform_order == "Hive.Social"] <- "Hive Social"
platform_order[platform_order == "Steam.Community"] <- "Steam Community"
platform_order[platform_order == "Stack.Exchange"] <- "Stack Exchange"
platform_order[platform_order == "Hacker.News"] <- "Hacker News"

#Removing X.1 column
platform_order <- platform_order[-1]

aggregated_categories_long$Platform <- factor(aggregated_categories_long$Platform, levels = platform_order)

# Creating graph
figure_7 <- ggplot(aggregated_categories_long, aes(x = Platform, y = Category, fill = normalized_count)) +
  geom_tile() +
  theme_bw() +
  theme(legend.position = "none") +
  scale_fill_gradient(low = "white", high = "#0072b2") +
  theme(axis.text.x = element_text(angle = 45, 
                                   hjust = 1)) +
  scale_y_discrete(labels = category_labels) 

# Displaying graph
figure_7

# Removing unnecessary objects
rm(aggregated_categories,aggregated_categories_long,categories,
   category_counts,category_map,category,category_labels,
   category_order,platform_order)

## Figure 8 ####
# Semantic complexity by platform characteristics

### 8.1  Area ####

# Creating graph
graph_categories_area <- ggplot(df, aes(y=banned_categories, x=area)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2",width=0.5 ) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Geographical Area")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Semantic Complexity") +
  geom_hline(yintercept=mean(df$banned_categories), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,65))

### 8.2 Size ####

# Creating graph
graph_categories_size <- ggplot(df, aes(y=banned_categories, x=platform_size)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2",width=0.5 ) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Size")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Semantic Complexity") +
  geom_hline(yintercept=mean(df$banned_categories), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,65))

### 8.3 Age ####

# Creating graph
graph_categories_age<- ggplot(data_wo_NA, aes(y=banned_categories, x=year_bin)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2", width=0.5) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Age")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Semantic Complexity") +
  geom_hline(yintercept=mean(df$banned_categories), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,65))

### 8.4 Type ####

# Creating graph
graph_categories_type<- ggplot(df, aes(y=banned_categories, x=type)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2", width=0.5) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Type")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Semantic Complexity") +
  geom_hline(yintercept=mean(df$banned_categories), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,65))

# Grouping Graphs
figure_8 <- (graph_categories_area | graph_categories_size) /
  (graph_categories_age |graph_categories_type) +
  plot_layout(guides = "collect")

# Displaying graph
figure_8

# Removing unnecessary objects
rm(graph_categories_age,graph_categories_area,graph_categories_size,graph_categories_type,data_wo_NA)

## Figure 9 ####
# Scatterplots

# Choosing platforms to be displayed with name  
platform_selection = c("Patriots.win","Mastodon","Plurk","Slug","Xing","YouTube","Facebook","X",
                       "Snapchat","Pinterest","LinkedIn","TikTok","Douyin","Discord","Twitch",
                       "WeChat","Aparat","Foursquare","4chan","Hacker News","SlideShare","Kuaishou",
                       "Imo","Gettr","Flickr","WhatsApp","Reddit","Letterboxd","Bluesky","Truth Social", "Tumblr")#LINE/QUORA


# Creating scatterplot length x readability
graph_scatterplot_len_read<-ggplot(df, aes(x=log_tokens, y=Flesch_Kincaid,label=platform))+
  geom_point(color = "#0072b2",fill="#0072b2",size=1.5, position = 'jitter')+
  geom_smooth(method = lm, color="black",size=0.3)+
  theme_bw(base_size = 14)+
  xlab('Length')+
  ylab('Flesch-Kincaid')+
  geom_text_repel(data = df %>%
                  filter(platform %in% platform_selection),
                  aes(label=platform),
                  size=3,
                  color='black')+
  annotate("text", x = 2.6, y = 17.5,
           label = bquote(bold("r = ") * bold(.(round(cor_len_read, 2)))), 
           size = 3, color = "black")+
  theme(
    axis.title.x = element_text(size = 10), 
    axis.title.y = element_text(size = 10)  
  )

# Creating scatterplot length x semantic complexity
filtered_data1 <- df %>%
  filter (platform %in% platform_selection)

graph_scatterplot_len_cat <- ggplot(df, aes(x = log_tokens, y = banned_categories, label = platform)) +
  geom_point(color = "#0072b2", fill = "#0072b2", size = 1.5, position = 'jitter') +
  geom_smooth(method = lm, color = "black", size = 0.3) +
  theme_bw(base_size = 14) +
  xlab('Length') +
  ylab('Semantic Complexity') +
  geom_text_repel(data = filtered_data1, aes(label = platform), size = 3, color = 'black')+
  annotate("text", x = 2.6, y = 69,
           label = bquote(bold("r = ") * bold(.(round(cor_len_cat, 2)))), 
           size = 3, color = "black")+
  theme(
    axis.title.x = element_text(size = 10), 
    axis.title.y = element_text(size = 10)  
  )

# Creating scatterplot readability x semantic complexity
filtered_data2 <- df %>%
  filter(platform %in% platform_selection)

graph_scatterplot_read_cat <- ggplot(df, aes(x = Flesch_Kincaid, y = banned_categories, label = platform)) +
  geom_point(color = "#0072b2", fill = "#0072b2", size = 1.5, position = 'jitter') +
  geom_smooth(method = lm, color = "black", size = 0.3) +
  theme_bw(base_size = 14) +
  xlab('Flesch-Kincaid') +
  ylab('Semantic Complexity') +
  geom_text_repel(data = filtered_data2, aes(label = platform), size = 3.4, color = 'black')+
  annotate("text", x = 7, y = 69,
           label = bquote(bold("r = ") * bold(.(round(cor_read_cat, 2)))), 
           size = 3, color = "black")+
  theme(
    axis.title.x = element_text(size = 10), 
    axis.title.y = element_text(size = 10)  
  )

# Grouping graphs
figure_9 <- ( graph_scatterplot_len_cat | graph_scatterplot_read_cat | graph_scatterplot_len_read )  +
  plot_layout(guides = "collect") & 
  theme(legend.position = "bottom")

# Displaying graph
figure_9

# Removing unnecessary objects
rm(graph_scatterplot_len_cat,graph_scatterplot_len_read,graph_scatterplot_read_cat, 
   platform_selection,cor_len_cat,cor_len_read,cor_read_cat,
   filtered_data1,filtered_data2)

## Figure 10 ####
# Evolution of community guidelines

# read history of community guidelines versions archived in PGA-Versions
# and unrolled in the project pga-versions-unrolled
df_evolution <- read.csv("../replication-data/pga-versions-unrolled/data/pga-versions-community-guidelines.csv")

df_evolution$tokens <- sapply(df_evolution$text, ntoken)

# Calculating readability
corpus_evolution <- corpus(df_evolution,text_field = "text" )
readability_scores_evolution <- textstat_readability(corpus_evolution, measure = "Flesch.Kincaid", remove_hyphens = TRUE, intermediate = FALSE)
df_evolution$Flesch_Kincaid <- readability_scores_evolution$Flesch.Kincaid

# Creating a data frame
version_scores <- df_evolution %>%
  select(platform,date,tokens,Flesch_Kincaid) %>%
  drop_na()

# Remove outlier due to technical error
version_scores <-version_scores %>%  filter(!(platform == "Facebook" & date == "2019-03-20"))

# Remove Instagram
version_scores <-version_scores %>%  filter(!(platform == "Instagram"))

# Splitting data into two data frames
pga_old <- version_scores %>%
  filter(date <= as.Date("2021-12-24"))

pga_new <- version_scores %>%
  filter(date >= as.Date("2022-04-20"))

# Creating Graphs

# Length
options(repr.plot.width=18, repr.plot.height=6)
colors_old <- c("Facebook" = "#0081FB", "Instagram" = "#C13584", "X" = "#000000")


graph_versions_old_tokens<-ggplot(pga_old, aes(x = date, y = tokens, color = platform)) +
  theme_bw()+
  scale_color_manual(values = colors_old)+
  xlab(NULL) +
  ylab("Length")+
  labs(color = "Platform Name") +
  geom_vline(xintercept=as.Date("2015-03-24"),color='#808080',size=0.8)+ # Manila Principles
  geom_vline(xintercept=as.Date("2018-05-07"),color='#808080',size=0.8)+ # SCP 1.0
  geom_vline(xintercept=as.Date("2021-11-25"),color='#808080',size=0.8)+ # DSA Council Opinion
  scale_x_date(date_breaks = "1 year", date_labels = "%Y")+
  geom_point(size=1) +
  geom_line(size=0.5) +
  coord_cartesian(ylim=c(0,30000))+
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 45, hjust = 1))


colors_new <- c("Facebook" = "#0081FB", "Instagram" = "#C13584",
            "X" = "#000000","LINE"=	"#21B94E","LinkedIn"="#0077B5",
            "Pinterest"="#FFC0CB" , "Quora"="#800000","Reddit"="#FF5700",
            "Snapchat"= "#FFFC00", "YouTube"="#FF0000","Bluesky"="#50B8E2",
            "TruthSocial"="#5448EE", "Twitch"="#6441a5","TikTok"="#00f2ea")

graph_versions_new_tokens<-ggplot(pga_new, aes(x = date, y = tokens, color = platform)) +
  theme_bw()+
  scale_color_manual(values = colors_new)+
  xlab(NULL) +
  ylab("Length")+
  labs(color = "Platform Name") +
  geom_vline(xintercept=as.Date("2023-08-25"),color='#808080',size=0.8)+ # DSA entering into force
  scale_x_date(date_breaks = "3 months", date_labels = "%b %Y")+
  geom_point(size=1) +
  geom_line(size=0.5) +
  coord_cartesian(ylim=c(0,30000))+
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 45, hjust = 1))+
  scale_y_continuous(name = "Length", position = "right")

# Readability
graph_versions_old_readability<-ggplot(pga_old, aes(x = date, y = Flesch_Kincaid, color = platform)) +
  theme_bw()+
  scale_color_manual(values = colors_old)+
  xlab(NULL) +
  ylab("Flesch-Kincaid")+
  labs(color = "Platform Name")+
  geom_vline(xintercept=as.Date("2015-03-24"),color='#808080',size=0.8)+ # Manila Principles
  geom_vline(xintercept=as.Date("2018-05-07"),color='#808080',size=0.8)+ # SCP 1.0
  geom_vline(xintercept=as.Date("2021-11-25"),color='#808080',size=0.8)+ # DSA Council Opinion
  annotate("text",x=as.Date("2014-01-08"), y=14, label="Manila \n Principles",color="#808080")+
  annotate("text",x=as.Date("2016-11-07"), y=14, label="SCP 1.0",color="#808080")+
  annotate("text",x=as.Date("2020-7-15"), y=14, label="Council \n Opinion \n on DSA ",color="#808080")+
  scale_x_date(date_breaks = "1 year", date_labels = "%Y")+
  geom_point(size=1) +
  geom_line(size=0.5) +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 45, hjust = 1))+
  coord_cartesian(ylim=c(8,16))

graph_versions_new_readability<-ggplot(pga_new, aes(x = date, y = Flesch_Kincaid, color = platform)) +
  theme_bw()+
  scale_color_manual(values = colors_new)+
  xlab(NULL) +
  ylab("Flesch-Kincaid")+
  labs(color = "Platform Name")+
  geom_vline(xintercept=as.Date("2023-08-25"),color='#808080',size=0.8)+ # DSA entering into force
  annotate("text",x=as.Date("2023-05-10"), y=9, label="DSA entering \n into force",color="#808080")+
  scale_x_date(date_breaks = "3 months", date_labels = "%b %Y")+
  geom_point(size=1) +
  geom_line(size=0.5) +
  theme(legend.position="bottom",
        axis.text.x = element_text(angle = 45, hjust = 1))+
  coord_cartesian(ylim=c(8,16)) +
  scale_y_continuous(name = "Flesch-Kincaid", position = "right")

# Grouping Graphs
figure_10 <- (graph_versions_old_tokens | graph_versions_new_tokens ) /
  (graph_versions_old_readability | graph_versions_new_readability) +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom")
figure_10
