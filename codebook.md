# Initial download, "raw" data 
The data, downloaded from https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip, come in seperate files: the _test_ and _training_ data for _subjects_, _activities_, and phone _measurements_.  Each row of these data correspons to a single _person_ x _activity_, with hundreds of _measurements_ taken on each.   

| Vector of subject IDs | Vector of activity values | Matrix of measurements |
|--------------------|----------------------|------------------------|
| _subject_train.txt_     | _y_train.txt_        | _x_train.txt_          |
| _subject_test.txt_          | _y_test.txt_            | _x_test.txt_              |

A features file lists the column headings for the measurements matrix. The feature names that corresponed to a mean or std are identified, and used to filter the measurements matrix.  Only measurements corresponding to a mean or std are kept.

| Column headings for matrix of measurements | 
|--------------------|
| _features.txt_ | 

An activity labels file gives a crosswalk between the activity values and their labels.

| Activity values crosswalked with labels|  
|--------------------|
|_activity_labels.txt_ | 

# First transformation into wide-form data
1. The training and test data sets are stacked vertically with the _bind_rows_ function (dplyr package).  This is done seperately for subjects, activities, and measurements.
2. The _grepl_ function is used to identify features names that contain the string "-mean()" or "-std()", and the _filter_ function is used to keep just the features that are flagged as such.  The measurements data are then restricted to just the columns where the feature number (V1, V2, etc) is %in% this list.
3. The activities values are replaced with meaningful labels by merging the crosswalk and the activity values. 
4. The variables are given meaningful names in the subjects and activity data sets.
then horizontally merging the subject, activity, and (filtered) measurements matrix with the _bind_cols_ function. 
5. The subjects, activities, and (filtered) measurements data frames are merged horizonally with the _bind_cols_ funciton (dplyr package) 

# Second transformation into long-form data
1. The _gather_ function (dplyr package) is used to transform the data into long form so that there is one row for every _subject_ x _activity_ x _measurement_. A single _value_ column holds the values that were previously listed under each measurement heading.  
```r
  LongFormData<-gather(
    WideFormData
    ,featNum                 #  All the true variables are hidden in the long feature names, so the key created here and is named "featNum" to easily merge with long names data
    ,Value                   #  "Value" is the variable we create in the new data set to contain the data values
    ,-c(SubjectID,Activity)) #  SubjectID and Activity are the variables that are already correct, so we don't gather them 
```

2. Using the _mgsub_ function (qdap package), abbreviations are searched for and replaced in the feature desctiption.  Then these expanded feature descriptions are pulled apart with the _str_match_ function (stringr package) to produce seven seperate variables.



```r
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
``` 

 
 3. The long-form data produced in (1) is merged with the full set of variables produced in (2) to produce the pent-ultimate tidy data set.  This long-form data frame is filtered to inly contain the following columns

Field name    | Meaning
-----------------|------------
SubjectID         | Subject's ID.  Between 1 and 30
Activity         | Activity being performed
Domain       | Whether measuring a Time or Frequency
Device   | Whether measured with Accelerometer or Gyroscope
AccelerationComponent | Whether measuring Body or Gravity acceleration
Stat     | Whether value represents a mean or a standard deviation (std)
Axis    | X, Y, or Z (or none of above) movement
Jerk         | whether or not a jerk is being measured
Magnitude        | whether or not a magnitude is being measured
Value      | The actual numerical output from the measurement



### Summary of long-form data


```r
summary(Tidy)
```

```
##    SubjectID                   Activity            Domain      
##  Min.   : 1.00   LAYING            :128304   Frequency:267774  
##  1st Qu.: 9.00   SITTING           :117282   Time     :411960  
##  Median :17.00   STANDING          :125796                     
##  Mean   :16.15   WALKING           :113652                     
##  3rd Qu.:24.00   WALKING_DOWNSTAIRS: 92796                     
##  Max.   :30.00   WALKING_UPSTAIRS  :101904                     
##            Device       AccelerationComponent   Stat          Axis       
##  Accelerometer:411960   Body   :597342        mean:339867   X   :164784  
##  Gyroscope    :267774   Gravity: 82392        std :339867   Y   :164784  
##                                                             Z   :164784  
##                                                             NA's:185382  
##                                                                          
##                                                                          
##    Jerk            Magnitude          Value         
##  Jerk:267774   Magnitude:185382   Min.   :-1.00000  
##  NA's:411960   NA's     :494352   1st Qu.:-0.98122  
##                                   Median :-0.55219  
##                                   Mean   :-0.51134  
##                                   3rd Qu.:-0.09971  
##                                   Max.   : 1.00000
```

