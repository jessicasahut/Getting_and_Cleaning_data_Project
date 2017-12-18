####################################################################################################################
## Getting and Cleaning Data: Peer Graded Assignment
##
## USER MUST:
## 1. Change the location of folderloc to their own local project directory
## 2. Once the zip file is downloaded, manually extract the files to folderloc/data/UCI HAR Dataset
##
## OUPUT FILE:C:/Users/sahutj/Box Sync/Resources/R/Coursera/GettingNCleaningData/Project/output_TidySummary.txt
##
####################################################################################################################


## libraries, file locations, data download -------------------------------------------------------

 
  library(stringr);library(tidyr);library(qdap);library(dplyr);library(knitr);library(markdown)



  # USER MUST manually unzip file to "./data/UCI HAR Dataset" before moving on to next step
  folderloc <- "C:/Users/sahutj/Box Sync/Resources/R/Coursera/3.GettingNCleaningData/Project";  setwd(folderloc)
 
  #creating subdirectory called "data" to hold downloaded data
  if (!file.exists("./data")) {dir.create("./data")}
 
  fileURL<-"https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"

  #NOTE - DO ONLY DO ONCE. No need to continually redownload data from the net 
  download.file(fileURL,destfile="./data/ImportData.zip") # commented out to prevent redownloading over and over
  
  
  # USER MUST manually unzip file to "./data/UCI HAR Dataset" before moving on to next step
 
  
  list.files("./data", recursive = TRUE)


  
## Read in data from downloaded files, stack training and test data  ------------------------------------------------------


  #Subjects: read in data sets that give the subject ID for each row
  SubjectsTest<-read.table("./data/UCI HAR Dataset/test/subject_test.txt", header=FALSE) 
  SubjectsTrain<-read.table("./data/UCI HAR Dataset/train/subject_train.txt", header=FALSE) 


  #Activities: read in data sets that give the measurement type for each row
  ActivityTest<-read.table("./data/UCI HAR Dataset/test/y_test.txt", header=FALSE) 
  ActivityTrain<-read.table("./data/UCI HAR Dataset/train/y_train.txt", header=FALSE) 


  #Measurements: read in data sets that give the measurement value for each row
  MeasTest<-read.table("./data/UCI HAR Dataset/test/x_test.txt", header=FALSE) 
  MeasTrain<-read.table("./data/UCI HAR Dataset/train/x_train.txt", header=FALSE) 

  
  #Feature Descriptions: read in features (measurement categories)
  Features<-read.table("./data/UCI HAR Dataset/features.txt", header=FALSE) 
  
  
  #Activity Descriptions: read in activity type descriptions
  ActivityDescriptions<-read.table("./data/UCI HAR Dataset/activity_labels.txt", header=FALSE) 
  
## Stack training and test data  ------------------------------------------------------
  
  Subjects<-bind_rows(SubjectsTest,SubjectsTrain) 
  Activities<-bind_rows(ActivityTest,ActivityTrain)
  Measurements<-bind_rows(MeasTest,MeasTrain)
  
  
## Assign meaningful variable names names and factor labels; Extract features corresponding to a mean or std-------------------------------------

  
  #KeptFeatures: Extract only measurements on the mean and std  (#2 in assigment), rename variables
  KeptFeatures<-Features%>%    
      filter(grepl("-mean\\(\\)|-std\\(\\)",V2)) %>%   #keep if description contains the string "-mean()" or "-std()"
      rename(featNum=V1,featDescription=V2) %>%        #renaming variables in Feature data frame
      mutate(featNum=paste0("V",featNum))              #putting a "V" before feat number to match variable names in Measurements data frame

  #Measurements: identify and keep only variables that corresponded to mean or std (found in last step)
  Measurements<-Measurements[names(Measurements) %in% KeptFeatures$featNum] 
  
  
  #Activities: Use descriptive activity names to name the activities in the data set (#3 in assignment)
  Activities<-merge(x=Activities,y=ActivityDescriptions,by="V1") %>% #replacing col names with labels
    rename(Activity=V2) %>%
    select(Activity)

  
  #Subjects: rename variable V1 to SubjectID
  Subjects<-rename(Subjects,SubjectID=V1)
  
  
  
