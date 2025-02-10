### Backend ID Mapping table update

### Using Mock Metadata created for the purpose of writing this script, located in Melissa - Sandbox Project on Synapse
### Pull in Individual Metadata for the study you are adding new individuals for
metadata <- read.csv(synGet("syn64756927")$path) # Insert the synID of the Individual Metadata you will be using

### Format metadata to the Backend - ID Mapping table format
metadata$originalId <- metadata$individualId

metadata <- metadata %>%
  select(individualId, originalId, studyCode, project)

colnames(metadata) <- c("individualId", "originalId", "studyKey", "project")

metadata$individualId <- NA

### Install or load digest package for hashing
library(digest)

### Create a salted hash and use the first 10 alphanumeric characters
generate_random_id <- function(n, salt) {
  raw_hash <- digest(paste0(salt, Sys.time(), n), algo = "sha256")
  toupper(substr(gsub("[^A-Za-z0-9]", "", raw_hash), 1, 10))
}

salt <- "mockstudy_salt"  # Insert study key for the study you are adding IDs for
na_count <- sum(is.na(metadata$individualId)) 

### Generate random IDs and replace NAs
metadata$individualId[is.na(metadata$individualId)] <- sapply(1:na_count, generate_random_id, salt)

### Upload new IDs into Backend - ID Mapping table
synStore(Table("syn64287566", metadata))
