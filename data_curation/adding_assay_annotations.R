### This script provides an example on how to add assay metadata that are specimen-specific as annotations

# Querying in the file view with the following empty columns: entityID, specimenID, sampleType
view_id <- "synID" ## Insert file view synID
view <- synTableQuery(paste0("SELECT * FROM ", view_id))$asDataFrame()

# Because the entityID in the metadata is the same as the "id" column in the file view, I will fill the entityID col with the id values
# This will make the join process easier for the rest of the columns
view$entityId <- view$id

# Now that the entity IDs have been filled out, I want to match the metadata values for those entityIDs to their corresponding columns (specimenID & sampleType) in the file view
# This will be done via a left join matching on entityID

view <- view %>%
  left_join(metadata[, c("entityId", "specimenID", "sampleType")], by = "entityId") %>%        # Performing a left join of the file view with the metadata file
  mutate(
    specimenID = coalesce(specimenID.x, specimenID.y),
    sampleType = coalesce(sampleType.x, sampleType.y)
  ) %>%
  select(-specimenID.x, -specimenID.y, -sampleType.x, -sampleType.y)

# Now that all of the columns are filled with the metadata I wanted to add, I am going to add the file view metadata back to the data frame for upload
view$ROW_ID <- substr(view[[1]], 4, 11)
view$ROW_VERSION <- "1"

# Now uploading back into Synapse
synStore(Table(view_id, view)) # This upload took about 7 minutes
