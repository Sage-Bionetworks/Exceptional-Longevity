# Load libraries
library(httr)
library(rvest)
library(tidyverse)
library(synapser)

# Login to Synapse
synLogin()

# dbGaP study ID
study_id <- "phs.ID.p1" # Insert dbGaP study ID
parentId <- "synID"  # Insert ID of Synapse datasets or documents folder

# Step 1: Build the datasets page URL
dbgap_url <- paste0(
  "https", # Insert link of page that provides all datasets or all documents
  "study_id=", study_id, "&object_type=dataset" # Or document
)

# Step 2: Scrape the table of datasets or documents
page <- read_html(dbgap_url)

dataset_table <- page %>%
  html_node("table") %>%
  html_table(fill = TRUE)

# Step 3: Extract dataset links & titles
dataset_links <- page %>%
  html_nodes("table a") %>%
  html_attr("href") %>%
  url_absolute("https://www.ncbi.nlm.nih.gov") %>%
  unique()

dataset_titles <- page %>%
  html_nodes("table a") %>%
  html_text(trim = TRUE)

# Step 4: Loop through datasets (or documents) & create Synapse link entities
for (i in seq_along(dataset_links)) {
  title <- dataset_titles[i]
  link  <- dataset_links[i]
  
  # Clean up title
  title <- gsub("[:;]", " ", title)
  title <- gsub("[^A-Za-z0-9 _\\-\\.\\+\\'\\(\\)]", "", title)
  title <- gsub("\\s+", " ", title)
  title <- trimws(title)
  
  entity <- File(
    path = link,
    parentId = parentId,
    name = title,
    synapseStore = FALSE
  )
  
  synStore(entity)
  message("✅ Created entity: ", title)
}
