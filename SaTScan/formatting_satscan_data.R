#This script pulls data using ESSENCE APIs
#it formats ESSENCE data so that it can be used with satscan software to detect data dropoffs 
#once you enter the ESSENCE URL, pw, username and wd, highlight entire script and run
#csv file with properly formatted data will be saved to wd file path 

##############################################################################
#SCRIPT SETUP, SET PARAMETERS IN THIS SECTION AND DO NOT EDIT ANY OTHER PART OF THIS SCRIPT

#setting pw for BioSense. A popup will ask you to enter pw.
#This authenication info is required for connecting to ESSENCE APIs and tables in BioSense_Platform
key_set("ESSENCE")

#enter your username and file path where you would like csv to be saved
username='username'
wd='wd'

#use API url from table builder page with selected row fields=timeResolution and selected columnField=Facility
URL <- 'URL'

############################################################################
#loading packages and installing if not already
if (!require("pacman")) install.packages("pacman")
pacman::p_load(keyring, httr, jsonlite, readr, dbplyr, odbc, DBI, dplyr, tidyr)
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

#saving data to workin directory
setwd(wd)
write.csv(ESSENCE_table, 'satscan_data.csv')



