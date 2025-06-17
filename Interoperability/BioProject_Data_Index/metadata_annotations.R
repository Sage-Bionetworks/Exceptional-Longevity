### Gorbunova file annotations - Example

### After the link entities have been created using the previous script, the naming format looks something like this:
### "GSM5730459 AMS1Lung Acomys russatus RNASeq"
### This format is important for the below code to work, but may not be exactly the same for each BioProject study.

# Create an entity view including all of the link entities that were creating using the previous script.

# Get the entity view to add annotations
entity_view <- synTableQuery("SELECT * FROM syn66351296")
df <- as.data.frame(entity_view)

### We will start with adding the link-specific file annotations

# Parse name column to extract 'specimenID', 'speciesName', and 'organ', since those are annotated on a per-link basis
df <- df %>%
  mutate(
    specimenID = word(name, 2),                 
    speciesName = str_c(word(name, 3), word(name, 4), sep = " "),
    organ = str_extract(specimenID, "[A-Z][a-z]+$")
  )

# Store the first set of annotations back into the entity view
synStore(Table("syn66351296", df))

### The next set of annotations will be file annotations that are the same for each link

entity_view <- synTableQuery("SELECT * FROM syn66351296")
df <- as.data.frame(entity_view)

# These are the annotations that I was able to manually parse this study and service desk ticket for
# Altogether, the annotations are a combination of attributes from the individual, biospecimen, and assay metadata templates

df$specimenType <- "tissue"
df$assay <- "RNAseq"
df$measurementTechnique <- "RNAseq"
df$technologyPlatformVersion <- "Illumina NextSeq 550"
df$repositoryName <- "SRA"

synStore(Table("syn66351296", df))
