
## 1. Regressions ####

### 1.1 Availability of community guidelines (logistic regression) ####
log_model <- glm(comguide_true ~  area + log(monvisit) + year + type + decentralized +alt_tech, data = compare, family = "binomial")
summary(log_model)

### 1.2 OLS Regressions ####
model_length<-lm(log(tokens) ~ area + log(monvisit) + year + type + decentralized +alt_tech ,data=df , na.action = na.omit)
model_complexity<-lm(Flesch_Kincaid ~  area + log(monvisit) + year + type + decentralized +alt_tech ,data=df , na.action = na.omit)
model_categories<-lm(banned_categories~  area + log(monvisit) + year + type + decentralized +alt_tech ,data=df , na.action = na.omit)

summary(model_length)
summary(model_complexity)
summary(model_categories)


# Removing unnecessary objects
rm(model_length,model_complexity,model_categories,log_model)

## 2. External Validation of Readability Measurements ####

# Reading in data
data_external_val <-read.csv("../replication-data/readability_external_validation.csv")


# Calculating correlations
cor_read_cert<-cor(data_external_val$Flesch_Kincaid,data_external_val$average_uncertainty)
cor_read_diff<-cor(data_external_val$Flesch_Kincaid,data_external_val$average_difficulty)


# Creating the scatter plot for uncertainty
graph_read_uncertainty <- ggplot(data_external_val, aes(x=average_uncertainty,y=Flesch_Kincaid, color = platform)) +
  geom_point(color = "#0072b2", size = 3,position="jitter") +
  geom_smooth(method = "lm", color = "black",size=0.3) +
  theme_bw(base_size = 14)+
  geom_text_repel(aes(label = platform), size = 3.4, color = "black") +  
  labs(
    title = "",
    x = "Uncertainty",
    y = "Flesch-Kincaid"
  ) +
  annotate("text", x = 2.4, y = 14,
           label = bquote(bold("r = ") * bold(.(round(cor_read_cert, 2)))), 
           size = 3.4, color = "black")+
  coord_cartesian(ylim=c(9,15))



# Creating the scatter plot for difficulty
graph_read_difficulty <- ggplot(data_external_val, aes(x=average_difficulty,y=Flesch_Kincaid, color = platform)) +
  geom_point(color = "#0072b2", size = 3,position="jitter") +
  geom_smooth(method = "lm", color = "black",size=0.3) +  
  theme_bw(base_size=14) +
  geom_text_repel(aes(label = platform), size = 3.4, color = "black") +  
  labs(
    title = "",
    x = "Difficulty",
    y = "Flesch-Kincaid"
  ) +
  annotate("text", x = 2.45, y = 14,
           label = bquote(bold("r = ") * bold(.(round(cor_read_diff, 2)))), 
           size = 3.4, color = "black")+
  coord_cartesian(ylim=c(9,15))

# Grouping graphs
figure_a2<-grid.arrange(graph_read_difficulty, graph_read_uncertainty, ncol=2)

# Displaying graph
gridExtra::grid.arrange(figure_a2)

# Removing unnecessary objects
rm(data_external_val,graph_read_difficulty,graph_read_uncertainty,cor_read_cert,cor_read_diff)

## 3. Internal Validation of Readability Measurements ####

### 3.1 Calculating Gunning's Fog Index ####

# Readability 
FOG<- textstat_readability(corpus, 
                                   "FOG",
                                   remove_hyphens = TRUE,
                                   intermediate = FALSE)

# Merging FOG into df
df <-df %>%
  inner_join(FOG, by = c("platform" ="document"))

### 3.2 ANOVA for group-based comparisons ####

# Area
anova_read_area_FOG<-aov(FOG~ area, data = df)
summary(anova_read_area_FOG)
TukeyHSD(anova_read_area_FOG)

# Size
anova_read_size_FOG<-aov(FOG ~ platform_size, data = df)
summary(anova_read_size_FOG)

# Age 
anova_read_age_FOG<-aov(FOG ~ year_bin, data = df)
summary(anova_read_age_FOG)

