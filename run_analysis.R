require(knitr) 
require(rmarkdown)
require(data.table)
require(reshape2)
require(plyr)

#' ###Setting working directory - to current wd for the user
#' ###Setting the working path for data - a new folder under the working dir
path <- getwd()
setwd(path)
filename <- "getdata-projectfiles-UCI HAR Dataset.zip"
fulldatapath <- paste(path, "/getdata-projectfiles-UCI HAR Dataset.zip", sep='')

#' #This code performs the following tasks to create a tidy data set:

#   1. Merges the training and the test sets to create one data set.
#   2. Extracts only the measurements on the mean and standard deviation for each measurement. 
#   3. Uses descriptive activity names to name the activities in the data set
#   4. Appropriately labels the data set with descriptive variable names. 
#   5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

#'***

# Step 1
# Merges the training and the test sets to create one data set

  #Downloads the data from the .zip file and extracts it into a folder ./data
  #if the path already exists it will not redownload the files
  url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
  
  #Step 1.1 - if path for data doesnt exist - create it
  if (!file.exists(path)) {dir.create(path) 
                                print("Created new path/directory for data")}
  
  #step 1.2 - if the data file doesnt exist - then move on to downloading
  if (file.exists(fulldatapath))
  {
      #step 1.2.1 - if the file is current dont re-download.  
      #this could be variable to N number of days old but its defaulted to 0
      if (as.numeric(as.Date(Sys.Date(),"%d%b%Y", tz=Sys.timezone()) - as.Date(file.mtime(fulldatapath),"%d%b%Y", tz=Sys.timezone())) == 0)
      {
          print("File was current as of today, not downloading another copy")
      } else {
          download.file(url, destfile=filename)
      } #close else
  } else {download.file(url, destfile=filename) }

  #Unzip the files - place them in memory
  
  Test_data <- read.table(unz(filename, "UCI HAR Dataset/test/X_test.txt"))
  Train_data <- read.table(unz(filename, "UCI HAR Dataset/train/X_train.txt"))
  features <- read.table(unz(filename, "UCI HAR Dataset/features.txt"))
  activity_labels <- read.table(unz(filename, "UCI HAR Dataset/activity_labels.txt"))
  Test_labels <- read.table(unz(filename, "UCI HAR Dataset/test/y_test.txt"))
  Train_labels <- read.table(unz(filename, "UCI HAR Dataset/train/y_train.txt"))
  Test_subject <- read.table(unz(filename, "UCI HAR Dataset/test/subject_test.txt"))
  Train_subject <- read.table(unz(filename, "UCI HAR Dataset/train/subject_train.txt"))

# Step 2
# Extracts only the measurements on the mean and standard deviation for each measurement  
  
  #grep (find) the rows with the mean and standard deviation (std)
  meanList <- c(grep("mean()",features$V2, fixed = TRUE))
  stdList <- c(grep("std()",features$V2, fixed = TRUE))

# Step 4
#Appropriately labels the data set with descriptive variable names  
  
  #subset the columns for mean()
  #Add Descriptive column names from features.txt
  tempMEAN_test <- Test_data[meanList]
  colnames(tempMEAN_test) <- features$V2[meanList]
  tempMEAN_train <- Train_data[meanList]
  colnames(tempMEAN_train) <- features$V2[meanList]
          
  #subset the columns for std()
  stdList <- c(grep("std()",features$V2, fixed = TRUE))
  tempSTD_test <- Test_data[stdList]
  colnames(tempSTD_test) <- features$V2[stdList]
  tempSTD_train <- Train_data[meanList]
  colnames(tempSTD_train) <- features$V2[stdList]
  
  #add the subject column
  tempSTD_test$subject <- Test_subject$V1
  tempSTD_train$subject <- Train_subject$V1

# Step 3
# Uses descriptive activity names to name the activities in the data set  
    
  #add the activity column (descriptive)
  #joins the labels to the text version of the name
  Test_labels <- join(Test_labels, activity_labels, type = "inner")
  Train_labels <- join(Train_labels, activity_labels, type = "inner")
  tempSTD_test$activity <- Test_labels$V2
  tempSTD_train$activity <- Train_labels$V2

  #Merge the training and test sets
  dataMEAN <- rbind(tempMEAN_test,tempMEAN_train)
  dataSTD <- rbind(tempSTD_test,tempSTD_train)
  data <- cbind(dataMEAN,dataSTD)
  
  #cleanup the workspace memory
  rmLIST_files <- c("Test_data", "Train_data",  "Test_labels","Train_labels","activity_labels","Test_subject","Train_subject", "features")
  rmLIST_variables <- c("dataMEAN", "dataSTD", "meanList","tempMEAN_test","tempMEAN_train", "tempSTD_test","tempSTD_train")
  rm(list = rmLIST_files)
  rm(list = rmLIST_variables)

  #creates the output file with the mean and std columns along with the subject ID and descriptive activity name
  write.table(data, file = "tidyDataSet_raw.txt", sep = "," ,row.names = FALSE)

# Step 5
#From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject

  aggData <- aggregate(data, by=list(data$subject, data$activity), FUN = "mean", na.rm=TRUE)
  aggData <- subset( aggData, select = -subject )
  aggData <- subset( aggData, select = -activity )
  names(aggData)[1]<-"subject"
  names(aggData)[2]<-"activity"

  write.table(aggData, file = "tidyDataSet_Mean_by_Subject_and_activity.txt", sep = "," ,row.names = FALSE)
  
