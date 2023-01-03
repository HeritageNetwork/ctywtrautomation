# Name: 01_CtyAndWtrdb_creator.R
# Purpose: Convert Biotics Exports to SQLite DB
# Authors: Jordana Anderson, Chris Tracey, Cameron Scott
# Created: 2022-11-11
#
#---------------------------------------------------

rm(list=ls()) # clean environments

library(tidyr)

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
county_table <- read.table(sourceCnty, header=TRUE, sep="\t")
watershed_table <- read.table(sourceWater, header=TRUE, sep="\t", colClasses=c("HUC8_CD"="character"))

# Write tables to sqlite db
db <- dbConnect(SQLite(), dbname=databasename) # connect to db
dbWriteTable(db, "county_table", county_table, overwrite=TRUE)
dbWriteTable(db, "watershed_table", watershed_table, overwrite=TRUE)
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

# NABA_1_ind_4_AnyESA_IND
nabaTableEGT[nabaTableEGT$LT_IND=="Y" | nabaTableEGT$LE_IND=="Y" | grep("C", nabaTableEGT$USESA_CD), "ANYUSESA_IND" ] <- "Y"  

# NABA_1_ind_3_CandProp_IND
library(sqldf)
a <- sqldf("select * from nabaTableEGT where USESA_CD = 'C' OR USESA_CD LIKE '%PE%' OR USESA_CD LIKE '%PT%' OR USESA_CD LIKE '%PSA%' ")

nabaTableEGT[nabaTableEGT$LT_IND!="Y" & nabaTableEGT$LE_IND!="Y" & nabaTableEGT$USESA_CD=="C", "CANDPROP_IND"] <- "Y"
nabaTableEGT[nabaTableEGT$LT_IND!="Y" & nabaTableEGT$LE_IND!="Y" & grep("PE", nabaTableEGT$USESA_CD), "CANDPROP_IND"] <- "Y"
nabaTableEGT[nabaTableEGT$LT_IND!="Y" & nabaTableEGT$LE_IND!="Y" & nabaTableEGT$USESA_CD=="C", "CANDPROP_IND"] <- "Y"

nabaTableEGT$CANDPROP_IND <- NA


UPDATE nabaTableEGT SET NABA_EGT_attributes_202206.CANDPROP_IND = "Y"
WHERE (((NABA_EGT_attributes_202206.USESA_CD)="C") AND ((NABA_EGT_attributes_202206.LE_IND) Is Null) AND ((NABA_EGT_attributes_202206.LT_IND) Is Null)) OR (((NABA_EGT_attributes_202206.USESA_CD) Like "*PE*") AND ((NABA_EGT_attributes_202206.LE_IND) Is Null) AND ((NABA_EGT_attributes_202206.LT_IND) Is Null)) OR (((NABA_EGT_attributes_202206.USESA_CD) Like "*PT*") AND ((NABA_EGT_attributes_202206.LE_IND) Is Null) AND ((NABA_EGT_attributes_202206.LT_IND) Is Null)) OR (((NABA_EGT_attributes_202206.USESA_CD) Like "PSA*") AND ((NABA_EGT_attributes_202206.LE_IND) Is Null) AND ((NABA_EGT_attributes_202206.LT_IND) Is Null));



nabaTableEGT[which(nabaTableEGT$LT_IND=="Y"),]








nabatable2 <- merge(nabaTable, nabaTableEGT, by.x=c("EGT_ID","G_COMNAME"), by.y=c("ELEMENT_GLOBAL_ID","G_COMNAME"), all.x=TRUE)

nabatable2a <- nabatable2[c(names(watershed_table))]

# names(nabaTable)
# names(nabaTableEGT)
# names(watershed_table)

names(nabatable2)[names(nabatable2) == "G_NAME"] <- "GNAME"
names(watershed_table)[names(watershed_table) == "ELEMENT_GLOBAL_ID"] <- "EGT_ID"



setdiff(names(nabatable2),names(watershed_table))
setdiff(names(watershed_table),names(nabatable2))

watershed_table_check <- watershed_table[c(names(nabaTableEGT))]


combined_table <- rbind(watershed_table_check, nabaTableEGT)

# Find duplicates in county table
# Jason's SQL for this step: 
# In (SELECT [ELEMENT_GLOBAL_ID] FROM [Widget_NSX_cty_export_201904] As Tmp GROUP BY [ELEMENT_GLOBAL_ID],[STATE_COUNTY_FIPS_CD] HAVING Count(*)>1  And [STATE_COUNTY_FIPS_CD] = [Widget_NSX_cty_export_201904].[STATE_COUNTY_FIPS_CD])
library(sqldf)
select <- "SELECT county_table.ELEMENT_GLOBAL_ID"
from <- "FROM county_table"
group <- "GROUP BY ELEMENT_GLOBAL_ID, FIPS_CD"
count <- "HAVING COUNT(*) > 1"

query <- paste(select, from, group, count)

sqldf(query)

# Find duplicates in watershed table
# Jason's SQL for this step:
# In (SELECT [ELEMENT_GLOBAL_ID] FROM [Widget_NSX_huc_export_201904] As Tmp GROUP BY [ELEMENT_GLOBAL_ID],[WATERSHED_CD_HUC8] HAVING Count(*)>1  And [WATERSHED_CD_HUC8] = [Widget_NSX_huc_export_201904].[WATERSHED_CD_HUC8])
select <- "SELECT watershed_table.EGT_ID"
from <- "FROM watershed_table"
group <- "GROUP BY EGT_ID, HUC8_CD"
count <- "HAVING COUNT(*) > 1"

query <- paste(select, from, group, count)

sqldf(query)

# May need to do other duplicate checks - Jason did some
# on the Naba tables

# Generate table with list of all species by county
# 

