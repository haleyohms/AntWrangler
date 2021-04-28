# AntWrangler

AntWrangler is a tool to parse, organize, and clean PIT tag antenna data prior to analysis. It handles single (non multiplexed) Oregon RFID and Biomark IS1001 readers.
AntWrangler is designed as an automated tool, so there is no need to manually edit out headers or commands in the raw data, or combine raw files. 
One simply points AntWrangler to the raw data directories and lets it do the work. 

## Supported data formats 
AntWrangler currently works with two Oregon RFID data formats and one Biomark format. Only data formats from single reader sites are currently supported. 

The ORFID formats include data from single readers prior to \2018 and the new readers that came out in \2018. The 'old style' data format looks like this:

```
Oregon RFID Datalogger Version 5.06  
2018-12-03 15:38:26.00

>supply power ok 13.0V
database file opened
starting reader after power up
up
Upload #4
Reader: 2018-07-011  Site: BYP
--------- upload 4 start ---------
E 2018-11-28 11:47:06.00 upload 3 complete
D 2018-11-28 11:47:43.13 00:00:00.80 HW 0000_0000000000001283    9   496
D 2018-11-28 11:50:42.15 00:00:00.10 HW 0000_0000000000001283    2  1768
D 2018-11-28 11:50:42.45 00:00:00.10 HW 0000_0000000000001283    2     1
D 2018-11-28 11:50:42.75 00:00:00.20 HW 0000_0000000000001283    3     1
D 2018-11-28 11:53:41.14 00:00:00.80 HW 0000_0000000000001283    9  1768
--------- upload 4 done ---------
2563 records

>ut4
                supply  RX    TX    EA  charge/listen Temp noise
2018-11-28 11:47 13.4V 0.15A 0.69A 0.42A  50ms/ 50ms  26C  0N
2018-11-28 11:48 13.3V 0.13A 0.68A 0.40A  49ms/ 50ms  26C  0N
2018-11-28 11:49 13.3V 0.13A 0.67A 0.39A  49ms/ 50ms  26C  0N
2018-11-28 11:50 13.3V 0.13A 0.67A 0.39A  49ms/ 50ms  26C  2N
----------- end of time records #4 ----------

```

The 'new style' readers can be customized to for a variety of data formats. We programmed ours to 
look as similar to the 'old style' format as possible.

```
up
Reader: RSC downstream  Site: AAA
--------- Upload #7, 2631 records ---------
DTY          ARR                 DUR       TCHTTY         TAG           NCD     EMP 
E  2019-09-17 10:56:48.553 G End of upload #6
S  2019-09-17 11:46:54.400    00:00:00.100 HDX  W  0000_000000000881        2     0 
S  2019-09-17 12:17:36.500    00:00:00.100 HDX  W  0000_000000000881        2     0 
S  2019-09-17 12:48:18.700    00:00:00.100 HDX  W  0000_000000000881        2     0 
S  2019-09-17 13:19:00.800    00:00:00.100 HDX  W  0000_000000000881        2     0 

```


The supported Biomark data format looks like this: 
```
med
INF: Tags Download Started
*TAG: 01 03/20/2020 13:13:22.130 999.000000007425
*TAG: 01 03/20/2020 14:13:22.130 999.000000007425
*TAG: 01 03/20/2020 15:13:22.140 999.000000007425
TAG: 01 03/26/2020 08:28:47.690 900.226001118697
INF: Status Reports Download Started
*SRP: 01 03/20/2020 13:13:32.100 16,0,0,2,5,4,92,0,0,267,200,26,33,391,345,0,0,0,0,0
*SRP: 01 03/20/2020 14:13:32.100 16,0,0,2,5,0,93,0,0,267,200,26,22,395,335,0,0,0,0,0
*SRP: 01 03/20/2020 15:13:32.100 16,0,0,2,5,0,97,0,0,267,199,26,30,395,330,0,0,0,0,0
*SRP: 01 03/20/2020 16:13:32.100 16,0,0,2,5,0,95,0,0,267,200,26,22,395,319,0,0,0,0,0
MSG: 01 03/26/2020 02:40:49.760 Set Caps = 84, I = 2.3 A, PH = 403, dPH = -8
MSG: 01 03/26/2020 02:40:53.970 Set Caps = 83, I = 2.3 A, PH = 407, dPH = -12
MSG: 01 03/26/2020 02:41:29.150 Set Caps = 82, I = 2.3 A, PH = 404, dPH = -9

```

Note that all of the commands, intro text, and other miscellaneous text in the raw files does not need to be deleted prior to processing. 
Similarly, the metadata lines and message lines do not need to be separated from the tag lines. 
AntWrangler will parse everything into separate files.


## Instructions

### Get the code from GitHub

To get the R code from GitHub, click the ***Clone or download button*** and select ***Download zip***. A zipped directory containing all files will be downloaded.
Unzip the directory and move the folder to a script directory on your system.

#### The R files

There are three R files included in the GitHub download:

