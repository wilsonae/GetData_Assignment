library("dplyr", lib.loc="~/R/win-library/3.2")
library("tidyr", lib.loc="~/R/win-library/3.2")

# Step 0: Read in all of the data

# Read in the training data set
train_labels <- tbl_df(read.table("UCI HAR Dataset/train/y_train.txt",col.names="act_id"))   # train_labels first, naming the column "act_id"
train_subject <- tbl_df(read.table("UCI HAR Dataset/train/subject_train.txt",col.names="subject"))   # train_subject next, naming the column "subject"
train_data <- tbl_df(read.table("UCI HAR Dataset/train/x_train.txt"))   # finally, read in the train_data

# Repeat the process for the test data set
test_labels <- tbl_df(read.table("UCI HAR Dataset/test/y_test.txt",col.names="act_id"))   # test_labels first, naming the column "act_id"
test_subject <- tbl_df(read.table("UCI HAR Dataset/test/subject_test.txt",col.names="subject"))   # test_subject next, naming the column "subject"
test_data <- tbl_df(read.table("UCI HAR Dataset/test/x_test.txt"))   # finally, read in the test_data

# Read in the features naming the second columns "f_id" and "feature".  Then drop the ID column
features <- read.table("UCI HAR Dataset/features.txt",sep=" ",col.names=c("f_id","feature"))
features <- features[,2]

# Read in the activity labels, naming the columns "act_id" and "activity"
activity_labels <- read.table("UCI HAR Dataset/activity_labels.txt",sep=" ",col.names=c("act_id","activity"))


# Step 1: merge the training and test data sets

# merge the different data set tables into combined tables
combined_labels <- rbind(train_labels,test_labels)     # activity IDs
combined_subject <- rbind(train_subject,test_subject)  # subject IDs
combined_data <- rbind(train_data,test_data)           # data

# Step 2: Extract the columns containing means and standard deviations

# get the column number that contain a mean or a standard deviation
columns_required <-
  rbind(grep("mean[(][)]",features),      # grep for "mean" in the feature name
        grep("std[(][)]",features)) %>%   # grep for "std" in the feature name
  sort                                    # and sort them into ascending order

# use this list to extract the required columns from the data and the feature labels
selected_data <- combined_data[,columns_required]   # data
selected_features <- features[columns_required]     # features

# Step 3: Replace the activity IDs with their names
combined_activity <- 
  merge(activity_labels,combined_labels, by="act_id") %>%  # merge the IDs with the names
  select(activity)                                         # select the names

# Step 4: Appropriately label the data set

# Use the selected feature labels as the data  variable names
colnames(selected_data) <- selected_features
# add the activity and subject tables as two extra variablesto the left of the data
full_data <-cbind(combined_activity,combined_subject,selected_data)

# Step 5: Create a tidy data set of the average for each variable for each activity and subject
feature_means <-
  full_data %>%
  group_by(activity, subject) %>%                      # first group by activity and subject
  summarise_each(funs(mean)) %>%                       # now summarise each variable by calculating the mean
  gather(feature, mean, -c(activity,subject)) %>%      # rearrange the data to have one observation per line
  arrange(activity, subject)                           # finally sort the resulting table by activity and then subject

# Finally, write out the variable means
write.table(feature_means,file="feature_means.txt",row.name=FALSE)
