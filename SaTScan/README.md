# SaTScan sample data and formatting script 

This directory contains example data and coordinate file that can be used to detect data drop offs using [SaTScan software](https://www.satscan.org/techdoc.html).     

## Getting Started

### File descriptions

* **example_coordinate_file.csv** - coordinate file of example from April DQC webinar. Columns: ED, coord_1, coord_2
* **example satscan_data.csv** - visit counts by date and ED, example from April DQC webinar. Columns: ED, Count, and Date. 
* **formatting_satscan_data.R** - script pulls data using ESSENCE table builder API URL. It formats data into SatScan format as seen in the "satscan_data.csv" and creates a coordinate file.  

### Pulling data from ESSENCE using ESSENCE APIs

1. Login to ESSENCE
2. Click on "Query Portal" tab
3. Enter query parameters
4. Click on "Table Builder" button
5. Select "Facility" as the column field 
6. Select "Date" as row field
7. Click on "Query Options" in top left corner of screen
8. Click on "API URLs"
9. Copy and paste the contents of the "CSV" box into the R script replacing "URL" 
10. Enter wd and username in script where prompted. Highlight and run script.
