### Data Indexing - BioProject Example

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
bioproject_id <- "PRJNA788430"

# Synapse folder
parentId <- "syn66271578"

# Step 1: Use esearch to find linked SRA IDs
search_url <- paste0("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?",
                     "db=sra&term=", bioproject_id, "[BioProject]&retmax=10000")

search_resp <- GET(search_url)
search_content <- content(search_resp, as = "text")
search_xml <- read_xml(search_content)

# Step 2: Extract all IDs
ids <- xml_find_all(search_xml, ".//Id") %>% xml_text()
sra_links <- paste0("https://www.ncbi.nlm.nih.gov/sra/", ids) %>% unique()

# Step 3: Iterate through each link, grab title, and create link entity in Synapse
for (link in sra_links) {
  page <- try(read_html(link), silent = TRUE)
  
  if (inherits(page, "try-error")) {
    message("Skipping due to error reading: ", link)
    next
  }
  
  # Extract and clean title
  title <- page %>%
    html_nodes("title") %>%
    html_text(trim = TRUE)
  
  # Just grab the first match (in case somehow multiple titles get returned)
  title <- title[1]
  
  # Strip everything after the first dash (usually ends in " - SRA - NCBI" or similar)
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
  message("✅ Created entity:", title)
}
