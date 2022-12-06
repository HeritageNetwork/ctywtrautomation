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

# Make sure the output directories have been created:
ifelse(!dir.exists(here::here("_data")), dir.create(here::here("_data")), FALSE)
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

###########################
# add in NABA data?

## Set up driver info and database path
DRIVERINFO <- "Driver={Microsoft Access Driver (*.mdb, *.accdb)};"
nabaPATH <- "X:/ZOOLOGY/NABA Deliverables (Jan2020)/Crayfish-Fish-MusselsSpeciesHUC_2020Jan05.accdb"
channel <- odbcDriverConnect(paste0(DRIVERINFO, "DBQ=", nabaPATH))
## Load data into R dataframe
nabaTable <- sqlQuery(channel, "SELECT * FROM [Species-HUC];",stringsAsFactors=FALSE)
close(channel) ## Close and remove channel

## Connect to central biotics to pull out most recent data on sss
# con <- odbcConnect("bioticscentral.natureserve.org", uid="biotics_report", pwd=rstudioapi::askForPassword("Password"))


nabaTableEGT <- read.csv("NABA_EGT_attributes_202206.txt", stringsAsFactors=FALSE)  ## TEMPORARY STEP TO GET AROUND BIOTICS. THis has all the columns created

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

