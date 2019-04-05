#This script formats ESSENCE visit count data so that it can be used with satscan software to detect data dropoffs
#It pulls data from ESSENCE using ESSENCE APIs and assigns C_BioSense_Facility_IDs as ED ID  

#once you enter the ESSENCE URL and your pw, username and file path for working directory, highlight entire script and run
#two csv files, one with visit count data and one with coordinate data will be saved to the wd file path

#################################################################################################################
# SCRIPT SETUP, EDIT PARAMETERS IN THIS SECTION AND DO NOT EDIT ANY OTHER PART OF THIS SCRIPT
# enter your ESSENCE username and file path where you would like csv to be saved
# After username, wd, and URL are entered, highlight entire script and run. 
# A popup will ask you to enter pw. Enter your BioSense password.

username='username'
wd='wd'

#use API url from table builder page with selected row fields=Date and selected columnField=Facility
URL <- 'URL'

#############################################################################
#setting pw for BioSense. 
if (!require(keyring)) install.packages('keyring')
library(keyring)
key_set("ESSENCE")

#loading packages and installing if not already
if (!require("pacman")) install.packages("pacman")
pacman::p_load(httr, jsonlite, readr, dbplyr, odbc, DBI, dplyr, tidyr)
httr::set_config(config(ssl_verifypeer = 0L))

#collecting table builder results
api_response <- GET(URL, authenticate(username, key_get("ESSENCE")))
api_response_csv <- content(api_response, as = "text")
ESSENCE_table <- read_csv(api_response_csv)

#gathering data
ESSENCE_table = gather(ESSENCE_table, 
                       names(ESSENCE_table[2:length(ESSENCE_table)]), 
                       key='Facility', 
                       value='counts')

# getting c_biosense_facility_ids from MFT
con <- dbConnect(odbc::odbc(), 
                 dsn = "Biosense_Platform", 
                 UID = paste0("BIOSENSE\\", username), 
                 PWD = key_get("ESSENCE"))

#establish a reference to a table in the database
MFT <- tbl(con, "WA_MFT")

# merging with ESSENCE_table 
MFT_report <- MFT %>% 
  select(Facility_Display_Name, C_Biosense_Facility_ID) %>% 
  collect()

ESSENCE_table <- merge(ESSENCE_table, MFT_report, 
                       by.x='Facility', 
                       by.y='Facility_Display_Name', 
                       all.x=TRUE)

#ordering and renaming columns
ESSENCE_table <- ESSENCE_table %>% 
  select(C_Biosense_Facility_ID, counts, timeResolution)

names(ESSENCE_table) <- c('ED', 'Count', 'Date')

#reformatting date column
ESSENCE_table$Date <- format(ESSENCE_table$Date, '%Y/%m/%d')

#creating coordinate file
coord <- ESSENCE_table %>%
  select(ED) %>%
  arrange(ED) %>%
  distinct()

coord_len <- length(coord$ED)-1
coord_end <- 100000+10*coord_len
coord$coord_1 <- seq(100000, coord_end, 10)
coord$coord_2 <- coord$coord_1

#saving data to workin directory
setwd(wd)
write.csv(ESSENCE_table, 'satscan_data.csv', row.names = FALSE)
write.csv(coord, 'coordinate_file.csv', row.names = FALSE)



