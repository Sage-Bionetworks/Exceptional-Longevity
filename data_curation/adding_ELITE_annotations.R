### This script can be used to add annotations to files that would be the same for every file in a data release (ELITE annotations)

view_id <- "synID" # Insert synID of filew view you would like to use to add annotations

# Query in file view as a data frame
view <- synTableQuery(paste0("SELECT * FROM ", view_id))$asDataFrame()

# Fill the columns of the data frame with the annotations that you would like to add to all of the files
view$testAnnotation1 <- "test"
view$testAnnotation2 <- "testing"

# Once the data frame is ready to upload back into Synapse, you need to add the ROW_ID and ROW_VERSION columns (table metadata)

# The ROW_ID column should be only the numbers of the synID (Pulling in the 4th and 11th character from the first column)
view$ROW_ID <- substr(view[[1]], 4, 11)

# The ROW_VERSION should just be 1 unless the view has been versioned 
view$ROW_VERSION <- "1"

# After the columns are filled and the table metadata have been added, upload the table into synapse, adding the annotations to the files in the file view
synStore(Table(view_id, view))
