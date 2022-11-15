# load packages
if (!requireNamespace("RSQLite", quietly=TRUE)) install.packages("RSQLite")
require(RSQLite)
if (!requireNamespace("openxlsx", quietly=TRUE)) install.packages("openxlsx")
require(openxlsx)
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
require(sf)
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
require(arcgisbinding)
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
require(dplyr)
if (!requireNamespace("lubridate", quietly = TRUE)) install.packages("lubridate")
require(lubridate)
if (!requireNamespace("reshape", quietly = TRUE)) install.packages("reshape")
require(reshape)
if (!requireNamespace("plyr", quietly = TRUE)) install.packages("plyr")
require(plyr)
if (!requireNamespace("dplyr", quietly=TRUE)) install.packages("dplyr")
require(dplyr)

#load the arcgis license
arc.check_product()

# update refresh name 
updateName <- "_refresh202301"
updateNameprev <- "_refresh202207"

# create a directory for this update unless it already exists
ifelse(!dir.exists(here::here("_data","output",updateName)), dir.create(here::here("_data","output",updateName)), FALSE)

# rdata file 
updateData <- here::here("_data","output",updateName,paste(updateName, "RData", sep="."))

# output database name
Cty_databasename <- here::here("_data","output",updateName,"test.sqlite")

# cutoff and exclusions for records ***Also not needed
# this refresh? Do the SQL Biotics scripts take care of this??

# final fields for arcgis ***Need to double check if these are
# the correct fields
final_fields <- c("ELEMENT_GLOBAL_ID", "INFORMAL_TAX", "GNAME", "G_COMNAME", "G_RANK", "ROUNDED_G_RANK", "USESA_STATUS", "S_RANK", "S_RANK_ROUNDED", "MAX_OBS_YEAR", "BEST_EO_RANK", "OCC_SRC", "FIPS_CD", "COUNTY_NAME", "STATE_CD", "NSX_LINK")

# north america albers equal area conic projection
# ***DOUBLE CHECK***
albersconic <- "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 
+x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"

# function to load species list ***Needed next refresh?

# THIS IS A TEST CHANGE FROM CHRIS
