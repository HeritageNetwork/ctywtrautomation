# Name: 01_CtyAndWtrdb_creator.R
# Purpose: Convert Biotics Exports to SQLite DB
# Authors: Jordana Anderson, Chris Tracey, Cameron Scott
# Created: 2022-11-11
#
#---------------------------------------------------

rm(list=ls()) # clean environments

# Settings from Script 00
if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)
#source(here::here("Automation_scripts", "00_PathsAndSettings_CtyWtr.r"))
source(here::here("00_PathsAndSettings_CtyWtr.r"))

# Make sure the input and output directories have been created:
ifelse(!dir.exists(here::here("_data")), dir.create(here::here("_data")), FALSE)
ifelse(!dir.exists(here::here("_data","input")), dir.create(here::here("_data","input")), FALSE)
ifelse(!dir.exists(here::here("_data","output")), dir.create(here::here("_data","output")), FALSE)

########################
# Convert Biotics Exports to SQLite Databases
db <- dbConnect(SQLite(), dbname=databasename) # creates an empty database
dbDisconnect(db) # disconnect the db

# Load tables
tbl_county <- read.table(sourceCnty, header=TRUE, sep="\t", colClasses=c("FIPS_CD"="character"))
tbl_watershed <- read.table(sourceWater, header=TRUE, sep="\t", colClasses=c("HUC8_CD"="character"))

# Write tables to sqlite db
db <- dbConnect(SQLite(), dbname=databasename) # connect to db
dbWriteTable(db, "tbl_county", tbl_county, overwrite=TRUE)
dbWriteTable(db, "tbl_watershed", tbl_watershed, overwrite=TRUE)
dbDisconnect(db) # disconnect the db
rm(db)


###########################
# add in NABA data

## Set up driver info and database path
DRIVERINFO <- "Driver={Microsoft Access Driver (*.mdb, *.accdb)};"
nabaPATH <- "X:/ZOOLOGY/NABA Deliverables (Jan2020)/Crayfish-Fish-MusselsSpeciesHUC_2020Jan05.accdb"
channel <- odbcDriverConnect(paste0(DRIVERINFO, "DBQ=", nabaPATH))
## Load data into R dataframe
nabaTable <- sqlQuery(channel, "SELECT * FROM [Species-HUC];",stringsAsFactors=FALSE)
close(channel) ## Close and remove channel


## Connect to central biotics to pull out most recent data on sss
# con <- odbcConnect("bioticscentral.natureserve.org", uid="biotics_report", pwd=rstudioapi::askForPassword("Password"))
# Stop here and copy the "_data/queries/NABA_EGT_attributes.sql" query into Biotics.  Save the output to the input directory in the format of "NABA_EGT_attributes_YYYYMM.csv"

NABAegtid_file <- list.files(path=here::here("_data","input"), pattern=".csv$")  
NABAegtid_file # look at the output,choose which csv you want to load, and enter its location in the list (first = 1, second = 2, etc)
n <- 1
NABAegtid_file <- here::here("_data","input", NABAegtid_file[n])
nabaTableEGT <- read.csv(NABAegtid_file, stringsAsFactors=FALSE, colClasses = "character")  ## TEMPORARY STEP TO GET AROUND BIOTICS. THis has all the columns created
rm("NABAegtid_file", n) # clean up the environment

names(nabaTableEGT)

# replace NA with blanks in certain columns
nabaTableEGT <- nabaTableEGT %>% 
  mutate_at(c("G1G2ORUSESA_IND","G1G2_IND","ANYUSESA_IND","LE_IND","LT_IND","CANDPROP_IND","G1G2WOUSESA_IND"), ~replace_na(.,""))

# NABA_1_ind_1_LE_IND
nabaTableEGT[grep("E", nabaTableEGT$USESA_CD), "LE_IND" ] <- "Y" 
nabaTableEGT[grep("LE", nabaTableEGT$USESA_CD), "LE_IND" ] <- "Y" 

