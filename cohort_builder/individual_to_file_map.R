# Below are the steps to add files to the individualToFileMap table in the backend cohort builder project.

# In this scenario, we are working with data that are split by Cohort/Consent Group. (Multiple folders are being released)
# If the data you are releasing are coming from one folder, you would only do the first step and remove the bind step.

# It is IMPORTANT to note that these files need to have already been annotated with the Sage-generated IDs from ID mapping.

#########################################################################################


### Cohort 1

files_in_usgen_folder <- as.list(synGetChildren("synID", includeTypes = list("file"))) # Insert cohort 1 folder synID

file_annotation_list <- data.frame(synID = character(), individualId = character(), stringsAsFactors = FALSE)

for (file in files_in_usgen_folder) {
  annotations <- synGetAnnotations(file$id)
  
  if (!is.null(annotations$individualId)) {
    file_annotation_list <- rbind(file_annotation_list, 
                                  data.frame(synID = file$id, individualId = annotations$individualId))
  } else {
    # If no individualID annotation exists, add NA
    file_annotation_list <- rbind(file_annotation_list, 
                                  data.frame(synID = file$id, individualId = NA))
  }
}

### Cohort 2

files_in_usnp_folder <- as.list(synGetChildren("synID", includeTypes = list("file"))) # Insert cohort 2 folder synID

file_annotation_list_2 <- data.frame(synID = character(), individualId = character(), stringsAsFactors = FALSE)

for (file in files_in_usnp_folder) {
  annotations <- synGetAnnotations(file$id)
  
  if (!is.null(annotations$individualId)) {
    file_annotation_list_2 <- rbind(file_annotation_list_2, 
                                    data.frame(synID = file$id, individualId = annotations$individualId))
  } else {
    # If no individualID annotation exists, add NA
    file_annotation_list_2 <- rbind(file_annotation_list_2, 
                                    data.frame(synID = file$id, individualId = NA))
  }
}

### Cohort 3

files_in_dk_folder <- as.list(synGetChildren("synID", includeTypes = list("file"))) # Insert cohort 3 folder synID

file_annotation_list_3 <- data.frame(synID = character(), individualId = character(), stringsAsFactors = FALSE)

for (file in files_in_dk_folder) {
  annotations <- synGetAnnotations(file$id)
  
  if (!is.null(annotations$individualId)) {
    file_annotation_list_3 <- rbind(file_annotation_list_3, 
                                    data.frame(synID = file$id, individualId = annotations$individualId))
  } else {
    # If no individualID annotation exists, add NA
    file_annotation_list_3 <- rbind(file_annotation_list_3, 
                                    data.frame(synID = file$id, individualId = NA))
  }
}

### Cohort 4


files_in_uslong_folder <- as.list(synGetChildren("synID", includeTypes = list("file"))) # Insert cohort 4 folder synID

file_annotation_list_4 <- data.frame(synID = character(), individualId = character(), stringsAsFactors = FALSE)

for (file in files_in_uslong_folder) {
  annotations <- synGetAnnotations(file$id)
  
  if (!is.null(annotations$individualId)) {
    file_annotation_list_4 <- rbind(file_annotation_list_4, 
                                    data.frame(synID = file$id, individualId = annotations$individualId))
  } else {
    # If no individualID annotation exists, add NA
    file_annotation_list_4 <- rbind(file_annotation_list_4, 
                                    data.frame(synID = file$id, individualId = NA))
  }
}

filemap <- rbind(file_annotation_list, file_annotation_list_2, file_annotation_list_3, file_annotation_list_4)

filemap <- filemap %>%
  rename(id = synID)

synStore(Table("syn51426533", filemap)) # This is the synID for the individualToFileMap table

#########################################################################################

# If you are only uploading data from one folder, here is how that would look

files <- as.list(synGetChildren("synID", includeTypes = list("file"))) # Insert synID of folder being released

file_annotation_list <- data.frame(synID = character(), individualId = character(), stringsAsFactors = FALSE)

for (file in files) {
  annotations <- synGetAnnotations(file$id)
  
  if (!is.null(annotations$individualId)) {
    file_annotation_list <- rbind(file_annotation_list, 
                                    data.frame(synID = file$id, individualId = annotations$individualId))
  } else {
    # If no individualID annotation exists, add NA
    file_annotation_list <- rbind(file_annotation_list, 
                                    data.frame(synID = file$id, individualId = NA))
  }
}

files <- files %>%
  rename(id = synID)

synStore(Table("syn51426533", files))
