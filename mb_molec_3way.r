remove(list = ls())
library(glmnet)
library(caret)
library(MLeval)
library(qpcR)
library(readxl)
library(dplyr)
library(ggplot2)
library(GGally)
library(pROC)
library(gbm)
set.seed(500) 


## DATA set up for LASSO TRAIN
lasso_data <- read_excel("~/Desktop/peds_tumor/mbpyradiomics/molec_classifier/3way/mb_t1_t2_3way.xlsx")
lasso_data[,"molec_id"]  <- NULL
lasso_data[,"seg_id"]  <- NULL
lasso_data[,"dx_date"]  <- NULL
lasso_data[,"alive"]  <- NULL
lasso_data[,"os"]  <- NULL
lasso_data[,"pfs"]  <- NULL

lasso_data$sex[lasso_data$sex == "M"] <- "0"
lasso_data$sex[lasso_data$sex == "F"] <- "1"
lasso_data$sex <- as.factor(lasso_data$sex)
#View(lasso_data)

#lasso_data<-lasso_data[!(lasso_data$molecular=="3 or 4"),]
#lasso_data<-lasso_data[!(lasso_data$molecular=="shh or 3 or 4"),]
#lasso_data<-lasso_data[!(lasso_data$molecular=="?"),]


#head(lasso_data)
count(lasso_data, molecular)
ncol(lasso_data)

inTraining <- createDataPartition(lasso_data$molecular, p = 0.70, list = FALSE)
training <- lasso_data[inTraining,]
testing <- lasso_data[-inTraining,]

count(lasso_data, molecular)
count(training, molecular)
count(testing, molecular)


#need to customize column range to match number of features
dimcol <- ncol(lasso_data) #check 
x <- (training[, 2:dimcol])
View(x)


#formats features to dataframe
x_final.df <- data.frame(x)
x_final <- model.matrix( ~., x_final.df)
x_final <- x_final[,-1] #remove intercept
#View(x_final)

#extract output data, stored in column 1
y <- training[, 1]

#formats output to data frame, convert to binary/numeric
y.df <- data.frame(y)
View(y)

y_binary <- model.matrix( ~., y.df)
View(y_binary)

y_binary <- y_binary[,-1] #remove intercept
sapply(y_binary[1], class)
View(y_binary)


#####
#LASSO
print('Training Dataset -  LASSO Multi Classification')
cvfit = cv.glmnet(x_final, y_binary, family = "multinomial", nfolds = 10, type.measure = "mse", keep = TRUE)
cvfit
plot(cvfit)

#Set up matrix to collect predicted coefficients
#rows matching the number of columns in x_final i.e. the number of features
#need to add 1 because there is an intercept generated with "Coefficients" in the loop
AllCoefficients1 = sparseMatrix(ncol(x_final)+1,1)
AllCoefficients2 = sparseMatrix(ncol(x_final)+1,1)
#AllCoefficients3 = sparseMatrix(ncol(x_final)+1,1)

AllErrors1 <-matrix() # rows = length of lambda stored in "cvm"; default i 100. col = # of seeds
AllErrors2 <-matrix() # rows = length of lambda stored in "cvm"; default i 100. col = # of seeds
#AllErrors3 <-matrix() # rows = length of lambda stored in "cvm"; default i 100. col = # of seeds

#Loops through the number of iterations of LASSO
#Can change seed iterations here

head(coeff1) #should see all the coefficients
head(Active.Index1) #should see a vector of indices
head(coeff1[Active.Index1]) #should see the coeff for that vector
head(AllCoefficients1) #should see concatenation of indices

for (i in 1:100) {
  print(i)
  set.seed(1)
  cvfit = cv.glmnet(x_final, y_binary, family = "multinomial", nfolds = 10)
  Coefficients <- coef(cvfit, s = cvfit$lambda.min) #yields Coefficients for given cycle
  coeff1 <- Coefficients[["molecularshh"]] #access the matrix for molecularwnt in the list containing matrices for molecular subtypes
  coeff2 <- Coefficients[["molecularwnt"]] 
  #coeff3 <- Coefficients[["molecularwnt"]] 
  head(coeff1)
  head(coeff2)
  Active.Index1 <- which(coeff1 !=0) #yields vector returning the column-inputs that were significant
  Active.Index2 <- which(coeff2 !=0)
  #Active.Index3 <- which(coeff3 !=0)
  head(Active.Index1)
  head(Active.Index2)
  
  Active.Coefficients1 <- coeff1[Active.Index1] #yields the coefficients of those significant columns
  Active.Coefficients2 <- coeff2[Active.Index2]
  #Active.Coefficients3 <- coeff2[Active.Index3]
  
  AllCoefficients1 <- cbind(AllCoefficients1, coeff1) #stores all the estimated coefficients for output--includes zeros
  AllCoefficients2 <- cbind(AllCoefficients2, coeff2)
  #AllCoefficients3 <- cbind(AllCoefficients3, coeff3)
  
  cvfit$cvm <- append(cvfit$cvm,i) #where cvfit$cvm is the mean cross-validated error - a vector of length length(lambda).
  AllErrors1 <- qpcR:::cbind.na(AllErrors1, cvfit$cvm) #stores all the errors for output
  AllErrors2 <- qpcR:::cbind.na(AllErrors2, cvfit$cvm) 
  #AllErrors3 <- qpcR:::cbind.na(AllErrors3, cvfit$cvm) 
}  
write.csv(as.data.frame(as.matrix(AllCoefficients1)), file = "~/Desktop/peds_tumor/mbpyradiomics/molec_classifier/3way/LASSO_multi_features1.csv") ## may not write if path is incorrect
write.csv(as.data.frame(as.matrix(AllCoefficients2)), file = "~/Desktop/peds_tumor/mbpyradiomics/molec_classifier/3way/LASSO_multi_features2.csv") ## may not write if path is incorrect
#write.csv(as.data.frame(as.matrix(AllCoefficients3)), file = "~/Desktop/peds_tumor/mbpyradiomics/molec_classifier/4way/LASSO_multi_features3.csv") ## may not write if path is incorrect

#write.csv(as.data.frame(as.matrix(AllErrors1)), file = "~/Desktop/peds_tumor/mbpyradiomics/molec_classifier/4way/LASSO_multi_errors1.csv")
#write.csv(as.data.frame(as.matrix(AllErrors2)), file = "~/Desktop/peds_tumor/mbpyradiomics/molec_classifier/4way/LASSO_multi_errors2.csv")
#write.csv(as.data.frame(as.matrix(AllErrors3)), file = "~/Desktop/peds_tumor/mbpyradiomics/molec_classifier/4way/LASSO_multi_errors3.csv")
