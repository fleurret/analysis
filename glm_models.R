library(ggplot2)
library(dplyr)
library(tidyr)
library(lsmeans)
library(glmmTMB)
library(DHARMa)
library(car)
library(stats)
library(circular)
# library(reshape2)
library(plotly)
library(rcompanion)

library(broom)
library(boot)


##### BEHAVIOR #####
df = read.csv('D:/Caras/Analysis/IC recordings/Behavior/behavior_thresholds.csv')
df = read.csv('D:/Caras/Analysis/MGB recordings/Behavior/behavior_thresholds.csv')
df_concat = merge(df, df2, all=T)

# Average over biological duplicates
df_grouped = df %>% group_by(Subject, Sex, Day) %>%
  summarise(
    threshold = mean(Threshold),
  )
df_grouped$Day = log(df_grouped$Day)
glm_data = df_grouped

glm_model <- glmmTMB((threshold) ~  Day + (1|Subject), data=glm_data, family=gaussian)

simulationOutput <- simulateResiduals(fittedModel = glm_model, plot = T, re.form=NULL)  # pass
summary(glm_model)
Anova(glm_model)

ggplot(data=df_grouped, aes(x=Day, y=threshold, group=Sex, color=Sex)) +
  geom_point() +
  stat_smooth(method='lm')

##### LEARNING #####

df = read.csv('D:/Caras/Analysis/IC recordings/Spreadsheets/Learning/FiringRate_threshold.csv')
df = read.csv('D:/Caras/Analysis/IC recordings/Spreadsheets/Learning/FiringRate_threshold_SU.csv')
df = read.csv('D:/Caras/Analysis/IC recordings/Spreadsheets/Learning/VScc_threshold_SU.csv')

df = read.csv('D:/Caras/Analysis/MGB recordings/Spreadsheets/Learning/FiringRate_threshold.csv')
df = read.csv('D:/Caras/Analysis/MGB recordings/Spreadsheets/Learning/FiringRate_threshold_SU.csv')
df = read.csv('D:/Caras/Analysis/MGB recordings/Spreadsheets/Learning/VScc_threshold_SU.csv')

df = read.csv('D:/Caras/Analysis/ACx recordings/Spreadsheets/Learning/FiringRate_threshold.csv')

# Average over biological duplicates
df_grouped = df %>% group_by(Subject, Sex, Day, Unit, Session, Validity) %>%
  summarise(
    threshold = mean(Threshold),
  )

df_grouped$Day = log(df_grouped$Day)

# anova
glm_data = df_grouped[df_grouped$Session == 'Active',]

glm_data = glm_data[!is.na(glm_data$threshold),]
glm_data$t = glm_data$threshold-mean(glm_data$threshold)

# VScc
glm_model <- glmmTMB(sqrt(threshold+2*abs(min(threshold)))~ Day + (1|Subject/Unit), data=glm_data, family=gaussian)
glm_model <- glmmTMB(threshold+2*abs(min(threshold)) ~ Day + (1|Subject/Unit), data=glm_data, family=gaussian)

# FR
glm_model <- glmmTMB(threshold-mean(threshold) ~ Day + (1|Subject/Unit), data=glm_data, family=gaussian)
glm_model <- glmmTMB(threshold ~ Day + (1|Subject/Unit),  data=glm_data, family=gaussian)


simulationOutput <- simulateResiduals(fittedModel = glm_model, plot = T, re.form=NULL)  # pass
summary(glm_model)
Anova(glm_model)

pairs(regrid(emmeans(glm_model,  ~ Day)),  adjust='Bonferroni')
contrast(regrid(emmeans(glm_model,  ~ Day)),  "trt.vs.ctrl", adjust='dunnett')



######################

# TASK-DEPENDENT

###### AM RATIO ANALYSIS #####

df = read.csv('D:/Caras/Analysis/IC recordings/Spreadsheets/Task/FiringRate_7days_AMRatio.csv')
df = read.csv('D:/Caras/Analysis/IC recordings/Spreadsheets/Task/FiringRate_AMCoV.csv')
df = read.csv('D:/Caras/Analysis/IC recordings/Spreadsheets/Task/FiringRate_NonAMCoV.csv')

df = read.csv('D:/Caras/Analysis/MGB recordings/Spreadsheets/Task/FiringRate_7days_AMRatio.csv')
df = read.csv('D:/Caras/Analysis/MGB recordings/Spreadsheets/Task/FiringRate_AMCoV.csv')
df = read.csv('D:/Caras/Analysis/MGB recordings/Spreadsheets/Task/FiringRate_NonAMCoV.csv')

# Average over biological duplicates
df_grouped = df %>% group_by(Subject, Sex, Unit, Session, Day, Type) %>%
  summarise(
    value = mean(CoV),
  )

# df_grouped$Day = as.factor(log(df_grouped$Day))
glm_data = df_grouped[df_grouped$Type == 'SU',]
# glm_data = df_grouped

