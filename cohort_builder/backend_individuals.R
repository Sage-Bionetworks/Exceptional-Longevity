### Backend Individuals table update

### Pull in fresh metadata
metadata <- read.csv(synGet("syn64756955")$path) # This example is utilizing mock metadata from a sandbox project, insert the individual metadata synID you will be using here

metadata <- metadata %>%
  select(individualId, age, sex, studyCode, diagnosis)

### Bin ages
metadata$minAge <- metadata$age
metadata$maxAge <- metadata$age

metadata$age <- as.numeric(metadata$age)

metadata <- metadata %>%
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

### Format to backend table
colnames(metadata) <- c("individualId", "age", "Sex", "studyKey", "Diagnosis", "minAge", "maxAge")

metadata <- metadata[, c("studyKey", "individualId", "minAge", "maxAge", "Sex", "Diagnosis")]

### Replace original IDs with Sage IDs, bring in updated ID mapping table
id_mapping <- as.data.frame(synTableQuery("select * from syn64287566")) ### Filter by study key here as some studies use the same OG IDs

metadata$individualId <- with(id_mapping, 
                              individualId[match(metadata$individualId, originalId)])

### Upload new Individual data into the Backend - Individuals table
synStore(Table("syn64290226",metadata)) ### This is the synID of the backend individuals table