+ **pit_tag_data_compile_functions.r**: a function file to be sourced in the *pit_tag_data_compile_run.r* file
+ **pit_tag_data_compile_run.r**: a file that runs the PIT tag data compiling program  
+ **pit_tag_data_explorer.r**: a script will a few plotting and summary utilities for exploring the compiled PIT tag data

We will come back to these files in a minute. First, you need to set up your data directory.

### Directory Setup

AntWrangler is expecting a certain directory structure on your computer so that it can find data files to parse, clean and incorporate, and then move them to an archive.

Here is the directory structure you need to create on your computer:

```
\---sites
	|
    +---siteX
    |   +---archive
    |   \---downloads
    |
    +---siteY
    |   +---archive
    |   \---downloads
```

`sitei`: will hold the data files for an individual site. 

`archive`: is where files that have been parsed and incorporated into the compilation files will be moved to. 
The date of inclusion in the compliation files will be prepended to the original file name. 

`downloads` is where you should place data files that you want parsed and incorporated into the compilation files. 



#### The example files

There is an ***example*** folder that contain all files needed to perform a test of the scripts.

```
\---example
	|
    +---SiteORFID
    |   +---archive
    |   \---downloads
    |           BGS_Dec3
	|			RSC_July9
    |
    +---SiteBiomark
	|   +---archive
    |   \---downloads
    |           01_00006
```

***An important note on site names:*** 
Site names are not consistenly included in the raw data files for either ORFID or Biomark. 
As a result, we assign the `site` field in the compiled data based on the names in the file structures.

For ORFID data, `site` is the name preceeding the underscore of each raw data file. 
In the example above, `site` in the compiled data is BGS.

For Biomark data, `site` is the name of the data folder. In the example above, `site` in the compiled data is SiteBiomark.
The reason for the difference is because when Biomark data is saved to a USB, each day is saved as a separate file with the format like the example. 
Rather than renaming all of those files, we assign `site` based on the folder name. 



### Running the program

Open the ***pit_tag_data_compile_run.r*** file in RStudio. This file is simply a helper for defining variables and 
calling the compiling program. To start, **three variables need to be defined:**

| Name | Type | Definition
| - | - | - |
| functionsPath | String, File path | The full system path to the ***pit_tag_data_compile_functions.r*** file
| dataDir | String, directory path | The full system path to the directory where the source log data exist - it should be the parent directory to all the site directories - 'sites' from the above directory structure example.
| dbDir | String, directory path | The full system path to the directory where the compiled log data base file exist or should be initially written to


Alter the variable definitions to suit your needs and then run the script.


##### About the compiled data tables

There are nine compilation data tables that may be produced, depending on your data inputs. These data tables do not have column headers, 
but you can add them with the code below. 

**logDB.csv**: this is a log file to document which data files were processed by the parser program and some details about those files. 

Here is my recommended way to open this file in RStudio with correct formatting and headers (copy and paste the code below). 

```R
#column names
logcolnames <- c("site", "manuf", "srcfile", "compdate", "tagnrow", "tagbadnrow", 
                 "metanrow_OR", "metanrow_BM", "metabadnrow", "msgnrow", "msgbadnrow", "othernrow", "totalnrow")

#read the file into R with correct column formats (see readr documentation here: https://readr.tidyverse.org/articles/readr.html)
logdat <- read_csv(paste(dbDir,"/logDB.csv", sep=""), col_names=logcolnames, 
         col_types = cols(site="c", manuf="c", srcfile="c", compdate="D", 
                          tagnrow="i", tagbadnrow="i", metanrow_OR="i", metanrow_BM="i", 
                          metabadnrow="i", msgnrow="i", 
                          msgbadnrow="i", othernrow="i", totalnrow="i") )

```
The fields are: 
+ `site`: the site or antenna name
+ `manuf`: the reader manufacturer (ORFID or Biomark)
+ `srcfile`: the raw PIT tag data source file path
+ `compdate`: the date this data file was compiled to the compilation files
+ `tagnrow`: the number of lines in raw data file that were good tag reads and were parsed correctly
+ `tagbadnrow`: the number of lines in raw data file that were bad tag reads and were not be parsed correctly
+ `metanrow_OR`: the number of lines in raw data file that were meta data from OregonRFID equipment and parsed correctly
+ `metanrow_OR`: the number of lines in raw data file that were meta data from Biomark 1S1001 standalone reader and parsed correctly
+ `metabadnrow`: the number of lines in raw data file that were bad meta data and were not be parsed correctly
+ `msgnrow`: the number of lines in raw data file that are good messages and were parsed correctly
+ `msgbadnrow`: the number of lines in raw data file that are bad tag reads and could not be parsed correctly
+ `othernrow`: the number of lines in raw data file that could not be parsed into either a tag, metadata or message 
+ `totalnrow`: the total number of lines in the raw data file
  
**tagDB.csv**: these are successful tag readings where data acquired from the reader is formatted correctly. 
For ORFID data, only tags that are numeric and have the prefixes "000", "900", "982", "985", and "999" will make it into tagdb.
All other tag lines (including hexadecimal formatted tags) will go to the tagbadDB. 