# NABA_1_ind_2_LT_IND
nabaTableEGT[grep("T", nabaTableEGT$USESA_CD), "LT_IND" ] <- "Y" 
nabaTableEGT[grep("LT", nabaTableEGT$USESA_CD), "LT_IND" ] <- "Y"

# NABA_1_ind_3_CandProp_IND
# nabaTableEGT[nabaTableEGT$LT_IND=="Y", "CANDPROP_IND" ] <- "Y"
# library(sqldf)
# a <- sqldf("select * from nabaTableEGT where USESA_CD = 'C' OR USESA_CD LIKE '%PE%' OR USESA_CD LIKE '%PT%' OR USESA_CD LIKE '%PSA%' ")
# nabaTableEGT[nabaTableEGT$LT_IND!="Y" & nabaTableEGT$LE_IND!="Y" & nabaTableEGT$USESA_CD=="C", "CANDPROP_IND"] <- "Y"
# nabaTableEGT[nabaTableEGT$LT_IND!="Y" & nabaTableEGT$LE_IND!="Y" & grep("PE", nabaTableEGT$USESA_CD), "CANDPROP_IND"] <- "Y"
# nabaTableEGT[nabaTableEGT$LT_IND!="Y" & nabaTableEGT$LE_IND!="Y" & nabaTableEGT$USESA_CD=="C", "CANDPROP_IND"] <- "Y"
# nabaTableEGT$CANDPROP_IND <- NA

# UPDATE "nabaTableEGT"
# SET "CANDPROP_IND" = "Y"
# WHERE ((NABA_EGT_attributes_202206.USESA_CD)="C") AND (is.null(NABA_EGT_attributes_202206.LE_IND)) AND (is.null(NABA_EGT_attributes_202206.LT_IND)) OR 
# ((NABA_EGT_attributes_202206.USESA_CD) %Like% "%PE") AND (is.null(NABA_EGT_attributes_202206.LE_IND)) AND (is.null(NABA_EGT_attributes_202206.LT_IND)) OR 
# ((NABA_EGT_attributes_202206.USESA_CD) %Like% "%PT") AND (is.null(NABA_EGT_attributes_202206.LE_IND)) AND (is.null(NABA_EGT_attributes_202206.LT_IND)) OR 
# ((NABA_EGT_attributes_202206.USESA_CD) %Like% "%PSA") AND (is.null(NABA_EGT_attributes_202206.LE_IND)) AND (is.null(NABA_EGT_attributes_202206.LT_IND));

# NABA_1_ind_4_AnyESA_IND
nabaTableEGT[nabaTableEGT$LT_IND=="Y", "ANYUSESA_IND" ] <- "Y"
nabaTableEGT[nabaTableEGT$LE_IND=="Y", "ANYUSESA_IND" ] <- "Y"
nabaTableEGT[grep("C", nabaTableEGT$USESA_CD), "ANYUSESA_IND" ] <- "Y"
#nabaTableEGT[nabaTableEGT$CANDPROP_IND=="Y", "ANYUSESA_IND" ] <- "Y"

# NABA_1_ind_5_G1G2woESA_IND #DO BOTH CONDITIONS NEED TO BE MET?
nabaTableEGT[nabaTableEGT$G1G2_IND=="Y", "G1G2woESA_IND" ] <- "Y"
nabaTableEGT[is.null(nabaTableEGT$ANYUSESA_IND), "G1G2woESA_IND" ] <- "Y"

# NABA_1_ind_6_G1G2orESA_IND
nabaTableEGT[nabaTableEGT$ANYUSESA_IND=="Y", "GIG2ORUSESA_IND" ] <- "Y"
nabaTableEGT[nabaTableEGT$G1G2_IND=="Y", "G1G2ORUSESA_IND" ] <- "Y"

# NABA_1_ind_7_counts
length(which(nabaTableEGT$G1G2_IND=="Y"))
length(which(nabaTableEGT$LE_IND=="Y"))
length(which(nabaTableEGT$LT_IND=="Y"))
length(which(nabaTableEGT$CANDPROP_IND=="Y"))
length(which(nabaTableEGT$ANYUSESA_IND=="Y"))
length(which(nabaTableEGT$G1G2WOUSESA_IND=="Y"))
length(which(nabaTableEGT$G1G2ORUSESA_IND=="Y"))