### Unique combinations of factors (except SubjectID) found in long-form data

```r
unique(VariableList[,4:10])
```

```
##       Domain        Device AccelerationComponent Stat Axis Jerk Magnitude
## 1       Time Accelerometer                  Body mean    X <NA>      <NA>
## 2       Time Accelerometer                  Body mean    Y <NA>      <NA>
## 3       Time Accelerometer                  Body mean    Z <NA>      <NA>
## 4       Time Accelerometer                  Body  std    X <NA>      <NA>
## 5       Time Accelerometer                  Body  std    Y <NA>      <NA>
## 6       Time Accelerometer                  Body  std    Z <NA>      <NA>
## 7       Time Accelerometer               Gravity mean    X <NA>      <NA>
## 8       Time Accelerometer               Gravity mean    Y <NA>      <NA>
## 9       Time Accelerometer               Gravity mean    Z <NA>      <NA>
## 10      Time Accelerometer               Gravity  std    X <NA>      <NA>
## 11      Time Accelerometer               Gravity  std    Y <NA>      <NA>
## 12      Time Accelerometer               Gravity  std    Z <NA>      <NA>
## 13      Time Accelerometer                  Body mean    X Jerk      <NA>
## 14      Time Accelerometer                  Body mean    Y Jerk      <NA>
## 15      Time Accelerometer                  Body mean    Z Jerk      <NA>
## 16      Time Accelerometer                  Body  std    X Jerk      <NA>
## 17      Time Accelerometer                  Body  std    Y Jerk      <NA>
## 18      Time Accelerometer                  Body  std    Z Jerk      <NA>
## 19      Time     Gyroscope                  Body mean    X <NA>      <NA>
## 20      Time     Gyroscope                  Body mean    Y <NA>      <NA>
## 21      Time     Gyroscope                  Body mean    Z <NA>      <NA>
## 22      Time     Gyroscope                  Body  std    X <NA>      <NA>
## 23      Time     Gyroscope                  Body  std    Y <NA>      <NA>
## 24      Time     Gyroscope                  Body  std    Z <NA>      <NA>
## 25      Time     Gyroscope                  Body mean    X Jerk      <NA>
## 26      Time     Gyroscope                  Body mean    Y Jerk      <NA>
## 27      Time     Gyroscope                  Body mean    Z Jerk      <NA>
## 28      Time     Gyroscope                  Body  std    X Jerk      <NA>
## 29      Time     Gyroscope                  Body  std    Y Jerk      <NA>
## 30      Time     Gyroscope                  Body  std    Z Jerk      <NA>
## 31      Time Accelerometer                  Body mean <NA> <NA> Magnitude
## 32      Time Accelerometer                  Body  std <NA> <NA> Magnitude
## 33      Time Accelerometer               Gravity mean <NA> <NA> Magnitude
## 34      Time Accelerometer               Gravity  std <NA> <NA> Magnitude
## 35      Time Accelerometer                  Body mean <NA> Jerk Magnitude
## 36      Time Accelerometer                  Body  std <NA> Jerk Magnitude
## 37      Time     Gyroscope                  Body mean <NA> <NA> Magnitude
## 38      Time     Gyroscope                  Body  std <NA> <NA> Magnitude
## 39      Time     Gyroscope                  Body mean <NA> Jerk Magnitude
## 40      Time     Gyroscope                  Body  std <NA> Jerk Magnitude
## 41 Frequency Accelerometer                  Body mean    X <NA>      <NA>
## 42 Frequency Accelerometer                  Body mean    Y <NA>      <NA>
## 43 Frequency Accelerometer                  Body mean    Z <NA>      <NA>
## 44 Frequency Accelerometer                  Body  std    X <NA>      <NA>
## 45 Frequency Accelerometer                  Body  std    Y <NA>      <NA>
## 46 Frequency Accelerometer                  Body  std    Z <NA>      <NA>
## 47 Frequency Accelerometer                  Body mean    X Jerk      <NA>
## 48 Frequency Accelerometer                  Body mean    Y Jerk      <NA>
## 49 Frequency Accelerometer                  Body mean    Z Jerk      <NA>
## 50 Frequency Accelerometer                  Body  std    X Jerk      <NA>
## 51 Frequency Accelerometer                  Body  std    Y Jerk      <NA>
## 52 Frequency Accelerometer                  Body  std    Z Jerk      <NA>
## 53 Frequency     Gyroscope                  Body mean    X <NA>      <NA>
## 54 Frequency     Gyroscope                  Body mean    Y <NA>      <NA>
## 55 Frequency     Gyroscope                  Body mean    Z <NA>      <NA>
## 56 Frequency     Gyroscope                  Body  std    X <NA>      <NA>
## 57 Frequency     Gyroscope                  Body  std    Y <NA>      <NA>
## 58 Frequency     Gyroscope                  Body  std    Z <NA>      <NA>
## 59 Frequency Accelerometer                  Body mean <NA> <NA> Magnitude
## 60 Frequency Accelerometer                  Body  std <NA> <NA> Magnitude
## 61 Frequency Accelerometer                  Body mean <NA> Jerk Magnitude
## 62 Frequency Accelerometer                  Body  std <NA> Jerk Magnitude
## 63 Frequency     Gyroscope                  Body mean <NA> <NA> Magnitude
## 64 Frequency     Gyroscope                  Body  std <NA> <NA> Magnitude
## 65 Frequency     Gyroscope                  Body mean <NA> Jerk Magnitude
## 66 Frequency     Gyroscope                  Body  std <NA> Jerk Magnitude
```