# FR
glm_model <- glmmTMB(value ~ Session + (1|Subject/Unit), data=glm_data, family=gaussian)
glm_model <- glmmTMB(value ~ Session + (1|Subject/Unit), data=glm_data, family=gaussian)
glm_model <- glmmTMB(sqrt(value) ~ Session + (1|Subject/Unit), data=glm_data, family=gaussian)


glm_model <- glmmTMB(log(value) ~ Session + (1|Subject/Unit), data=glm_data, family=gaussian)
glm_model <- glmmTMB(log(value) ~ Session + (1|Subject/Unit), data=glm_data, family=gaussian)
glm_model <- glmmTMB(log(value) ~ Session + (1|Subject/Unit), data=glm_data, family=gaussian)

simulationOutput <- simulateResiduals(fittedModel = glm_model, plot = T, re.form=NULL)  # pass
summary(glm_model)
Anova(glm_model)
pairs(regrid(emmeans(glm_model,  ~ Session)),  adjust='Bonferroni')
p <- Anova(glm_model)$`Pr(>Chisq)`
p <- summary(pairs(regrid(emmeans(glm_model,  ~ Session)),  adjust='Bonferroni'))$t.ratio

# bootstrapping
s <- function(data, i) {
  data <- data[i,]
  glm_model <- glmmTMB(log(value) ~ Session + (1|Subject/Unit), data=data, family=gaussian)
  a <- Anova(glm_model)
  return(c(a$Chisq, a$`Pr(>Chisq)`))
}

b <- boot(df_grouped, s, R=999)
output <- tidy(b,conf.int=TRUE)


##### SESSION THRESHOLD ANALYSIS #####

df = read.csv('D:/Caras/Analysis/IC recordings/Spreadsheets/Learning/FiringRate_threshold.csv')
df = read.csv('D:/Caras/Analysis/IC recordings/Spreadsheets/Learning/FiringRate_threshold_SU.csv')
df = read.csv('D:/Caras/Analysis/IC recordings/Spreadsheets/Learning/VScc_threshold_SU.csv')
df = read.csv('D:/Caras/Analysis/IC recordings/Spreadsheets/Learning/VScc_threshold_split.csv')

df = read.csv('D:/Caras/Analysis/MGB recordings/Spreadsheets/Learning/FiringRate_threshold.csv')
df = read.csv('D:/Caras/Analysis/MGB recordings/Spreadsheets/Learning/FiringRate_threshold_SU.csv')
df = read.csv('D:/Caras/Analysis/MGB recordings/Spreadsheets/Learning/VScc_threshold_SU.csv')
df = read.csv('D:/Caras/Analysis/MGB recordings/Spreadsheets/Learning/VScc_threshold_split.csv')

# Average over biological duplicates
df_grouped = df %>% group_by(Subject, Unit, Session, Day, Validity) %>%
  summarise(
    threshold = mean(Threshold),
  )

df_grouped$Day = log(df_grouped$Day)

#glm_data = df_grouped[df_grouped$Condition == 'Both',]
glm_data = df_grouped

# VScc
glm_model <- glmmTMB(threshold ~ Session + (1|Subject/Unit), data=glm_data, family=gaussian)
glm_model <- glmmTMB(threshold ~ Session + (1|Subject/Unit), data=glm_data, family=gaussian) 


# FR
glm_model <- glmmTMB(Validity ~ Session + (1|Subject/Unit), data = glm_data, family=binomial)
glm_model <- glmmTMB((threshold) ~ Session  + (1|Subject/Unit), data=glm_data, family=gaussian)

glm_model <- glmmTMB(Validity ~ Session + (1|Subject/Unit), data = glm_data, family=binomial)
glm_model <- glmmTMB((threshold) ~ Session  + (1|Subject/Unit), data=glm_data, family=gaussian)

simulationOutput <- simulateResiduals(fittedModel = glm_model, plot = T, re.form=NULL)  # pass

summary(glm_model)
Anova(glm_model)
pairs(regrid(emmeans(glm_model,  ~ Session)),  adjust='Bonferroni')

p <- Anova(glm_model)$`Pr(>Chisq)`
p <- summary(pairs(regrid(emmeans(glm_model,  ~ Session)),  adjust='Bonferroni'))$t.ratio
options(digits = 10)

##### INTERACTION #####
df = read.csv('D:/Caras/Analysis/IC recordings/Spreadsheets/Learning/FiringRate_threshold_zero.csv')
# df = read.csv('D:/Caras/Analysis/IC recordings/Spreadsheets/Learning/FiringRate_threshold_zero_SU.csv')
df = read.csv('D:/Caras/Analysis/IC recordings/Spreadsheets/Learning/VScc_threshold_SU_zero.csv')

