# AntWrangler

Automated PIT tag antenna data cleaning tool for Oregon RFID and Biomark readers


## Instructions

### Get the files

Click the ***Clone or download button*** and select ***Download zip*** - a zipped directory containing all files will be downloaded.
Unzip the directory and move the folder to a script directory on your system.

#### The R files

There are three R files included:

+ **pit_tag_data_compile_functions.r**: a function file to be sourced in the *pit_tag_data_compile_run.r* file
+ **pit_tag_data_compile_run.r**: a file that runs the PIT tag data compiling program  
+ **pit_tag_data_explorer.r**: a script will a few plotting and summary utilities for exploring the compiled PIT tag data

We will come back to these files in a minute. First, you need to set up your data directory.

### Directory Setup

AntWrangler is expecting a certain directory structure so that it can find data files to parse, clean and incorporate, and then move them to an archive.

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
```

`site`: will hold the data files for an individual site. This will *not* be used for the site designation in the compilation data. Instead, site will come from the downloaded file name (see download below)

`archive`: is where files that have been parsed and incorporated into the compilation files will be moved to - the date of inclusion in the compliation files will be prepended to the original file name

`download` is where you should place data files that you want parsed and incorporated into the compilation files. 

***An important note:*** for OregonRFID data files, each file should be labeled with the site name first and followed with an underscore (i.e., BGS_nov21). The parser code will use the first entry of the file name (i.e., "BGS") as the site name in the compilation data. 

#### The example files

There is an ***example*** folder that contain all files needed to perform a test of the scripts.

```
\---example
	|
    +---BGS
    |   +---archive
    |   \---downloads
    |           BGS_nov21
    |
    +---RanchoSanCarlos
    |   +---archive
    |   \---downloads
    |           01_00006
```


### Running the program

Open the ***pit_tag_data_compile_run.r*** file in RStudio. This file is simply a helper for defining variables and 
calling the compiling program. To start, **four variables need to be defined:**

| Name | Type | Definition
| - | - | - |
| functionsPath | String, File path | The full system path to the ***pit_tag_data_compile_functions.r*** file
| dataDir | String, directory path | The full system path to the directory where the source log data exist - it should be the parent directory to all the site directories - 'sites' from the above directory structure example.
| dbDir | String, directory path | The full system path to the directory where the compiled log data base file exist or should be initially written to
| timeZone | String | The time zone for where the raw PIT tag data was collected. Use this to find your time zone: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

Alter the variable definitions to suit your needs and then run the script.


##### About the compiled data tables

There are seven compilation data tables that may be produced, depending on your data inputs. These data tables do not have column headers. See the code below to add column headers.

**logDB.csv**: this is a log file to document which data files were processed by the parser program and some details about those files. 

Here is my recommended way to open this file in RStudio with correct formatting and headers (copy and paste the code below). 

```R
#column names
logcolnames <- c("site", "manuf", "srcfile", "compdate", "tagnrow", "tagbadnrow", 
                 "metanrow", "metabadnrow", "msgnrow", "msgbadnrow", "othernrow", "totalnrow")

#read the file into R with correct column formats (see readr documentation here: https://readr.tidyverse.org/articles/readr.html)
read_csv(paste(dbDir,"/logDB.csv", sep=""), col_names=logcolnames, 
         col_types = cols(site="c", manuf="c", srcfile="c", compdate="D", 
                          tagnrow="i", tagbadnrow="i", metanrow="i", metabadnrow="i", msgnrow="i", 
                          msgbadnrow="i", othernrow="i", totalnrow="i") )
```
The fields are: 
+ `site`: the site or antenna name
+ `manuf`: the reader manufacturer (ORFID or Biomark)
+ `srcfile`: the raw PIT tag data source file path
+ `compdate`: the date this data file was compiled to the compilation files
d tag reads
+ `tagnrow`: the number of lines in raw data file that were good tag reads and were parsed correctly
+ `tagbadnrow`: the number of lines in raw data file that were bad tag reads and were not be parsed correctly
+ `metanrow`: the number of lines in raw data file that were meta data and parsed correctly
+ `metabadnrow`: the number of lines in raw data file that were bad meta data and were not be parsed correctly
+ `msgnrow`: the number of lines in raw data file that are good messages and were parsed correctly
+ `msgbadnrow`: the number of lines in raw data file that are bad tag reads and could not be parsed correctly
+ `othernrow`: the number of lines in raw data file that could not be parsed into either a tag, metadata or message 
+ `totalnrow`: the total number of lines in the raw data file
  
**tagDB.csv**: these are successful tag readings where data acquired from the reader is formatted correctly

Here is my recommended way to open this file in RStudio with correct formatting and headers 

```R
#column names
tagcolnames <- c("datetime", "fracsec", "duration", "tagtype", "tagid", "antnum", 
                 "consdetc", "arrint", "site", "manuf", "srcfile", "srcline", "compdate")