# Type
anova_read_type_FOG<-aov(FOG ~ type, data = df)
summary(anova_read_type_FOG)
TukeyHSD(anova_read_type_FOG)

### 3.3 Visualization ####

# Area
graph_read_fog_area <- ggplot(df, aes(y=FOG, x=area)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2",width=0.5 ) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Geographical Area")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Gunning’s Fog Index") +
  geom_hline(yintercept=mean(df$FOG), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,30))

# Size
graph_read_fog_size <- ggplot(df, aes(y=FOG, x=platform_size)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2",width=0.5 ) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Size")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Gunning’s Fog Index") +
  geom_hline(yintercept=mean(df$FOG), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,30))


# Age

# Filter out NA values
data_wo_NA_FOG <- df %>%
  filter(!is.na(FOG), !is.na(year_bin))


graph_read_fog_age <- ggplot(data_wo_NA_FOG, aes(y=FOG, x=year_bin)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2", width=0.5) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Age") +
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Gunning’s Fog Index") +
  geom_hline(yintercept=mean(data_wo_NA_FOG$FOG, na.rm=TRUE), 
             color='#808080', size=0.8, linetype="dashed")+
  coord_cartesian(ylim=c(0,30))


# Type
graph_read_fog_type<- ggplot(df, aes(y=FOG, x=type)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2", width=0.5) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Type")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Gunning’s Fog Index") +
  geom_hline(yintercept=mean(df$FOG), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,30))

# Grouping graphs
figure_a3 <- (graph_read_fog_area | graph_read_fog_size) /
  (graph_read_fog_age |graph_read_fog_type) +
  plot_layout(guides = "collect")#+

# Displaying graph
figure_a3

# Removing unnecessary objects
rm(anova_read_age_FOG,anova_read_area_FOG,anova_read_size_FOG,anova_read_type_FOG,corpus,
   data_wo_NA_FOG,FOG,graph_read_fog_age,graph_read_fog_area,graph_read_fog_size,graph_read_fog_type)

## 4. Readability Measurements Applied to a Multilingual Corpus ####

### 4.1 Translated vs. non-translated texts####

# Scatterplot English vs. non-English

# Listing non-English community guidelines
non_eng <- c("6.cn","Ameblo","Aparat","Bilibili","CSDN","Douban",
             "Douyin","Dxy","Hatenablog","Kakao","Knuddels",
             "Kuaishou","Nicovideo","Ninisite","Nnmclub","VK",
             "WeChat","Wykop","Xiaohongshu","YY","Zhanqi.tv","Zhihu")

# Adding a variable indicating whether the comguide is english or not
df <- df %>% 
  mutate(English = ifelse(!platform %in% non_eng, 1, 0))


# Creating subsets for english and non englsh texts
eng_texts <- df %>% 
  filter(English == 1)

neng_texts <- df %>% 
  filter(English ==0)

# Calculating correlations
cor_scat_eng<-cor(eng_texts$log_tokens,eng_texts$Flesch_Kincaid)
cor_scat_neng<-cor(neng_texts$log_tokens,neng_texts$Flesch_Kincaid)


# Creating scatterplot for english texts
graph_scatterplot_english<-ggplot(eng_texts, aes(x=log_tokens, y=Flesch_Kincaid,label=platform))+
  geom_point(color = "#0072b2",fill="#0072b2",size=1.5, position = 'jitter')+
  geom_smooth(method = lm, color="black",size=0.3)+
  theme_bw(base_size = 14)+
  xlab('Length')+
  ylab('Flesch-Kincaid')+
  coord_cartesian(ylim=c(5,18))+
  annotate("text", x = 2.7, y = 17.5,
           label = bquote(bold("r = ") * bold(.(round(cor_scat_eng, 2)))), 
           size = 3.4, color = "black")