## Merging all data into one WIDE form dataframe, then restructuring into LONG form-------------------------------------

  # All data merged into one (non tidy) data frame called WideFormData
  # 1 row for each subject x activity, 66 feature columns for each combination
  WideFormData<-bind_cols(Subjects,Activities,Measurements)

  
  # Wide data reformatted into a (semi- tidy) data frame called LongFormData  
  # 1 row for each subject x activity x feature, 1 "Value" column for each combination
  LongFormData<-gather(
    WideFormData
    ,featNum                 #  All the true variables are hidden in the long feature names, so the key created here and is named "featNum" to easily merge with long names data
    ,Value                   #  "Value" is the variable we create in the new data set to contain the data values
    ,-c(SubjectID,Activity)) #  SubjectID and Activity are the variables that are already correct, so we don't gather them 
  
  
  
  
## extracting seperate variables out of the long feature names, applying to LongFormData-------------------------------------
  
  #replacing abbreviations in feature names with long description
  ToBeReplaced<-c("^t","^f","Acc","Gyro","Mag")
  Replacements<-c("Time","Frequency","Accelerometer","Gyroscope","Magnitude")
  KeptFeatures$FullNames<-mgsub(ToBeReplaced,Replacements,KeptFeatures$featDescription,fixed=FALSE)

  #pulling long descriptions apart to form all variables in seperate columns
  VariableList<-mutate(KeptFeatures
 
           ,Domain=coalesce(                               
                  str_match(FullNames, "Time")        #if FullName contains the string "Time", str_match returns "Time" and this value is used
                  ,str_match(FullNames, "Frequency"))  #otherwise, if FullNames contains the string "Frequency", str_match returns "Frequency" and this value is used
           
           ,Device=coalesce(
                  str_match(FullNames, "Accelerometer")
                  ,str_match(FullNames, "Gyroscope"))
           
           ,AccelerationComponent= coalesce(
                  str_match(FullNames, "Body")
                  ,str_match(FullNames, "Gravity"))
           
           ,Stat=coalesce(
                  str_match(FullNames, "mean")
                  ,str_match(FullNames, "std"))   
     
           ,Axis=coalesce(
                  str_match(FullNames, "X")
                  ,str_match(FullNames, "Y")
                  ,str_match(FullNames, "Z")) 

           ,Jerk=str_match(FullNames, "Jerk")
           ,Magnitude=str_match(FullNames, "Magnitude")
           
   ) 
  
  #coercing newly made variables into factors
  ColstomakeFactors<-c("Domain","Device","AccelerationComponent","Stat","Axis","Jerk","Magnitude")
  VariableList[ColstomakeFactors] <- lapply(VariableList[ColstomakeFactors], factor)
  
  
  #checking that all variable combinations are unique.  If not, splitting had problems.
  identical(unique(VariableList[,4:10]),VariableList[,4:10])
  

  #final Tidy Dataset - one column for each variable, one row for each measurement

   Tidy<-merge(x=VariableList,y=LongFormData,by="featNum") %>% 
    
         select(SubjectID
                ,Activity
                ,Domain
                ,Device
                ,AccelerationComponent
                ,Stat
                ,Axis
                ,Jerk
                ,Magnitude
                ,Value) %>%
    
          group_by(SubjectID
                   ,Activity
                   ,Domain
                   ,Device
                   ,AccelerationComponent
                   ,Stat
                   ,Axis
                   ,Jerk
                   ,Magnitude)

  #look at summary to see if everything seems Ok
  summary(Tidy)
  
  #final data set of means (step 5 in assignment)
  TidySummary<-summarise(Tidy,meanVal=mean(Value,na.rm=TRUE),n=length(Value))
  


## write summary to a txt ile and create dynamic codebook -------------------------------------
  
  #write data frame to a txt file
  write.table(TidySummary,"output_TidySummary.txt", row.name=FALSE) 
  
  #dynamic codebook called "codebook.md" created with latest data
  knit("MakeCodebook.Rmd", output = "codebook.md", encoding = "ISO8859-1", quiet = TRUE)
