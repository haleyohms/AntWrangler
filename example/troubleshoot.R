
tagcolnames <- c("datetime", "fracsec", "duration", "tagtype", "PITnum", 
                 "consdetc", "arrint", "site", "manuf", "srcfile", "srcline", "compdate")
dbDir<-"C:/Users/HaleyOhms/Documents/Carmel/Database/AntennaData"
tdat <- read_csv(paste(dbDir,"/tagDB.csv", sep=""), col_names=tagcolnames,
                 col_types = cols(datetime=col_datetime(format = "%Y-%m-%d %H:%M:%S"),
                                  fracsec="d", duration="d", tagtype="c", PITnum="c",
                                  consdetc="i", arrint="i", site="c", manuf="c",
                                  srcfile="c", srcline="i", compdate=col_date(format = "%Y-%m-%d")))

tprob<-tdat[which(hour(tdat$datetime)=="0" & minute(tdat$datetime)=="0" & second(tdat$datetime)=="0" ) , ]
head(tprob$srcfile)

#########################
### Test data
##### Tag data
tagcolnames <- c("datetime", "fracsec", "duration", "tagtype", "PITnum", 
                 "consdetc", "arrint", "site", "manuf", "srcfile", "srcline", "compdate")
dbDir<-"C:/Users/HaleyOhms/Documents/GitHub/AntWrangler/example"
tdat <- read_csv(paste(dbDir,"/tagDB.csv", sep=""), col_names=tagcolnames,
                 col_types = cols(datetime=col_datetime(format = ""),
                                  fracsec="d", duration="d", tagtype="c", PITnum="c",
                                  consdetc="i", arrint="i", site="c", manuf="c",
                                  srcfile="c", srcline="i", compdate=col_date(format = "%Y-%m-%d")))
head(tdat)
unique(tdat$compdate)
unique(date(tdat$datetime))
unique(time(tdat$datetime))
  which(is.na(time(tdat$datetime))==F)
  
  
  
  op <- options(digits.secs=2)
  dmy_hms("20/2/06 11:16:16.683")
  dmy_hm("20/2/06 11:16")
  options(op)
?options()
  

##### Meta data
  metacolnames <- c("datetime", "power", "rx", "tx", "ea", "charge", "listen", 
                    "temp", "noise", "site", "manuf", "srcfile", "srcline", "compdate")
  mdat<- read_csv(paste(dbDir,"/metaDB.csv", sep=""), col_names = metacolnames)
  head(mdat)
  unique(mdat$compdate)
  unique(date(mdat$datetime))
  unique(time(mdat$datetime))
  which(is.na(time(mdat$datetime))==T)
  
  
  tdat[which(is.na(tdat$datetime)) , ]
tprob<-tdat[which(hour(tdat$datetime)=="0" & minute(tdat$datetime)=="0" ) , ]
tprob<-tdat[which(hour(tdat$datetime)=="0" & minute(tdat$datetime)=="0" & second(tdat$datetime)=="0" ) , ]

tprob<-tdat[which(hour(tdat$datetime)=="0" & minute(tdat$datetime)=="0" & second(tdat$datetime)=="0" ) , ]
head(tprob$srcfile)