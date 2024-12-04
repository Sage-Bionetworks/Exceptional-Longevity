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

#######################################################################################################

# Here is an example adding more assay annotations at once when the variable type differs between the file view and metadata

# Query in file view
view_query <- synTableQuery("select * from synID") # Insert file view synID
view <- as.data.frame(view_query)

# Read in metadata
assay_metadata <- read.csv(synGet("synID")$path) # Insert assay metadata synID

# This example was for Whole Genome Sequencing assay metadata
view <- view %>%
  left_join(
    assay_metadata[, c(
      "specimenID", "sequencingBatchID", "aligned_reads", 
      "alignment_rate", "freemix", "haploid_coverage", 
      "mean_coverage", "pct_10x", "pct_20x"
    )],
    by = "specimenID"
  ) %>%
  mutate(
    sequencingBatchID = coalesce(as.character(sequencingBatchID.x), as.character(sequencingBatchID.y)),
    aligned_reads = coalesce(as.character(aligned_reads.x), as.character(aligned_reads.y)),
    alignment_rate = coalesce(as.character(alignment_rate.x), as.character(alignment_rate.y)),
    freemix = coalesce(as.character(freemix.x), as.character(freemix.y)),
    haploid_coverage = coalesce(as.character(haploid_coverage.x), as.character(haploid_coverage.y)),
    mean_coverage = coalesce(as.character(mean_coverage.x), as.character(mean_coverage.y)),
    pct_10x = coalesce(as.character(pct_10x.x), as.character(pct_10x.y)),
    pct_20x = coalesce(as.character(pct_20x.x), as.character(pct_20x.y))
  ) %>%
  select(-ends_with(".x"), -ends_with(".y"))

# Upload table back into the file view with new, specimen-specific, assay metadata for annotations
synStore(Table("synID", view)) # Insert file view synID
