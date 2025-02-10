# Format metadata to the Backend - ID Mapping table format
metadata <- metadata[, c("individualID.y", "individualID.x", "studyCode.x", "studyCode.y")]
colnames(metadata) <- c("individualId", "originalId", "studyKey", "project")

#Install or load digest package for hashing
library(digest)

generate_random_id <- function(n, salt) {
  # Create a salted hash, then take the first 10 alphanumeric characters
  raw_hash <- digest(paste0(salt, Sys.time(), n), algo = "sha256")
  toupper(substr(gsub("[^A-Za-z0-9]", "", raw_hash), 1, 10))
}

salt <- "stuydkey_salt"  # Insert study key for the stuyd you are adding IDs for
na_count <- sum(is.na(metadata$individualID)) 

# Generate random IDs and replace NAs
updated_metadata$individualID[is.na(metadata$individualID)] <- sapply(1:na_count, generate_random_id, salt)

# Now, we format this table to match the backend - ID mapping table
metadata <- metadata[, c("individualID.y", "individualID.x", "studyCode.x", "studyCode.y")]
colnames(metadata) <- c("individualId", "originalId", "studyKey", "project")
updated_id_mapping <- metadata

# Time to add the new IDs to the backend table

synStore(Table("synID", metadata)

