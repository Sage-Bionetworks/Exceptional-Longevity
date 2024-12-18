### This is the script that was used for the first go at updating Cohort Builder's driving tables for a data release 

### TO BE SOLIDIFIED AND ADDED TO SOPs

#####################################################################################################################

# Install and open synapser, log in to Synapse using Synapse PAT

# Read metadata CSV from Synapse
metadata <- read.csv(synGet("synID")$path) # Insert synID

# Read Backend - ID Mapping table from Synapse to determine whether new Sage IDs need to be created for participants
id_mapping <- synTableQuery("SELECT * FROM synID WHERE studyKey = 'STUDYKEY'") # Insert synID and study key
id_mapping_df <- as.data.frame(id_mapping)

# Replace the individualIDs in the metadata with the Sage individualIDs that already exist
id_lookup <- setNames(id_mapping_df$individualId, id_mapping_df$originalId)
metadata$individualID <- id_lookup[metadata$individualID]
updated_metadata <- metadata %>%
  mutate(individualID = recode(individualID, !!!setNames(id_mapping_df$individualId, id_mapping_df$originalId)))

# There are individuals in the metadata that do not have pre-existing Sage-generated IDs, so we need to create those using salted hash. 

#Install/load digest package for hashing
library(digest)

generate_random_id <- function(n, salt) {
  # Create a salted hash, then take the first 10 alphanumeric characters
  raw_hash <- digest(paste0(salt, Sys.time(), n), algo = "sha256")
  toupper(substr(gsub("[^A-Za-z0-9]", "", raw_hash), 1, 10))
}

salt <- "studykey_salt"  # Salt value used for this instance, different salts can be used for different studies
na_count <- sum(is.na(metadata$individualID)) 

# Generate random IDs and replace NAs
updated_metadata$individualID[is.na(metadata$individualID)] <- sapply(1:na_count, generate_random_id, salt)

# Before moving forward, double check for duplicates in the individualID column
duplicate_ids <- updated_metadata$individualID[duplicated(updated_metadata$individualID)]

# If there are duplicates, this will show them
if (length(duplicate_ids) > 0) {
  print("Duplicate IDs found:")
  print(duplicate_ids)
} else {
  print("No duplicate IDs found.")
}

# Now that the study IDs have been replaced with the Sage-generated IDs and there are no duplicates, we can format the updated metadata file to the IndividualMetadata template.

# Select the columns needed for the individual metadata manifest
individual_metadata <- updated_metadata %>%
  select(individualID, age, sex, studyCode, diagnosis)

# Duplicate the age column to create two new columns in order to bin the ages over 90 (90-94, 95-99, 100+)

# Add new min age and max age column duplicating the original age column
individual_metadata$minAge <- individual_metadata$age
individual_metadata$maxAge <- individual_metadata$age

# Apply the binning for ages 90 and up
individual_metadata$age <- as.numeric(individual_metadata$age)

library(dplyr)

individual_metadata <- individual_metadata %>%
  mutate(
    minAge = case_when(
      age >= 90 & age <= 94 ~ 90,
      age >= 95 & age <= 99 ~ 95,
      age >= 100 ~ 100,
      TRUE ~ age
    ),
    maxAge = case_when(
      age >= 90 & age <= 94 ~ 94,
      age >= 95 & age <= 99 ~ 99,
      age >= 100 ~ 100,
      TRUE ~ age
    )
  )

# Finish formatting to match to the individual metadata template

colnames(individual_metadata) <- c("individualId", "age", "Sex", "studyKey", "Diagnosis", "minAge", "maxAge")

individual_metadata <- individual_metadata[, c("studyKey", "individualId", "minAge", "maxAge", "Sex", "Diagnosis")]

# We need to update multiple backend tables in the Cohort Builder project on Synapse. 
# Before we update Backend - Individuals, we should update Backend - ID mapping

# First, we need a table that contains both the original ID and the new Sage ID
combined_metadata <- merge(originalmetadata, updated_metadata, by = "Id", all = TRUE)

