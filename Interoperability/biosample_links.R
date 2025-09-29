# Load R libraries
library(httr)
library(rvest)
library(tidyverse)
library(stringr)
library(synapser)
library(xml2)

# Log in to Synapse
synLogin()

#############################################

# BioProject ID
bioproject_id <- "PRJNA___" # Insert BioProject ID

# Synapse folder
parentId <- "synID" # Insert parent folder SynID

# Step 1: First get the BioProject UID
bioproject_search_url <- paste0("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?",
                                "db=bioproject&term=", bioproject_id, "[PRJA]&retmax=1")
bioproject_resp <- GET(bioproject_search_url)
bioproject_content <- content(bioproject_resp, as = "text")
bioproject_xml <- read_xml(bioproject_content)
bioproject_uid <- xml_find_first(bioproject_xml, ".//Id") %>% xml_text()

message("BioProject UID: ", bioproject_uid)

# Step 2: Use elink to find linked BioSample IDs
elink_url <- paste0("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?",
                    "dbfrom=bioproject&db=biosample&id=", bioproject_uid)
elink_resp <- GET(elink_url)
elink_content <- content(elink_resp, as = "text")
elink_xml <- read_xml(elink_content)

# Step 3: Extract all linked BioSample IDs
ids <- xml_find_all(elink_xml, ".//Link/Id") %>% xml_text()
biosample_links <- paste0("https://www.ncbi.nlm.nih.gov/biosample/", ids) %>% unique()

message("Found ", length(biosample_links), " BioSample links")

# Step 4: Iterate through each link, grab title, and create link entity in Synapse
for (link in biosample_links) {
  page <- try(read_html(link), silent = TRUE)
  
  if (inherits(page, "try-error")) {
    message("Skipping due to error reading: ", link)
    next
  }
  
  # Extract and clean title
  title <- page %>%
    html_nodes("title") %>%
    html_text(trim = TRUE)
  
  # Just grab the first match
  title <- title[1]
  
  # Strip everything after the first dash (usually ends in " - BioSample - NCBI" or similar)
  title <- sub(" -.*$", "", title)
  
  # Clean up: replace colons and semicolons with space
  title <- gsub("[:;]", " ", title)
  
  # Remove invalid characters (but keep spaces, underscores, hyphens, periods, etc.)
  title <- gsub("[^A-Za-z0-9 _\\-\\.\\+\\'\\(\\)]", "", title)
  
  # Collapse multiple spaces and trim
  title <- gsub("\\s+", " ", title)
  title <- trimws(title)
  
  # Create external file
  entity <- File(
    path = link,
    parentId = parentId,
    name = title,
    synapseStore = FALSE
  )
  
  synStore(entity)
  message("✅ Created entity: ", title)
  
  # Small delay to be respectful to NCBI servers
  Sys.sleep(0.5)
}

message("✅ Completed processing ", length(biosample_links), " BioSample links")