# Find duplicates in county table
# Jason's SQL for this step: 
# In (SELECT [ELEMENT_GLOBAL_ID] FROM [Widget_NSX_cty_export_201904] As Tmp GROUP BY [ELEMENT_GLOBAL_ID],[STATE_COUNTY_FIPS_CD] HAVING Count(*)>1  And [STATE_COUNTY_FIPS_CD] = [Widget_NSX_cty_export_201904].[STATE_COUNTY_FIPS_CD])
library(sqldf)
select <- "SELECT tbl_county.ELEMENT_GLOBAL_ID"
from <- "FROM tbl_county"
group <- "GROUP BY ELEMENT_GLOBAL_ID, FIPS_CD"
count <- "HAVING COUNT(*) > 1"

query <- paste(select, from, group, count)
sqldf(query)

# Find duplicates in watershed table
# Jason's SQL for this step:
# In (SELECT [ELEMENT_GLOBAL_ID] FROM [Widget_NSX_huc_export_201904] As Tmp GROUP BY [ELEMENT_GLOBAL_ID],[WATERSHED_CD_HUC8] HAVING Count(*)>1  And [WATERSHED_CD_HUC8] = [Widget_NSX_huc_export_201904].[WATERSHED_CD_HUC8])
select <- "SELECT tbl_watershed.ELEMENT_GLOBAL_ID"
from <- "FROM tbl_watershed"
group <- "GROUP BY ELEMENT_GLOBAL_ID, HUC8_CD"
count <- "HAVING COUNT(*) > 1"

query <- paste(select, from, group, count)

sqldf(query)

nabatable2 <- merge(nabaTable, nabaTableEGT, by.x=c("EGT_ID","G_COMNAME"), by.y=c("ELEMENT_GLOBAL_ID","G_COMNAME"), all.x=TRUE)

#nabatable2a <- nabatable2[c(names(tbl_watershed))]

names(nabaTable)
names(nabaTableEGT)
names(tbl_watershed)

names(nabatable2)[names(nabatable2) == "G_NAME"] <- "GNAME"
names(tbl_watershed)[names(tbl_watershed) == "ELEMENT_GLOBAL_ID"] <- "EGT_ID"

setdiff(names(nabatable2),names(tbl_watershed))
setdiff(names(tbl_watershed),names(nabatable2))

#watershed_table_check <- tbl_watershed[c(names(nabaTableEGT))]

combined_table <- rbind(tbl_watershed_check, nabaTableEGT)

#########################################
# make a summary table of counts of species by county and watershed
library(dplyr)

tbl_county_sums <- tbl_county  %>%
  group_by(FIPS_CD)  %>%
    dplyr::summarize(
    count_allsp = n(),
    count_G1G2 = length(GNAME[G1G2_IND=='Y']),
    count_ESA = length(GNAME[ANYUSESA_IND=='Y']),
    count_G1G2ESA = length(unique(GNAME[ANYUSESA_IND=='Y'|G1G2_IND=='Y'])),
  )

tbl_county_sums$sym_count_G1G2ESA <- cut(tbl_county_sums$count_G1G2ESA, breaks = c(0, .9, 5, 20, 50, 100, max(tbl_county_sums$count_G1G2ESA)), labels=c("No Data", "1-5", "6-20", "21-50", "51-100",">100"), include.lowest=TRUE) 


tbl_watershed_sums <- tbl_watershed  %>%
  group_by(HUC8_CD)  %>%
  dplyr::summarize(
    count_allsp = n(),
    count_G1G2 = length(GNAME[G1G2_IND=='Y']),
    count_ESA = length(GNAME[ANYUSESA_IND=='Y']),
    count_G1G2ESA = length(unique(GNAME[ANYUSESA_IND=='Y'|G1G2_IND=='Y'])),
  )