# Now, we format this table to match the backend - ID mapping table
combined_metadata <- combined_metadata[, c("individualID.y", "individualID.x", "studyCode.x", "studyCode.y")]
colnames(combined_metadata) <- c("individualId", "originalId", "studyKey", "project")
updated_id_mapping <- combined_metadata

# Time to add the new IDs to the backend table!

# Pull in Backend-ID-mapping from Synapse
idmapping_table_id <- "synID" # Insert backend ID mapping synID
idmapping_table <- synTableQuery(paste("SELECT * FROM", idmapping_table_id))
idmapping_df <- as.data.frame(idmapping_table)

# Compare updated id mapping table that we have been working on to determine which new data is to be added to the Synapse table
new_idmapping_data <- updated_id_mapping[!updated_id_mapping$individualId %in% idmapping_df$individualId, ]
# The number of new data observations should be the same as the NA count from earlier

# Upload new data to Synapse table
if (nrow(new_idmapping_data) > 0) {
  new_idmapping_table <- Table(idmapping_table_id, new_idmapping_data)
  synStore(new_idmapping_table)
} else {
  print("No new data to upload.")
}

# Let's do the same thing for the Backend - individuals Synapse table!
individuals_table_id <- "synID" # Insert the backend individuals synID
individuals_table <- synTableQuery(paste("SELECT * FROM", individuals_table_id))
individuals_df <- as.data.frame(individuals_table)

new_individuals_data <- individual_metadata[!individual_metadata$individualId %in% individuals_df$individualId, ]

if (nrow(new_individuals_data) > 0) {
  new_individuals_table <- Table(individuals_table_id, new_individuals_data)
  synStore(new_individuals_table)
} else {
  print("No new data to upload.")
}

# Once the tables are updated, you need to take a snapshot of the new data creating a new version for this release. The version number is to be added to the defining SQL for the backend filemaptoindividual Materialized View.

# Now that the Backend - ID-mapping table and the Backend - individuals tables have been updated, we need to update the individualToFileMap table

# In summary we need to: 
# Pull in files for newly released data and their individual ID annotation.
# Utilize the ID mapping table to switch the original ID to the Sage Individual ID
# Upload all files and their corresponding Sage IDs to the individual to file map table

# For some instances, you may be dealing with multiple cohorts or multiple studies at a time. In that case, run the below code for each cohort and study and then combine.

files_in_study_folder <- as.list(synGetChildren("synID", includeTypes = list("file"))) # Insert synID for study or cohort folder

file_annotation_list <- data.frame(synID = character(), individualID = character(), stringsAsFactors = FALSE)

for (file in files_in_study_folder) {
  annotations <- synGetAnnotations(file$id)
  
  if (!is.null(annotations$individualID)) {
    file_annotation_list <- rbind(file_annotation_list, 
                                  data.frame(synID = file$id, individualID = annotations$individualID))
  } else {
    # If no individualID annotation exists, add NA
    file_annotation_list <- rbind(file_annotation_list, 
                                  data.frame(synID = file$id, individualID = NA))
  }
}


# The below code would be used if you had multiple cohorts to combine

filemap <- rbind(file_annotation_list, file_annotation_list_2, file_annotation_list_3, file_annotation_list_4)

# The next step now is to replace those original IDs with the Individual IDs we created earlier

filemap <- filemap %>%
  left_join(updated_id_mapping[, c("originalId", "individualId")], 
            by = c("individualID" = "originalId")) %>%
  group_by(synID, individualID) %>%
  slice(1) %>%
  ungroup() 

# Formatting to match the individualToFileMap table in Synapse

filemap <- filemap %>%
  select(-individualID) %>%
  rename(id = synID)

# Add this file to the current backend table

individualtofilemap <- synTableQuery("SELECT * FROM synID") # Insert synID for the individualToFileMap backend table
# Add WHERE statement to add in studyKey to ensure that duplicate IDs for different studies are not included
individualtofilemap_df <- as.data.frame(individualtofilemap)

updated_individualtofilemap <- bind_rows(individualtofilemap_df, filemap)

synStore(Table("synID", updated_individualtofilemap)) # Insert synID for the individualToFileMap backend table