# Creating scatterplot for non-english texts
graph_scatterplot_non_english<-ggplot(neng_texts, aes(x=log_tokens, y=Flesch_Kincaid,label=platform))+
  geom_point(color = "#0072b2",fill="#0072b2",size=1.5, position = 'jitter')+
  geom_smooth(method = lm, color="black",size=0.3)+
  theme_bw(base_size = 14)+
  xlab('Length')+
  ylab('Flesch-Kincaid')+
  coord_cartesian(ylim=c(5,18))+
  annotate("text", x = 3.1, y = 17.5,
           label = bquote(bold("r = ") * bold(.(round(cor_scat_neng, 2)))), 
           size = 3.4, color = "black")

# Grouping Figures
figure_a4<-grid.arrange(graph_scatterplot_english, graph_scatterplot_non_english, ncol=2)

# Displaying the graph
gridExtra::grid.arrange(figure_a4)

# Removing unnecessary objects
rm(eng_texts,graph_scatterplot_english,graph_scatterplot_non_english,neng_texts,cor_scat_eng,cor_scat_neng)

### 4.2 Platform-provided translations vs. machine translations ####

## Reading in texts

# WeChat
WeChat <- readtext("../../data/pga-versions/WeChat/Community Guidelines.md",encoding = "UTF-8") # Platform provided English translation
WeChatII <- readtext("../../data/community-guidelines/WeChat/WeChat_en.md",encoding = "UTF-8")
WeChat <-rbind(WeChat,WeChatII)

# Kakao 
Kakao <- readtext("../replication-data/Kakao_platform_provided_translation.md",encoding = "UTF-8")
KakaoII <- readtext("../../data/community-guidelines/Kakao/Kakao_en.md",encoding = "UTF-8")
Kakao <-rbind(Kakao,KakaoII)

# Renaming entries
WeChat$doc_id[WeChat$doc_id == "Community Guidelines.md"] <- "WeChat_Translation"
WeChat$doc_id[WeChat$doc_id == "WeChat_en.md"] <- "DeepL_Translation"
Kakao$doc_id[Kakao$doc_id == "Kakao_platform_provided_translation.md"] <- "Kakao_Translation"
Kakao$doc_id[Kakao$doc_id == "Kakao_en.md"] <- "DeepL_Translation"

## Text cleaning
WeChat$text <- sapply(WeChat$text, text_cleaning_markdown)
WeChat$text <- sapply(WeChat$text, text_cleaning_remaining_markdown)

Kakao$text <- sapply(Kakao$text, text_cleaning_markdown)
Kakao$text <- sapply(Kakao$text, text_cleaning_remaining_markdown)

## Text preparation

# Only keeping the first part of the WeChat guidelines (PGA only scraped a part)
WeChat_shortened <- WeChat$text[2]
WeChat_shortened <- strsplit(WeChat_shortened, " WeChat Community Guidelines\\.")[[1]][1]

# Update the dataframe
WeChat$text[2] <- WeChat_shortened

# Only keeping the first part (PGA only scraped a part)
Kakao_shortened <- Kakao$text[2]
Kakao_shortened <- strsplit(Kakao_shortened, "Kakao aims to create a")[[1]][1]

# Update the dataframe
Kakao$text[2] <- Kakao_shortened

## Creating Corpus and calculating readability
corpus_WeChat<-corpus(WeChat, docid_field = "doc_id", text_field = "text")
readability_WeChat <- textstat_readability(corpus_WeChat, "Flesch.Kincaid", 
                                           remove_hyphens = TRUE,
                                           intermediate = FALSE)

corpus_Kakao<-corpus(Kakao, docid_field = "doc_id", text_field = "text")
readability_Kakao <- textstat_readability(corpus_Kakao, "Flesch.Kincaid", 
                                          remove_hyphens = TRUE,
                                          intermediate = FALSE)

# Removing unnecessary objects
rm(Kakao,KakaoII,Kakao_shortened,readability_Kakao,corpus_Kakao,
   WeChat,WeChatII,WeChat_shortened,readability_WeChat,corpus_WeChat)

### 4.3 Google translations ####

#### 4.3.1 Importing and cleaning text ####

# Reading in translations generated with google
data_dir <- "../replication-data/comguides-translations-google"