df = read.csv('D:/Caras/Analysis/MGB recordings/Spreadsheets/Learning/FiringRate_threshold_zero.csv')
# df = read.csv('D:/Caras/Analysis/MGB recordings/Spreadsheets/Learning/VScc_threshold_SU.csv')
df = read.csv('D:/Caras/Analysis/MGB recordings/Spreadsheets/Learning/VScc_threshold_SU_zero.csv')

df = read.csv('D:/Caras/Analysis/ACx recordings/concatenated.csv')

# Average over biological duplicates
df_grouped = df %>% group_by(Subject, Day, Unit, Session) %>%
  summarise(
    threshold = mean(Threshold),
  )

df_grouped$Subject = as.character(df_grouped$Subject)
df_grouped$Unit = as.character(df_grouped$Unit)

df_grouped$Day = log(df_grouped$Day)

glm_data = df_grouped

# FR
glm_model <- lme4::lmer(threshold ~ Session*Day + (1|Subject/Unit), data = glm_data)

glm_model <- glmmTMB(threshold ~ Session*Day  + (1|Subject/Unit), data=glm_data, family=gaussian)

# VScc
glm_model <- glmmTMB(threshold ~ Session*Day  + (1|Subject/Unit), data=glm_data, family=gaussian)

simulationOutput <- simulateResiduals(fittedModel = glm_model, plot = T, re.form=NULL)  # pass
summary(glm_model)
Anova(glm_model)

s <- function(data, i) {
  data <- data[i,]
  glm_model <- glmmTMB(threshold ~ Session*Day  + (1|Subject/Unit), data=data[i,], family=gaussian)
  a <- Anova(glm_model)
  return(c(a$Chisq[3], a$`Pr(>Chisq)`[3]))
}

b <- boot(glm_data, s, R=999)
output <- tidy(b,conf.int=TRUE)


##### ALL REGIONS #####
df = read.csv('D:/Caras/Analysis/allregions.csv')

# Average over biological duplicates
df_grouped = df %>% group_by(Subject, Unit, Session, Region, Validity) %>%
  summarise(
    threshold = mean(Threshold),
  )

df_grouped$Subject = as.character(df_grouped$Subject)
df_grouped$Unit = as.character(df_grouped$Unit)

glm_data = df_grouped

glm_data = df_grouped[df_grouped$Session == 'Pre',]
glm_data = df_grouped[df_grouped$Session == 'Active',]
glm_data = df_grouped[df_grouped$Session == 'Post',]

glm_model <- glmmTMB(Validity ~ Session*Region + (1|Subject/Unit), data=glm_data, family=binomial)
glm_model <- glmmTMB(Validity ~ Region + (1|Subject/Unit), data=glm_data, family=binomial)
glm_model <- glmmTMB(threshold ~ Region + (1|Subject/Unit), data=glm_data, family=gaussian)

simulationOutput <- simulateResiduals(fittedModel = glm_model, plot = T, re.form=NULL)  # pass

summary(glm_model)
Anova(glm_model)

interaction.plot(x.factor = glm_data$Region, trace.factor = glm_data$Session, response = glm_data$Validity, fun = mean)
pairs(regrid(emmeans(glm_model,  ~ Session*Region)),  adjust='Bonferroni')
p <- summary(pairs(regrid(emmeans(glm_model,  ~ Region)),  adjust='Bonferroni'))$t.ratio

##### VECTORS #####
# Rayleigh
v = read.csv('D:/Caras/Analysis/IC recordings/vectors.csv')
v = read.csv('D:/Caras/Analysis/MGB recordings/vectors.csv')

rad = circular(v$Angle, type=c("angles"), units=c("radians"))
r <- rayleigh.test(rad, mu=circular(0))
r <- rayleigh.test(rad, mu=circular(pi/2))
r <- rayleigh.test(rad, mu=circular(pi))
r <- rayleigh.test(rad, mu=circular(3*pi/2))

print(r, digits=4)
cor.test(v$X.component,v$Y.component, method = "spearman")

###### PROPORTION OF SENSITIVE UNITS ###### 
df = read.csv('D:/Caras/Analysis/IC recordings/Spreadsheets/Proportions.csv')
df = read.csv('D:/Caras/Analysis/MGB recordings/Spreadsheets/Proportions.csv')
df = read.csv('D:/Caras/Analysis/ACx recordings/Spreadsheets/Proportions.csv')

# Average over biological duplicates
df_grouped = df %>% group_by(Subject, Day, FR.SU, TotalSU) %>%
  summarise(
    prop = mean(FR),
  )

glm_data = df_grouped
glm_model <- glmmTMB((FR.SU/TotalSU) ~ Day + (1|Subject), data=glm_data, family=binomial, weights = TotalSU)


simulationOutput <- simulateResiduals(fittedModel = glm_model, plot = T, re.form=NULL)  # pass

summary(glm_model)
Anova(glm_model)
