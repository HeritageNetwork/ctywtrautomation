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

#***need to find raw naba data***
#naba_table <- read.table("naba.csv", stringsAsFactors = FALSE)
#dbWriteTable(db, "naba_table", naba_table, overwrite = TRUE)
