### This script can be used for moving files from a Staging folder to a Released folder 
### Example: Staging and released folders split into cohorts, but the ARs live on the released folder.
### Rather than moving the staging folder within the released folder, you programmatically move the files within the folder.

# Name the source and destination folder
source_folder <- "synID" # Staging synID
destination_folder <- "synID" # Released synID

children <- as.list(synGetChildren(source_folder))

for (child in children) {
  entity <- synGet(child$id, downloadFile = FALSE)
  entity$parentId <- destination_folder
  synStore(entity)
}
