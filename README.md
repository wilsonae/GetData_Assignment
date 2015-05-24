# GetData_Assignment Readme File


This README will describe the process used to tidy the data referred to in the associated [Codebook](GetData_Assignment/Codebook.rmd) for the Getting and Cleaning Data project assignment.

The associated program run_analysis.R requires the additional R packages *dplyr* and *tidyr*.  It will load these two libraries at execution.

## Process used by the program (with code snippets)

### Load the required additional libraries
```
library("dplyr", lib.loc="~/R/win-library/3.2")
library("tidyr", lib.loc="~/R/win-library/3.2")
```

### Step 0: Read in the data
Read in the data using the *read.table* command.  At the same time, wrap the data with a data frame table using the *tbl_df* command. 

The three files for the training data are in the subfolder *train* and are
- *y_train.txt*: the activity IDs for each observation of the training data.  The data is given the variable name *act_id*
- *subject_train.txt*: the subject ID for each observation of the training data.  The data is given the variable name *subject*
- *x_train.txt*: the observed data values.  Each row consists of 561 variables as described in the *feature_info.txt* file.
```
# Read in the training data set
train_labels <- tbl_df(read.table("./UCI HAR Dataset/train/y_train.txt",col.names="act_id"))   # train_labels first, naming the column "act_id"
train_subject <- tbl_df(read.table("./UCI HAR Dataset/train/subject_train.txt",col.names="subject"))   # train_subject next, naming the column "subject"
train_data <- tbl_df(read.table("./UCI HAR Dataset/train/x_train.txt"))   # finally, read in the train_data
```

Repeat the above by reading in the three files of the test data that is held in the subfolder *test*.
```
# Repeat the process for the test data set
test_labels <- tbl_df(read.table("./UCI HAR Dataset/test/y_test.txt",col.names="act_id"))   # test_labels first, naming the column "act_id"
test_subject <- tbl_df(read.table("./UCI HAR Dataset/test/subject_test.txt",col.names="subject"))   # test_subject next, naming the column "subject"
test_data <- tbl_df(read.table("./UCI HAR Dataset/test/x_test.txt"))   # finally, read in the test_data
```

Input the feature file as a factored list of text data.  The raw feature list has two variables, a feature ID and a feature name.  As we only require the feature name, we can subset the data to drop the ID.  The remaining variable is given the variable name *feature*.
```
# Read in the features naming the second columns "f_id" and "feature".  Then drop the ID column
features <- read.table("./UCI HAR Dataset/features.txt",sep=" ",col.names=c("f_id","feature"))
features <- features[,2]
```

The last input file contains the IDs and names for the six activities.  The two variables are given the names *act_id* and *activity*.  
```
# Read in the activity labels, naming the columns "act_id" and "activity"
activity_labels <- read.table("./UCI HAR Dataset/activity_labels.txt",sep=" ",col.names=c("act_id","activity"))
```

### Step 1: Merge the training and test datasets
Create three new data frames that contain the combined data using *rbind* to add the observations from the test data to the bottom off the training data.  The three combined tables are: for the activity labels (*combined_labels*); the subject IDs (*combined_subject*); and the observed data (*combined_data*).
```
# merge the different data set tables into combined tables
combined_labels <- rbind(train_labels,test_labels)     # activity IDs
combined_subject <- rbind(train_subject,test_subject)  # subject IDs
combined_data <- rbind(train_data,test_data)           # data
```

### Step 2: Extract the columns containing the means and standard deviations
The feature variables containing the means and standard deviations that we require will contain the strings **"mean()"** or **"std()"** respectively.  The *grep* command will give us the column numbers containing the required text.

Here *grep* is run twice on the features, once for each string; the two results are then combined using *rbind*, and finally, the list is sorted with the result stored in *columns_required* using the *sort* command.
```
# get the column numbers that contain a mean or a standard deviation
columns_required <-
  rbind(grep("mean[(][)]",features),      # grep for "mean" in the feature name
        grep("std[(][)]",features)) %>%   # grep for "std" in the feature name
  sort                                    # and sort them into ascending order
```
This produces a list of 66 number (33 for the means and 33 for the SDs) which can be used to select the required variables from both the observed data (*combined_data*) and their feature names (*combined_features*).
```
# use this list to extract the required columns from the data and the feature labels
selected_data <- combined_data[,columns_required]   # data
selected_features <- features[columns_required]     # features
```

### Step 3: Replace the activity IDs with their names
Using the *act_id* variable from each table as the key add the activity names (*activity_labels*) to the activity labels (*combined_labels*) using the *merge* command.  As we no longer require the activity name, use the *select* command to ignore the IDs.
```
combined_activity <- 
  merge(activity_labels,combined_labels, by="act_id") %>%  # merge the IDs with the names
  select(activity)                                         # select the names
```

### Step 4: Appropriately label the data set
Label the variables of the selected observed data with selected feature names using the *colnames* command.  Then combine the activity names (*combined_activity*), subject ID (*combined_subject*) and selected data (*selected_data*) into a single data frame using the *cbind* command.  The order of the variables in this data table is firstly **activity**, then **subject**, followed by the **feature variables**.
```
# Use the selected feature labels as the data variable names
colnames(selected_data) <- selected_features
# add the activity and subject tables as two extra variablesto the left of the data
full_data <-cbind(combined_activity,combined_subject,selected_data)
```

### Step 5: For each variable for each activity and subject, create a tidy data set of the average 
The data consists of 10,299 observations with 68 variables.  To convert this into the form that we require we must
- group the data by activity and subject using the *group_by* command
- for each activity/subject combination, calculate the mean for each of the 66 observations using the *summarise_each* command
- convert the 66 means per line into a list of 66 observation consisting of the activitym subject, feature and mean using the *gather* command
- sort the list by activity and then subject.
This will give a tidy dataset consisting of 2,310 observations with 4 variables.
```
feature_means <-
  full_data %>%
  group_by(activity, subject) %>%                      # first group by activity and subject
  summarise_each(funs(mean)) %>%                       # now summarise each variable by calculating the mean
  gather(feature, mean, -c(activity,subject)) %>%      # rearrange the data to have one observation per line
  arrange(activity, subject)                           # finally sort the resulting table by activity and then subject
```

### Write out the data table
Finally write out the table in the required format using the *write.table* command.
```
# Finally, write out the variable means
write.table(feature_means,file="./UCI HAR Dataset/feature_means.txt",row.name=FALSE)
```
Thsi file should be read into R using the *data.table* command.
