### This script can be used to add annotations to files that would be the same for every file in a data release (ELITE annotations)

annotation_query = synTableQuery("select * from synID") # Insert synID of filew view you would like to use to add annotations, query in the file view
annotation_view = as.data.frame(annotation_query) # Open the file view query as a data frame

view$annotation <- "Test Annotation" # Fill in the column(s) of the data frame with the annotations you would like to add to the files in the file view
view$annotation2 <- "Test Annotation  2"

synStore(Table("synID", annotation_view)) # After the columns are filled and the table metadata have been added, upload the table into synapse, adding the annotations to the files in the file view
