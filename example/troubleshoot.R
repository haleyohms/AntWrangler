
tagcolnames <- c("datetime", "fracsec", "duration", "tagtype", "PITnum", 
                 "consdetc", "arrint", "site", "manuf", "srcfile", "srcline", "compdate")
dbDir<-"C:/Users/HaleyOhms/Documents/Carmel/Database/AntennaData"
tdat <- read_csv(paste(dbDir,"/tagDB.csv", sep=""), col_names=tagcolnames,
                 col_types = cols(datetime=col_datetime(),
                                  fracsec="d", duration="d", tagtype="c", PITnum="c",
                                  consdetc="i", arrint="i", site="c", manuf="c",
                                  srcfile="c", srcline="i", compdate=col_date(format = "%Y-%m-%d")))


tdat2<-tdat[!duplicated(tdat), ]

probs<-tdat2[is.na(tdat2$srcline) , ]
unique(date(probs$datetime))


tdat2tprob<-tdat[which(hour(tdat$datetime)=="0" & minute(tdat$datetime)=="0" & second(tdat$datetime)=="0" ) , ]
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
unique(tdat$PITnum)
  which(is.na(time(tdat$datetime))==F)
  
  
  
head(tagDataDF)
  unique(date(tagDataDF$datetime))
  unique(hour(tagDataDF$datetime))
  unique(minute(tagDataDF$datetime))
  which(is.na(hour(tagDataDF$datetime))==T)

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


x<-"6,0,1,2,5,2,188,0,7,238,199,60,3,386,253,0,0,0,0,0"
x2<-strsplit(x, ",")
x2[1]
x3<-as.numeric(unlist(strsplit(x, ",")))
x3[1]
str(x)