# Final transformation - calculating the means 

Finally, since the assignment says we must create _".. a second, independent tidy data set with the average of each variable for each activity and each subject.", the _group_by_ function (dplyr package) is used to split the long-form data by _Activity_, _featNum_, _Domain_, _Device_, _AccelerationComponent_, _Stat_, _Axis_, _Jerk_, _Magnitude_, and _subjectID_ (all factors).

A final data set, **_TidySummary_**, is produced by taking the mean and count of all variables with the _summarize_ function (dplyr package) 

```r
TidySummary<-summarise(meanVal=mean(Value,na.rm=TRUE),n=length(Value))
```

### Summary of TidySummary data

```r
summary(TidySummary)
```

```
##    SubjectID                   Activity         Domain    
##  Min.   : 1.00   LAYING            :396   Frequency: 910  
##  1st Qu.: 8.00   SITTING           :396   Time     :1400  
##  Median :15.00   STANDING          :396                   
##  Mean   :15.11   WALKING           :396                   
##  3rd Qu.:23.00   WALKING_DOWNSTAIRS:396                   
##  Max.   :30.00   WALKING_UPSTAIRS  :330                   
##            Device     AccelerationComponent   Stat        Axis    
##  Accelerometer:1400   Body   :2030          mean:1155   X   :560  
##  Gyroscope    : 910   Gravity: 280          std :1155   Y   :560  
##                                                         Z   :560  
##                                                         NA's:630  
##                                                                   
##                                                                   
##    Jerk          Magnitude       meanVal              n        
##  Jerk: 910   Magnitude: 630   Min.   :-0.9801   Min.   : 28.0  
##  NA's:1400   NA's     :1680   1st Qu.:-0.7197   1st Qu.:288.0  
##                               Median :-0.6122   Median :321.0  
##                               Mean   :-0.4953   Mean   :294.3  
##                               3rd Qu.:-0.3121   3rd Qu.:364.0  
##                               Max.   : 0.9522   Max.   :408.0
```



codebook generated by run_analysis.R

```r
Sys.time()
```

```
## [1] "2017-06-22 11:27:45 EDT"
```
