# GetData_Assignment
Project assignment for Getting and Cleaning Data

This README will describe the process used to tidy the data referred to in the associated Codebook.

The program run_analysis.R requires the additional R packages dplyr and tidyr.  It will load these two libraries at the start.

## Steps taken by the program (with the code)

### Load the additional libraries

```
library("dplyr", lib.loc="~/R/win-library/3.2")
library("tidyr", lib.loc="~/R/win-library/3.2")
```

### Step 0: Read in the data
Read in the data using the read.table command.  At the same time, wrap the data with a data frame table using the tbl_df command. 

The three files for the training data are in the subfolder *train* and are
- *y_train.txt*: the activity IDs for each observation of the training data.  The data is given the variable name *act_id*
- *subject_train.txt*: the subject ID for each observation of the training data.  The data is given the variable name *subject*
- *x_train.txt*: the observed data values.  Each row consists of 561 variables as described in the *feature_info.txt* file.

```
# Step 0: Read in all of the data

# Read in the training data set
train_labels <- tbl_df(read.table("./UCI HAR Dataset/train/y_train.txt",col.names="act_id"))   # train_labels first, naming the column "act_id"
train_subject <- tbl_df(read.table("./UCI HAR Dataset/train/subject_train.txt",col.names="subject"))   # train_subject next, naming the column "subject"
train_data <- tbl_df(read.table("./UCI HAR Dataset/train/x_train.txt"))   # finally, read in the train_data
```

Repeat the above for the three files of the test data that is held in the subfolder *test*.

```
# Repeat the process for the test data set
test_labels <- tbl_df(read.table("./UCI HAR Dataset/test/y_test.txt",col.names="act_id"))   # test_labels first, naming the column "act_id"
test_subject <- tbl_df(read.table("./UCI HAR Dataset/test/subject_test.txt",col.names="subject"))   # test_subject next, naming the column "subject"
test_data <- tbl_df(read.table("./UCI HAR Dataset/test/x_test.txt"))   # finally, read in the test_data
```

Read in the feature file as a factored list of text.  The raw feature list has two variables, an ID and the name.  As we only require the name, we can drop the feature ID.  The remaining variable is given the variable name *feature*.


```
# Read in the features naming the second columns "f_id" and "feature".  Then drop the ID column
features <- read.table("./UCI HAR Dataset/features.txt",sep=" ",col.names=c("f_id","feature"))
features <- features[,2]
```

The last input files contains the six activity IDs and names.  The two variables are given the names *act_id* and *activity.  

```
# Read in the activity labels, naming the columns "act_id" and "activity"
activity_labels <- read.table("./UCI HAR Dataset/activity_labels.txt",sep=" ",col.names=c("act_id","activity"))
```

### Step 1: Merge the training and test datasets
Create three new data frames for the activity labels (*combined_labels*), the subject IDs (*combined_subject*) and the observed data (*combined_data*) by using *rbind* to add the observations from the test data to the bottom off the training data.
```
# Step 1: merge the training and test data sets

# merge the different data set tables into combined tables
combined_labels <- rbind(train_labels,test_labels)     # activity IDs
combined_subject <- rbind(train_subject,test_subject)  # subject IDs
combined_data <- rbind(train_data,test_data)           # data
```

### Step 2: Extract the columns containing the means and standard deviations
The variables containing the means and standard deviations contain the strings "mean()" or "std()" respectively.  The *grep* command will give us the column numbers containing the required text.

Here *grep* is run twice on the features, once for each string; the two results are combined using *rbind* and then the list is *sort*ed with the result stored in *columns_required*

```

# Step 2: Extract the columns containing means and standard deviations

# get the column number that contain a mean or a standard deviation
columns_required <-
  rbind(grep("mean[(][)]",features),      # grep for "mean" in the feature name
        grep("std[(][)]",features)) %>%   # grep for "std" in the feature name
  sort                                    # and sort them into ascending order
```
This produces a list of 66 number (33 for the means and 33 for the SDs) which can be used to select the required variables from both the observed data and their feature names.
```

# use this list to extract the required columns from the data and the feature labels
selected_data <- combined_data[,columns_required]   # data
selected_features <- features[columns_required]     # features
```

### Step 3: Replace the activity IDs with their names
Use the *merge* command to combine the combined activity labels (*combined_labels*) and the activity names (*activity_labels*).  The *act_id* variable is used as the key to match the records.  As we only require the activity name, use the *select* command to ignore the IDs.
```

# Step 3: Replace the activity IDs with their names
combined_activity <- 
  merge(activity_labels,combined_labels, by="act_id") %>%  # merge the IDs with the names
  select(activity)                                         # select the names
```

### Step 4: Appropriately label the data set
Label the variables of the selected observed data with select feature names using the *colnames* command.  Then combine the activity names (*combined_activity*), subject ID (*combined_subject*) and selected data (*selected_data*) into a single data frame using the *cbind* command.  The activity and the subject will be the first two columns followed by the observations.

```

# Step 4: Appropriately label the data set

# Use the selected feature labels as the data variable names
colnames(selected_data) <- selected_features
# add the activity and subject tables as two extra variablesto the left of the data
full_data <-cbind(combined_activity,combined_subject,selected_data)
```

### Step 5: Create a tidy data set of the average for each variable for each activity and subject
The data consists of 10,299 observations with 68 variables.  To convert this into the form that we requires we must
- group the data by activity and subject using the *group_by* command
- for each activity/subject combination, calculate the mean of each of the 66 observations using the *summarise_each* command
- convert the 68 means per line into a list of 66 observation consisting of the activitym subject, feature and mean using the *gather* command
- sort the list by activity and then subject.
This will give a tidy dataset consisting of 2,310 observations with 4 variables.
```

# Step 5: Create a tidy data set of the average for each variable for each activity and subject
feature_means <-
  full_data %>%
  group_by(activity, subject) %>%                      # first group by activity and subject
  summarise_each(funs(mean)) %>%                       # now summarise each variable by calculating the mean
  gather(feature, mean, -c(activity,subject)) %>%      # rearrange the data to have one observation per line
  arrange(activity, subject)                           # finally sort the resulting table by activity and then subject
```

### Write out the data table
Finally write out the table in the required format unsng the *write.table* command.

```

# Finally, write out the variable means
write.table(feature_means,file="./UCI HAR Dataset/feature_means.txt",row.name=FALSE)
```

