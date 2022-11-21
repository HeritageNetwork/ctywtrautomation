# Name: 01_CtyAndWtrdb_creator.R
# Purpose: Convert Biotics Exports to SQLite DB
# Authors: Jordana Anderson, Chris Tracey, Cameron Scott
# Created: 2022-11-11
#
#---------------------------------------------------
#clear the environments **Do we need this step?
rm(list=ls())

# Settings from Script 00
if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)
source(here::here("Automation_scripts", "00_PathsAndSettings_CtyWtr.r"))

# Convert Biotics Exports to SQLite Databases
# Create empty sqlite db
db <- dbConnect(SQLite(), dbname=databasename) # creates an empty database
dbDisconnect(db) # disconnect the db

# Load tables
county_table <- read.table("widget_egt_county_export_202203_v4.txt", header=TRUE, sep="\t")
watershed_table <- read.table("widget_egt_watershed_202203_export_v4.txt", header=TRUE, sep="\t")
#***need to find raw naba data***
#naba_table <- read.table("naba.csv", stringsAsFactors = FALSE)

# Write tables to sqlite db
db <- dbConnect(SQLite(), dbname=databasename) # connect to db
dbWriteTable(db, "county_table", county_table, overwrite = TRUE)
dbWriteTable(db, "watershed_table", watershed_table, overwrite = TRUE)
#dbWriteTable(db, "naba_table", naba_table, overwrite = TRUE)
dbDisconnect(db) # disconnect the db