import_google_translations <- function(data_dir) {
  txt_files <- list.files(data_dir, pattern = "_en_google\\.md$", full.names = TRUE)
  
  # Read the files
  text_data <- readtext(txt_files)
  
  # Extract the base filename and remove the extension manually
  base_names <- basename(txt_files)
  name_no_ext <- sub("\\.md$", "", base_names)
  
  # Remove the _en_google part
  text_data$platform <- sub("_en_google$", "", name_no_ext)
  
  # Keep only relevant columns
  text_data  <- text_data[, c("platform", "text")]
  
  return(text_data)
}

df_google_text <- import_google_translations(data_dir)

# Text cleaning
df_google_text$text <- sapply(df_google_text$text, text_cleaning_markdown)
df_google_text$text <- sapply(df_google_text$text, text_cleaning_remaining_markdown)

# Merging with remaining platforms form text_df
df_google_text <- text_df %>%
  filter(!(platform %in% non_eng)) %>%
  bind_rows(df_google_text)

#### 4.3.2 Creating df with radability based on google translations ####

# Creating a corpus
corpus_google<-corpus(df_google_text, docid_field = "platform", text_field = "text")

# Calculating readability
readability_google <- textstat_readability(corpus_google, c("Flesch.Kincaid"),
                                                     remove_hyphens = TRUE,
                                                     intermediate = FALSE)
# Renaming columns
colnames(readability_google)<- c("platform","Flesch_Kincaid_google")

# Merging with df
df <- df %>% 
  inner_join(readability_google, by = "platform") 

#### 4.3.3 ANOVAS ####

# Area
anova_read_area_google<-aov(Flesch_Kincaid_google~ area, data = df)
summary(anova_read_area_google)
TukeyHSD(anova_read_area_google)

# Size 
anova_read_size_google<-aov(Flesch_Kincaid_google ~ platform_size, data = df)
summary(anova_read_size_google)

# Age 
anova_read_age_google<-aov(Flesch_Kincaid_google ~ year_bin, data = df)
summary(anova_read_age_google)

# Type
anova_read_type_google<-aov(Flesch_Kincaid_google ~ type, data = df)
summary(anova_read_type_google)
TukeyHSD(anova_read_type_google)

#### 4.3.4 Visualizations ####

# Area
graph_read_google_area <- ggplot(df, aes(y=Flesch_Kincaid_google, x=area)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2",width=0.5 ) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Geographical Area")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Flesch-Kincaid") +
  geom_hline(yintercept=mean(df$Flesch_Kincaid_google), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,15))

# Size
graph_read_google_size <- ggplot(df, aes(y=Flesch_Kincaid_google, x=platform_size)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2",width=0.5 ) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Size")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Flesch-Kincaid") +
  geom_hline(yintercept=mean(df$Flesch_Kincaid_google), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,15))
  graph_read_google_size

# Age
# Filter out NA values
data_wo_NA_google <- df %>%
  filter(!is.na(Flesch_Kincaid_google), !is.na(year_bin))


graph_read_google_age <- ggplot(data_wo_NA_google, aes(y=Flesch_Kincaid_google, x=year_bin)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2", width=0.5) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Age") +
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Flesch-Kincaid") +
  geom_hline(yintercept=mean(data_wo_NA_google$Flesch_Kincaid_google, na.rm=TRUE), 
             color='#808080', size=0.8, linetype="dashed")+
  coord_cartesian(ylim=c(0,15))

# Type
graph_read_google_type<- ggplot(df, aes(y=Flesch_Kincaid_google, x=type)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2", width=0.5) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Type")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Flesch-Kincaid") +
  geom_hline(yintercept=mean(df$Flesch_Kincaid_google), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,15))

# Grouping graphs
figure_a5 <- (graph_read_google_area | graph_read_google_size) /
  (graph_read_google_age |graph_read_google_type) +
  plot_layout(guides = "collect")

# Displaying graph
figure_a5

