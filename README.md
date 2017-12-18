# Getting and Cleaning Data - course project

> The purpose of this project is to demonstrate your ability to collect, work with, and clean a data set. The goal is to prepare tidy data that can be used for later analysis. You will be graded by your peers on a series of yes/no questions related to the project. You will be required to submit: 1) a tidy data set as described below, 2) a link to a Github repository with your script for performing the analysis, and 3) a code book that describes the variables, the data, and any transformations or work that you performed to clean up the data called CodeBook.md. You should also include a README.md in the repo with your scripts. This repo explains how all of the scripts work and how they are connected.  
> 
> One of the most exciting areas in all of data science right now is wearable computing - see for example this article . Companies like Fitbit, Nike, and Jawbone Up are racing to develop the most advanced algorithms to attract new users. The data linked to from the course website represent data collected from the accelerometers from the Samsung Galaxy S smartphone. A full description is available at the site where the data was obtained: 
> 
> http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones 
> 
> Here are the data for the project: 
> 
> https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip 
> 
> You should create one R script called run_analysis.R that does the following. 
> 
> 1. Merges the training and the test sets to create one data set.
> 2. Extracts only the measurements on the mean and standard deviation for each measurement.
> 3. Uses descriptive activity names to name the activities in the data set.
> 4. Appropriately labels the data set with descriptive activity names.
> 5. Creates a second, independent tidy data set with the average of each variable for each activity and each subject. 
> 
> Good luck!

# How to run
The following packages must be installed 
 - stringr
 - tidyr
 - qdap
 - dplyr
 - knitr
 - markdown 
 
The code in Run_analysis.R must be modified slightly to reproduce the results of this project.
 - Change the location of _folderloc_ to their own local project directory
 - Once the zip file is downlaoded, manually extract the files to
folderloc/data/UCI HAR Dataset

# Basic overview of functionality 
#### Downloaded data
The data come in seperate files: the _test_ and _training_ data for _subjects_, _activities_, and phone _measurements_.  Each row of these data correspons to a single _person_ x _activity_, with hundreds of _measurements_ taken on each.   

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

The initial wide-format data is put together by vertically stacking the training and test data sets, then horizontally merging the subject, activity, and (filtered) measurements matrix.  The activities values are replaced with meaningful values using the crosswalk.

#### Transformed data
The _gather_ function (dplyr package) is used to transform the data into long form so that there is one row for every _subject_ x _activity_ x _measurement_. A single _value_ column holds the values that were previously listed under each measurement heading.  The features (now oriented vertically) are pulled apart with the _str_match_ function (stringr package) to produce seven seperate variables:

 - **Domain** - whether "time" or "frequency"
 - **Device** - whether measured with "Accelerometer" or "Gyroscope"
 - **AccelerationComponent** - whether acceleration is for "Body" or "Gravity"
 - **Stat**- whether value represents a mean or standard deviation
 - **Axis**- X, Y, or Z (or null)
 - **Jerk**- whether or not a "Jerk" was being measured
 - **Magnitude**- whether or not a "Magnitude" was being measured

Finally, since the assignment is to calculate seperate means for each variable, the _group_by_ function (dplyr package) is used to split the long-form data by _Activity_, _featNum_, _Domain_, _Device_, _AccelerationComponent_, _Stat_, _Axis_, _Jerk_, _Magnitude_, and _subjectID_.

A final data set, **_TidySummary_**, is produced by taking the mean and count of all variables with the _summarize_ function (dplyr package) 
```sh
TidySummary<-summarise(meanVal=mean(Value,na.rm=TRUE),n=length(Value))
```
This data frame is written to **output_TidySummary.txt** with the _write.table_ function.

# Design discussions 

#### Is the result really "tidy?"
We've got "tidy" data if the format makes statistical analyses as frictionless as possible.  The basic rule is that there should be one row per experimental unit, one column per variable.  The variables we use in our analyses should not be split across columns (i.e. one column for males, and one column for females), but should be in long form (i.e. one column called "gender" with values Male or Female) instead.  

But creating a tidy data set is not an exact science - it really depends on what you want to do with the data.  For instance, a project to assess the median household income is not the same as a project to assess the percent of individuals who are unemployed.  The experimental units are households and humans, respectively, and each would need its own (different) tidy data set.  It is therefore pretty important to know what question the analysis is supposed to answer in order to know whether you have the best data set for the job.

A clear goal was not given for the analysis in this project.  I'm not enough of a content expert to guess what a reasonable goal might be.  I could have spent more hours learning about phone data science, but I didn't think this was a good use of time.  Would it have been a good idea to have one column for X, one for Y, and one for Z?  Should the mean and std be in seperate columns?  The documentation in the assignment isn't sufficient to say.  

So just to be on the safe side, I made this data set as long as I could get it.  Every possible attribute was made into a column! 

