# AntWrangler

Automated PIT tag antenna data organization and cleaning tool for Oregon RFID and Biomark antennas


## Instructions

### Get the files

Click the ***Clone or download button*** and select ***Download zip*** - a zipped directory containing all files will be downloaded.
Unzip the directory and move the folder to a script directory on your system.

#### The R files

There are three R files included:

+ **pit_tag_data_compile_functions.r**: a function file to be sourced in the *pit_tag_data_compile_run.r* file
+ **pit_tag_data_compile_run.r**: a file that runs the PIT tag data compiling program  
+ **pit_tag_data_explorer.r**: a script will a few plotting and summary utilities for exploring the compiled PIT tag data

#### The example files

There is an ***example*** folder that contain all files needed to perform a test of the scripts.

```
\---example
	|
    +---CAWD
    |   +---archive
    |   \---downloads
    |           CAWD2_06082018
    |
    +---RanchoSanCarlos
    |   +---archive
    |   \---downloads
    |           01_00120.log
    |
    +---Scarlett
    |   +---archive
    |   \---downloads
    \---SleepyHollow
        +---archive
        \---downloads
                SH2_20180607_fulldownload
```


### Directory Setup

The compilation program is expecting a certain directory structure so that it can find files to incorporate and where it should move log file that have been parsed and included in the database files.

Here is the structure you need to create per site:

```
\---sites
	|
    +---site1
    |   +---archive
    |   \---downloads
    |
    +---site2
    |   +---archive
    |   \---downloads
    |
    +---site3
        +---archive
        \---downloads
```

`site`: will hold the log files for an individual reader - whatever the name of the folder is, is what the name of the site will be in the database files
`archive`: is where files that have been parsed and incorporated into the database files will be moved to - the date of inclusion in the db files will be prepended to the original file name
`download` is where you should place log files from the readers that you want incorporated into the DB files


### Running the program

Open the ***pit_tag_data_compile_run.r*** file in RStudio. This file is simply a helper for defining variables and 
calling the compiling program. First. Four variables need to be defined 

| Name | Type | Definition
| - | - | - |
| functionsPath | String, File path | The full system path to the ***pit_tag_data_compile_functions.r*** file
| dataDir | String, directory path | The full system path to the directory where the source log data exist - it should be the parent directory to all the site directories - 'sites' from the above directory structure example.
| dbDir | String, directory path | The full system path to the directory where the compiled log data base file exist or should be initially written to
| timeZone | String | The time zone for where the raw PIT tag data was collected. Use this to find your time zone: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

Alter the variable definitions to suit your needs and then run the script.




##### About the compiled data tables

There are 7 data tables that may be produced, depending on your data inputs

**logDB.csv**: these are successful tag readings where are data acquired from the reader is formatted correctly

The log data table does not have a column header. The columns are defined as such:

```
site, manuf, srcfile, compdate, metapct, metabadpct, tagpct, tagfailpct, tagbadpct, msgpct, msgbadpct, otherpct, tagnrow, tagfailnrow, tagbadnrow, msgnrow, msgbadnrow, othernrow, totalnrow
```

+ `site`: the name of the site or antenna 
+ `manuf`: the type of PIT reader system (ORFID or Biomark)
+ `srcfile`: the raw PIT tag data source file path
+ `compdate`: the date this entry was compiled to the database
+ `metapct`: the percent of lines in source file that were metadata (ORFID)
+ `metabadpct`: the percent of lines in source file that were bad metadata (ORFID)
+ `tagpct`: the percent of lines in log file that are good tag reads
+ `tagfailpct`: the percent of lines in log file that are failed tag reads - the tag ID is not valid
+ `tagbadpct`: the percent of lines in log file that are bad tag reads - the line could not be parsed correctly
+ `msgpct`: the percent of lines in log file that are good messages - parsed correctly
+ `msgbadpct`: the percent of lines in log file that are bad messages - parsed incorrectly
+ `otherpct`: the percent of lines in log file that could not be parsed correctly to identify whether it was a tag reading or a message
+ `tagnrow`: the number of lines in log file that are good tag reads
+ `tagfailnrow`: the number of lines in log file that are failed tag reads - the tag ID is not valid
+ `tagbadnrow`: the number of lines in log file that are bad tag reads - the line could not be parsed correctly
+ `msgnrow`: the number of lines in log file that are good messages - parsed correctly
+ `msgbadnrow`: the number of lines in log file that are bad tag reads - the line could not be parsed correctly
+ `othernrow`: the number of lines in log file that could not be parsed correctly to identify whether it was a tag reading or a message
+ `totalnrow`: the total number of lines in the reader log file
  
**tagDB.csv**: these are successful tag readings where data acquired from the reader is formatted correctly

The tag data table does not have a column header. The columns are defined as such:

```
date, time, fracsec, datetime, duration, tagtype, tagid, antnum, consdetc, arrint, site, manuf, srcfile, srcline, compdate
```

+ `date`: raw data collection datetime
+ `time`: raw data collection time
+ `fracsec`: raw data collection fraction of a second for the time
+ `datetime`: raw date and time
+ `duration`: duration tag was in the field 
+ `tagtype`: tag type (A for ISO animal format, R for read-only, W for writeable tag; OregonRFID)
+ `tagid`: the PIT tag id
+ `antnum`: antenna number (multiple antenna reader only)
+ `consdetc`: consecutive detections count  
+ `arrint`: arrival interval - empty scans before detection
+ `site`: site or antenna where PIT tag data was collected
+ `manuf`: equipment manufacturer (ORFID or Biomark)
+ `srcfile`: the raw PIT tag data source file path
+ `srcline`: the raw PIT tag data source file line
+ `compdate`: the date this entry was compiled

**metaDB.csv**: these are the metadata from OregonRFID readers

The metadata table does not have a column header. The columns are defined as such:

```
date, time, datetime, power, rx, tx, ea, charge, listen, temp, noise, site, manuf, srcfile, srcline, compdate
```

+ `date`: raw data collection datetime
+ `time`: raw data collection time
+ `datetime`: raw date and time
+ `power`: voltage received by the reader
+ `rx`:  charge amperage used
+ `tx`: listen amperage used
+ `ea`: average of charge and listen amperages over the minute
+ `charge`: field charge time (ms)
+ `listen`: listen time (ms)
+ `temp`: temperature inside datalogger (degrees Cel)
+ `noise`: number of noise detections over the minute
+ `site`: site or antenna where PIT tag data was collected
+ `manuf`: equipment manufacturer (ORFID or Biomark)
+ `srcfile`: the raw PIT tag data source file path
+ `srcline`: the raw PIT tag data source file line
+ `compdate`: the date this entry was compiled


**tagFailDB.csv**: these are tag readings where the tag id was not recorded correctly during scan

**tagBadDB.csv**: these are tag readings whose format is incorrect and parsing failed

**msgDB.csv**: these proper messages from the scanner system

**msgBadDB.csv**: these are messages from the scanner system that 

