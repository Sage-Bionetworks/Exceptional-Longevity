### Changing the Individual ID annotation to the Sage-generated individual ID

### Pull in ID mapping
id_mapping <- as.data.frame(synTableQuery("select * from syn64287566")) ### synID of the Bakcend - ID Mapping table where Sage-generated and original IDs are stored
             ### Depending on the study you may need to filter this table by study key
             ### For example, %>% filter(studyKey == "LLFS") , if the study you are working on is LLFS

### Pull in file view for study and change IDs
study <- as.data.frame(synTableQuery("select * from synID")) ### Insert the synID of the file view you are using for annotations

study$individualID <- id_mapping$individualId[match(study$individualID, id_mapping$originalId)]

synStore(Table("synID", study))