tbl_watershed_sums$sym_count_G1G2ESA <- cut(tbl_watershed_sums$count_G1G2ESA, breaks = c(0, .9, 5, 20, 50, 100, max(tbl_watershed_sums$count_G1G2ESA)), labels=c("No Data", "1-5", "6-20", "21-50", "51-100",">100"), include.lowest=TRUE)


########################################
# make feature classes

# add in step to create an empty geodatabase, for now I just made one in the folder via Pro

# counties  # note, need to document the source of the county dataset as USGS, last downloaded data, etc
counties_sf <- arc.open(counties)
counties_sf <- arc.select(counties_sf, fields=c("ADMIN_NAME","ADMIN_FIPS","STATE","STATE_FIPS","NAME","SQ_MILES","SUFFIX"), where_clause="STATE NOT IN ('VI', 'PR')")
counties_sf <- arc.data2sf(counties_sf)
# setdiff(tbl_county$FIPS_CD, counties_sf$ADMIN_FIPS)
# setdiff(counties_sf$ADMIN_FIPS, tbl_county$FIPS_CD)
counties_sf <- merge(counties_sf, tbl_county_sums, by.x="ADMIN_FIPS", by.y="FIPS_CD", all.x=TRUE)
counties_sf <- counties_sf[c("ADMIN_FIPS","ADMIN_NAME","NAME","STATE","STATE_FIPS","SQ_MILES","count_allsp","count_G1G2","count_ESA","count_G1G2ESA","sym_count_G1G2ESA","geometry")]
arc.delete(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "counties_AllSpTot"))
arc.write(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "counties_AllSpTot"), counties_sf, validate=TRUE, overwrite=TRUE)

# county related table of species
arc.write(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "tbl_county"), tbl_county, validate=TRUE, overwrite=TRUE)
   # need to build a relationship class in ArcPy
   # something like: arcpy.management.CreateRelationshipClass("watersheds_AllSpTot", "tbl_watershed", r"S:\Projects\_Workspaces\Christopher_Tracey\CountyWatershed\ctywtrautomation\_data\output\_refresh202301\_refresh202301.gdb\watersheds_AllSpTot_tbl_watershed", "SIMPLE", "tbl_watershed", "watersheds_AllSpTot", "NONE", "ONE_TO_MANY", "NONE", "huc8", "HUC8_CD", '', '')

# watersheds # note, need to document the source of the county dataset as USGS, last downloaded data, etc
watersheds_sf <- arc.open(watersheds)
watersheds_sf <- arc.select(watersheds_sf, fields=c("loaddate","name","huc8","states","areasqkm"))
watersheds_sf <- arc.data2sf(watersheds_sf)
watersheds_sf <- merge(watersheds_sf, tbl_watershed_sums, by.x="huc8", by.y="HUC8_CD", all.x=TRUE)
watersheds_sf <- watersheds_sf[c("huc8","name","states","areasqkm","count_allsp","count_G1G2","count_ESA","count_G1G2ESA","sym_count_G1G2ESA","geometry")]
arc.delete(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "watersheds_AllSpTot"))
arc.write(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "watersheds_AllSpTot"), watersheds_sf, validate=TRUE, overwrite=TRUE)

# watershed related table of species
arc.write(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "tbl_watershed"), tbl_watershed, validate=TRUE, overwrite=TRUE)
  # need to build a relationship class in ArcPy
  # something like: arcpy.management.CreateRelationshipClass("watersheds_AllSpTot", "tbl_watershed", r"S:\Projects\_Workspaces\Christopher_Tracey\CountyWatershed\ctywtrautomation\_data\output\_refresh202301\_refresh202301.gdb\watersheds_AllSpTot_tbl_watershed", "SIMPLE", "tbl_watershed", "watersheds_AllSpTot", "NONE", "ONE_TO_MANY", "NONE", "huc8", "HUC8_CD", '', '')





######################################
# create metadata


#########################################
# create preview graphics


########################################
# create information for marketplace page