There are fewer conditions on tags that go to tagDB for Biomark data. Both decimal and hexadecimal (i.e., both numeric and alpha characters) 
are allowed and there are no prefix conditions. Any non-alpha or numeric characters in the tag will go to tagBadDB. 


Here is my recommended way to open this file in RStudio with correct formatting and headers 

```R
#column names
tagcolnames <- c("datetime", "fracsec", "duration", "tagtype", "PITnum", 
                 "consdetc", "arrint", "site", "manuf", "srcfile", "srcline", "compdate")

#read the file into R with correct column formats 
tdat <- read_csv(paste(dbDir,"/tagDB.csv", sep=""), col_names=tagcolnames,
                 col_types = cols(datetime=col_datetime(format = ""),
                                  fracsec="d", duration="d", tagtype="c", PITnum="c",
                                  consdetc="i", arrint="i", site="c", manuf="c",
                                  srcfile="c", srcline="i", compdate=col_date(format = "%Y-%m-%d")))
```


+ `datetime`: raw date and time
+ `fracsec`: raw data collection fraction of a second for the time
+ `duration`: duration tag was in the field 
+ `tagtype`: tag type (A for ISO animal format, R for read-only, W for writeable tag; OregonRFID)
+ `PITnum`: the PIT tag number
+ `consdetc`: consecutive detections count  
+ `arrint`: number of empty scans prior to the detection
+ `site`: site name 
+ `manuf`: equipment manufacturer (ORFID or Biomark)
+ `srcfile`: the raw PIT tag data source file path
+ `srcline`: the raw PIT tag data source file line
+ `compdate`: the date this entry was compiled

***Note***: if you open tagDB.csv in excel, the PITnum column will be a 
'general' format and will display the tag numbers in scientific notation (i.e., 435 x 10^16). If you 
change the tag column to 'number' format, excel will display the full tag number.
Excel is not my recommended way to view tagDB.csv, or any of the output files. I recommend directly importing into R, or using Notepad++.

**metaDB_OR.csv**: these are metadata from OregonRFID readers

Here is my recommended way to open this file in RStudio with correct formatting and headers 

```R
#column names
metaORcolNames <- c("datetime", "power", "rx", "tx", "ea", "charge", "listen", 
                  "temp", "noise", "site", "manuf", "srcfile", "srcline", "compdate")
				  
#read the file into R with correct column formats 
mdat_OR<- read_csv(paste(dbDir,"/metaDB_OR.csv", sep=""), col_names = metaORcolNames, 
                col_types = cols(datetime = col_datetime(format = ""),
                                 power = "d", rx = "d", tx = "d", ea = "d", charge = "d", 
                                 listen = "d", temp = "d", noise = "d", site = "c",
                                 manuf = "c", srcfile = "c", srcline = "d",
                                 compdate = col_date(format = "")))
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
+ `site`: site name
+ `manuf`: equipment manufacturer (ORFID or Biomark)
+ `srcfile`: the raw PIT tag data source file path
+ `srcline`: the raw PIT tag data source file line
+ `compdate`: the date this entry was compiled


**metaDB_BM.csv**: these are metadata from Biomark 1S1001 individual readers
```R
#column names
metaBMcolNames <- c("date", "time", "OpMo", "NMo", 
"EMo", "Sync", "ExVL", "TunP", "Caps", "TMem", "SMem",
"InV", "ExV", "AA", "FDXsig", "TPh", "Temp", "A1", "A2", 
"A3", "A4", "A5", "site", "manuf", "srcfile", "srcline", "compdate")
  
mdat_BM<- read_csv(paste(dbDir,"/metaDB_BM.csv", sep=""), col_names = metaBMcolNames)
```
These fields are also described in the Biomark 1S1001 standalone manual, page 49 

+ `date`: raw date 
+ `time`: raw time
+ `OpMo`: reader operation mode
+ `NMo`: reader network mode
+ `EMo`: reader exciter sync mode
+ `Sync`: sync input status
+ `ExVL`: exciter voltage level
+ `TunP`: tuning relative phase
+ `Caps`: tuning capacitors
+ `TMem`: tag memory usage
+ `SMem`: status report memory usage
+ `InV`: input voltage
+ `ExV`: exciter voltage
+ `AA`: antenna current 
+ `FDXsig`: FDX-B signal level
+ `Tph`: tuning phase
+ `Temp`: reader temperature
+ `A1` to `A5`: last 5 alarms
+ `site`: site name
+ `manuf`: equipment manufacturer (ORFID or Biomark)
+ `srcfile`: the raw PIT tag data source file path
+ `srcline`: the raw PIT tag data source file line
+ `compdate`: the date this entry was compiled




**tagBadDB.csv**: these are tag readings where the tag id was not recorded correctly or there was some formatting error

**metaBadDB.csv**: these are metadata that were not formatted correctly. *Note: these include detections that occur when TeraTerm or whatever reader you use is open. These detections are also saved as tags in reader database, so we exclude them from tagDB.csv and instead parse them here.* **msgDB.csv**: these are messages from the reader

**msgDB.csv**: these are messages from the reader 

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


