

#... check the tag data
tagcolnames <- c("datetime", "fracsec", "duration", "tagtype", "PITnum", 
                 "consdetc", "arrint", "site", "manuf", "srcfile", "srcline", "compdate")
dbDir<-"C:/Users/HaleyOhms/Documents/Carmel/Database/AntennaData"
tdat <- read_csv(paste(dbDir,"/tagDB.csv", sep=""), col_names=tagcolnames,
                 col_types = cols(datetime=col_datetime(format = ""),
                                  fracsec="d", duration="d", tagtype="c", PITnum="c",
                                  consdetc="i", arrint="i", site="c", manuf="c",
                                  srcfile="c", srcline="i", compdate=col_date(format = "%Y-%m-%d")))

head(tdat)


#... remove duplicates
#tdat2<-tdat[!duplicated(tdat),]
tdat3<-tdat[!duplicated(dplyr::select(tdat, -srcfile, -srcline, -compdate)),]  

?duplicated()
















#... check the meta data
metacolnames <- c("datetime", "power", "rx", "tx", "ea", "charge", "listen", 
                  "temp", "noise", "site", "manuf", "srcfile", "srcline", "compdate")
mdat<- read_csv(paste(dbDir,"/metaDB_OR.csv", sep=""), col_names = metacolnames, 
               col_types = cols(datetime = col_datetime(format = ""),
                  power = "d", rx = "d", tx = "d", ea = "d", charge = "d", 
                  listen = "d", temp = "d", noise = "d", site = "c",
                  manuf = "c", srcfile = "c", srcline = "d",
                  compdate = col_date(format = "")))
                
                
head(mdat)

#... remove duplicates
mdat2<-mdat[!duplicated(mdat),]



## 5/11/19 changes
  # BGS from Dec 20 to Jan 3 did not read properly
    probs<-tdat[is.na(tdat$srcline) , ]
    unique(date(probs$datetime))
    unique(probs$arrint)
    
    #... remove the problems, save file, and recompile
    tdat<-tdat[!is.na(tdat$srcline) , ]
    
    write.csv(tdat,"C:/Users/HaleyOhms/Documents/Carmel/Database/AntennaData/tagDB.csv")
