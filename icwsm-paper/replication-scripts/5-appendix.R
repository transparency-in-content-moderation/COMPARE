
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

## 2. External Validation of Readability Measurements ####

# - Lab study difficulty/uncertainty data
# - FK scores from that time

## 3. Internal Validation of Readability Measurements ####

# - Gunning's Fog Index

## 4. Readability Measurements Applied to a Multilingual Corpus ####

#- translated vs. non translated text
#- platform-provided vs. machine translations
#- Google translations ??
#- Chinese metrics


