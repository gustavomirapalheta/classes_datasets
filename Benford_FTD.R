
options(scipen=999)   #   disable scientific notation 

#---- input area ------------------------
setwd("C:/R/Data")    # change to the directory containing your input csv file
#inFile<-"1_CensusData_2010a.csv"  
inFile<-'http://datayyy.com/data_csv/1_CensusData_2010a.csv'  # altervative infile 
outFile<-"BenfordFirstTwo_R.csv"

#People <- read.csv(file="1_CensusData_2010a.csv", header=TRUE)
People <- read.csv(inFile, header=TRUE)
class(People$People2010)
class(People$Area)
People$People2010 <- as.numeric(People$People2010)
View(People)
colnames(People)

TotPeople <- format(sum(People$People2010), nsmall=2, big.mark=",")
MinPeople <- format(min(People$People2010), nsmall=2, big.mark=",")
MaxPeople <- format(as.numeric(max(People$People2010)),nsmall=2,scientific=FALSE,big.mark=",")

str(People)
summary(People$People2010)
People<-People[!(People$People2010<0.01),] # Delete records < 0.01

# Multiply records 0.01<=x<10 by 1000 to move decimal point to the right
People$People2010 <- ifelse(People$People2010 <10 & People$People2010 >=0.01,
   People$People2010*1000,People$People2010)

# Extract and Sum the Digit Frequencies
FT       <- substr(People$People2010,1,2)
FTD      <- as.numeric(FT)
Count    <- aggregate(data.frame(Count=FTD),list(FirstTwo=FTD),length)
FTDCount <- data.frame(Count$FirstTwo, Count$Count)

# Rename the FirstTwo and Count fields
colnames(FTDCount)[colnames(FTDCount)=="Count.FirstTwo"]<-"FirstTwo"
colnames(FTDCount)[colnames(FTDCount)=="Count.Count"]<-"Count"

# Check: Is there a positive (>0) count for each possible First-Two Digits?
CheckErr1 <- NROW(FTDCount)
CheckErr2 <- sum(FTDCount$FirstTwo)
if(CheckErr1!= 90)   warning('Count of First-Two Digits ne 90')
if(CheckErr2!= 4905) warning('First-Two Digits not = 10:99')

# Prepare the components of the Benford Table
FTDigit    <- c(10:99)
Count      <- c(FTDCount$Count)
TotObs     <- sum(Count)
Actual     <- round(Count/TotObs, digits=6)
Benford    <- round(log10(1+1/FTDigit), digits=6)
Difference <- round(Actual-Benford, digits=6)
AbsDiff    <- round(abs(Difference), digits=6)
Zstat      <- round((abs(Actual-Benford)-(1/(2*TotObs)))/(sqrt(Benford*(1-Benford)/TotObs)), digits=6)
Zstat      <- ifelse(Zstat<0, 0, Zstat)

# Combine the components of the Benford Table with reasonableness tests
BenTest <- cbind(FTDigit,Count,Actual,Benford,Difference,AbsDiff,Zstat)
head(BenTest, n=5)
tail(BenTest, n=5)
str(BenTest)
summary(Count)

# Calculate the Mean Absolute Deviation (MAD) to assess conformity
MAD <- round(mean(AbsDiff), digits = 5)
if(MAD>0.0022){
     con<-"Nonconformity"
}else if(MAD>0.0018) {
     con<-"Marginally acceptable conformity"
}else if(MAD>0.0012) {
     con<-"Acceptable conformity"
}else{
     con<-"Close conformity"
}
#
cat('Our conclusion is:',con,"\n")
write.csv(BenTest, file=outFile)    # Write the results to a csv file



