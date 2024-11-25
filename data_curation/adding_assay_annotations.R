### This script provides an example on how to add assay metadata that are specimen-specific as annotations

# Querying in the file view with the following empty columns: entityID, specimenID, sampleType
annotation_query = synTableQuery("select * from synID") # Insert synID of filew view you would like to use to add annotations, query in the file view
annotation_view = as.data.frame(annotation_query) # Open the file view query as a data frame

# Because the entityID in the metadata is the same as the "id" column in the file view, I will fill the entityID col with the id values
# This will make the join process easier for the rest of the columns
annotation_view$entityId <- annotation_view$id

# Now that the entity IDs have been filled out, I want to match the metadata values for those entityIDs to their corresponding columns (specimenID & sampleType) in the file view
# This will be done via a left join matching on entityID
annotation_view <- annotation_view %>%
  left_join(metadata[, c("entityId", "specimenID", "sampleType")], by = "entityId") %>%        # Performing a left join of the file view with the metadata file
  mutate(
    specimenID = coalesce(specimenID.x, specimenID.y),
    sampleType = coalesce(sampleType.x, sampleType.y)
  ) %>%
  select(-specimenID.x, -specimenID.y, -sampleType.x, -sampleType.y)

# After the columns are filled and the table metadata have been added, upload the table into synapse, adding the annotations to the files in the file view
synStore(Table("synID", annotation_view))