#read the file into R with correct column formats 
read_csv(paste(dbDir,"/tagDB.csv", sep=""), col_names=tagcolnames, col_types = cols(datetime=col_datetime(format = "%m/%d/%Y %H:%M"), 
                                                              fracsec="d", duration="d", tagtype="c", tagid="c",
                                                              antnum="i", consdetc="i", arrint="i", site="c", manuf="c",
                                                              srcfile="c", srcline="i", compdate=col_date(format = "%m/%d/%Y")))
```

+ `datetime`: raw date and time
+ `fracsec`: raw data collection fraction of a second for the time
+ `duration`: duration tag was in the field 
+ `tagtype`: tag type (A for ISO animal format, R for read-only, W for writeable tag; OregonRFID)
+ `tagid`: the PIT tag number
+ `antnum`: antenna number (multiple antenna reader only)
+ `consdetc`: consecutive detections count  + `arrint`: number of empty scans prior to the detection
+ `site`: site or antenna 
+ `manuf`: equipment manufacturer (ORFID or Biomark)
+ `srcfile`: the raw PIT tag data source file path
+ `srcline`: the raw PIT tag data source file line
+ `compdate`: the date this entry was compiled

**metaDB.csv**: these are metadata from OregonRFID readers

Here is my recommended way to open this file in RStudio with correct formatting and headers 

```R
#column names
metacolnames <- c("datetime", "power", "rx", "tx", "ea", "charge", "listen", 
                  "temp", "noise", "site", "manuf", "srcfile", "srcline", "compdate")

#read the file into R with correct column formats 
read_csv(paste(dbDir,"/metaDB.csv", sep=""), col_names=metacolnames, 
         col_types = cols(datetime=col_datetime(format = "%Y-%m-%d %H:%M:%S"), power="d", rx="d", tx="d", 
                          ea="d", charge="d", listen="d", temp="d", noise="i", site="c", manuf="c", 
                          srcfile="c", srcline="i", compdate=col_date(format = "%Y-%m-%d")))
```

+ `datetime`: raw date and time
+ `power`: voltage received by the reader
+ `rx`:  charge amperage 
+ `tx`: listen amperage 
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


**tagBadDB.csv**: these are tag readings where the tag id was not recorded correctly or there was some formatting error

**metaBadDB.csv**: these are metadata that were not formatted correctly. *Note: these include detections that occur when TeraTerm or whatever reader you use is open. These detections are also saved as tags in reader database, so we exclude them from tagDB.csv and instead parse them here.* **msgDB.csv**: these are messages from the reader

**msgBadDB.csv**: these are messages from the reader that were not formatted correctly

**otherDB.csv**: these are miscellaneous text that does not fit into any of the above categories.

Each of these files are formatted in the same way. Here is an example of my recommended way to open these files in RStudio with correct formatting and headers 

```R
#column names
badcolnames <- c("linecontent", "site", "manuf", "srcfile", "srcline", "compdate")

#read the file into R with correct column formats 
read_csv(paste(dbDir,"/tagbadDB.csv", sep=""), col_names=badcolnames, col_types = cols(linecontent="c", site="c",
                                                                                            manuf="c", srcfile="c", srcline="i", 
                                                                                            compdate=col_date(format = "%Y-%m-%d")))

 #read the file into R with correct column formats 
  read_csv(paste(dbDir,"/metabadDB.csv", sep=""), col_names=badcolnames, col_types = cols(linecontent="c", site="c",
                                                                                            manuf="c", srcfile="c", srcline="i", 
                                                                                            compdate=col_date(format = "%Y-%m-%d")))

  #read the file into R with correct column formats 
  read_csv(paste(dbDir,"/msgbadDB.csv", sep=""), col_names=badcolnames, col_types = cols(linecontent="c", site="c",
                                                                                             manuf="c", srcfile="c", srcline="i", 
                                                                                             compdate=col_date(format = "%Y-%m-%d")))

  #read the file into R with correct column formats 
  read_csv(paste(dbDir,"/otherDB.csv", sep=""), col_names=badcolnames, col_types = cols(linecontent="c", site="c",
                                                                                            manuf="c", srcfile="c", srcline="i", 
                                                                                            compdate=col_date(format = "%Y-%m-%d")))
 ```


