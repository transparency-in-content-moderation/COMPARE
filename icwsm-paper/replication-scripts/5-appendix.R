
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

# Keep for checking for now - effect sizes have changed a tiny bit - significance levels remain the same
library(stargazer)
stargazer(model_length,model_complexity,model_categories,type= "html",
          out="stargazer2.html",
          no.space = TRUE,
          dep.var.labels = c("Length (log10)", "Flesch-Kincaid", "Semantic Complexity"),
          covariate.labels = c("EU","Other","USA","Monthly Visits","Year","Creator","Forum","Social Network","Decentralized","Alt-Tech"),
          float=F)

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
figure_a2

# Removing unnecessary objects
rm(data_external_val,graph_read_difficulty,graph_read_uncertainty,cor_read_cert,cor_read_diff)

## 3. Internal Validation of Readability Measurements ####

### 3.1 Calculating Gunning's Fog Index ####

# Reading text data in and performing text cleaning
source("1-text-preparation.R")

# Creating the corpus
corpus<-corpus(text_df, docid_field = "platform", text_field = "text")

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
  geom_bar(stat="summary", fun.y=mean, fill="#0072b2",width=0.5 ) +
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
  geom_bar(stat="summary", fun.y=mean, fill="#0072b2",width=0.5 ) +
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
  geom_bar(stat="summary", fun.y=mean, fill="#0072b2", width=0.5) +
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
  geom_bar(stat="summary", fun.y=mean, fill="#0072b2", width=0.5) +
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
rm(anova_read_age_FOG,anova_read_area_FOG,anova_read_size_FOG,anova_read_type_FOG,corpus,text_df,
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
figure_a4

# Removing unnecessary objects
rm(eng_texts,graph_scatterplot_english,graph_scatterplot_non_english,neng_texts,cor_scat_eng,cor_scat_neng,non_eng)

### 4.2 Platform-provided translations vs. machine translations ####
### 4.3 Google translations ?? ####
### 4.4 Chinese metrics ?? ####