# Removing unnecessary objects
rm(anova_read_age_google,anova_read_area_google,anova_read_size_google,anova_read_type_google,
   data_wo_NA_google,df_google_text,graph_read_google_area,graph_read_google_age,graph_read_google_size,
   graph_read_google_type,readability_google,corpus_google,non_eng,import_google_translations,import_PGA_texts,
   text_cleaning_markdown,text_cleaning_remaining_markdown,data_dir)

### 4.4 Chinese metrics ####

#### 4.4.1 Importing and merging Chinese metrics ####

# These scores were calculated using the cntext (https://pypi.org/project/cntext/) and jieba (https://pypi.org/project/jieba/) Python packages 
df_chinese_readability <- read.csv("../replication-data/chinese_readability_metrics.csv")

df_chinese_readability <- df %>% 
  inner_join(df_chinese_readability, by = "platform") %>%
  select (platform,area, platform_size, year_bin, type,token.count, readability3)

#### 4.4.2 ANOVAS ####

# Area
anova_read_area_chinese<-aov(readability3~ area, data = df_chinese_readability)
summary(anova_read_area_chinese)
TukeyHSD(anova_read_area_chinese)

# Size 
anova_read_size_chinese<-aov(readability3 ~ platform_size, data = df_chinese_readability)
summary(anova_read_size_chinese)

# Age
anova_read_age_chinese<-aov(readability3 ~ year_bin, data = df_chinese_readability)
summary(anova_read_age_chinese)

# Type
anova_read_type_chinese<-aov(readability3 ~ type, data = df_chinese_readability)
summary(anova_read_type_chinese)

#### 4.4.3 Visualizations ####

# Area
graph_read_chin_area <- ggplot(df_chinese_readability, aes(y=readability3, x=area)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2",width=0.5 ) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Geographical Area")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Chinese Readability Index") +
  geom_hline(yintercept=mean(df_chinese_readability$readability3), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,35))


# Size
graph_read_chin_size <- ggplot(df_chinese_readability, aes(y=readability3, x=platform_size)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2",width=0.5 ) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Size")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Chinese Readability Index") +
  geom_hline(yintercept=mean(df_chinese_readability$readability3), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,35))

# Age
# Filter out NA values
data_wo_NA_chinese <- df_chinese_readability %>%
  filter(!is.na(readability3), !is.na(year_bin))

graph_read_chin_age <- ggplot(data_wo_NA_chinese, aes(y=readability3, x=year_bin)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2", width=0.5) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Age")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Chinese Readability Index") +
  geom_hline(yintercept=mean(data_wo_NA_chinese$readability3, na.rm=TRUE), 
             color='#808080', size=0.8, linetype="dashed")+
  coord_cartesian(ylim=c(0,35))

# Type
graph_read_chin_type<- ggplot(df_chinese_readability, aes(y=readability3, x=type)) +
  geom_bar(stat="summary", fun=mean, fill="#0072b2", width=0.5) +
  stat_summary(fun.data=mean_cl_normal, geom="errorbar", width=0.2, color="black") +
  theme_bw() +
  ggtitle("Platform Type")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1))+
  xlab("") +
  ylab("Chinese Readability Index") +
  # stat_summary(fun=mean, geom="text", aes(label=round(..y.., 1)), 
  #              vjust=-0.5,hjust=-0.3, size=3, color="black") +
  geom_hline(yintercept=mean(df_chinese_readability$readability3), color='#808080', size=0.8,linetype="dashed")+
  coord_cartesian(ylim=c(0,35))


# Grouping graphs
figure_a6 <- (graph_read_chin_area | graph_read_chin_size) /
  (graph_read_chin_age |graph_read_chin_type) +
  plot_layout(guides = "collect")#+

# Displaying graph
figure_a6  

# Remove unnecessary objects
rm(data_wo_NA_chinese,df_chinese_readability,graph_read_chin_age,graph_read_chin_area,
   graph_read_chin_size,graph_read_chin_type,anova_read_age_chinese,anova_read_area_chinese,
   anova_read_size_chinese,anova_read_type_chinese)


