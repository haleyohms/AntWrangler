

#... check the tag data
tagcolnames <- c("datetime", "fracsec", "duration", "tagtype", "PITnum", 
                 "consdetc", "arrint", "site", "manuf", "srcfile", "srcline", "compdate")
dbDir<-"C:/Users/HaleyOhms/Documents/Carmel/Database/AntennaData"
tdat <- read_csv(paste(dbDir,"/tagDB.csv", sep=""), col_names=tagcolnames,
                 col_types = cols(datetime=col_datetime(format = ""),
                                  fracsec="d", duration="d", tagtype="c", PITnum="c",
                                  consdetc="i", arrint="i", site="c", manuf="c",
                                  srcfile="c", srcline="i", compdate=col_date(format = "%Y-%m-%d")))

#... CHECKS HERE, MAKE CHANGES BELOW

#... check for NAs
dateNAs <- tdat[is.na(tdat$datetime) , ]
siteNAs <- tdat[is.na(tdat$site) , ]
PITNAs <- tdat[is.na(tdat$PITnum) , ]


#...check for odd ball site names
unique(tdat$site)

#... check for correct years 
tyr <- tdat %>%
  mutate(year = year(datetime)) %>%
  group_by(site, year) %>%
  summarise(n())

tmin <- tdat %>% 
  mutate(date = date(datetime), hour = hour(datetime)) %>% 
  group_by(PITnum, site, date, hour) %>% 
  filter(PITnum == min(PITnum)) %>% 
  slice(1) %>% # takes the first occurrence if there is a tie
  ungroup()

odays<-ggplot(tmin, aes(datetime,site))+geom_point()+geom_jitter()
# odays<-ggplot(tmin, aes(datetime,site))+geom_point()+geom_jitter()+
#   scale_x_datetime(limits = c(ymd_hm("2018-01-01 00:00","2019-05-01 00:00")))+
#   labs(x = "Date", y = "Site")
odays



########################################################
# TagDB edits
########################################################

################################################################################################
# May 13, 2019
#... Clean up site names
tdat$site[which(tdat$site=="scarlett")] <- "SCAR"
tdat$site[which(tdat$site=="scarlett1")] <- "SCAR1"
tdat$site[which(tdat$site=="scarlett2")] <- "SCAR2"
tdat$site[which(tdat$site=="sh1")] <- "SH1"
tdat$site[which(tdat$site=="sh2")] <- "SH2"
tdat$site[which(tdat$site=="tALPsolo")] <- "ALPsolo"

## BLP date format incorrectly says 2018
tdat$datetime[which(tdat$site=="BLP" & tdat$datetime<"2018-07-01 00:00")] <- 
  tdat$datetime[which(tdat$site=="BLP" & tdat$datetime<"2018-07-01 00:00")] + years(x=1) 

#... BGS_March27 was incorrectly labeled, should have been BGSC
badFilePath = "C:\\Users\\HaleyOhms\\Documents\\Carmel\\ArrayData\\BGS\\archive\\2019-05-11_BGS_March27"	
tdat$site[which(tdat$srcfile==badFilePath)] <- "BGSC"
newFilePath = "C:\\Users\\HaleyOhms\\Documents\\Carmel\\ArrayData\\BGSC\\archive\\2019-05-11_BGSC_March27"
tdat$srcfile[which(tdat$srcfile==badFilePath)] <- newFilePath

#... Deal with some funky years
tdat <- tdat[!year(tdat$datetime)=="2027" , ] #delete these
tdat <- tdat[!year(tdat$datetime)=="2026" , ] #delete these
tdat <- tdat[!year(tdat$datetime)=="2036" , ] #delete these
tdat <- tdat[!year(tdat$datetime)=="2037" , ] #delete these
tdat <- tdat[!year(tdat$datetime)=="2012" , ] #delete these
tdat <- tdat[!year(tdat$datetime)=="2014" , ] #delete these
tdat <- tdat[!(tdat$site=="SH1" & year(tdat$datetime)=="2016") , ] 
tdat <- tdat[!(tdat$site=="SH1" & year(tdat$datetime)=="2017") , ] 
tdat <- tdat[!(tdat$site=="BLP" & year(tdat$datetime)=="2014") , ] 
tdat <- tdat[!(tdat$site=="ALPsolo" & tdat$datetime<"2018-07-01 00:00") , ] 
tdat <- tdat[!(tdat$site=="RSC" & tdat$datetime<"2017-07-01 00:00") , ] 
tdat <- tdat[!(tdat$site=="RSC" & year(tdat$datetime)>"2018") , ]

tdat$datetime[year(tdat$datetime)=="2010"] <- 
  tdat$datetime[year(tdat$datetime)=="2010"] + years(x=8) #test tags at BGS, change year from 2010 to 2018 (I think this is correct)
#NOPE, I was wrong. Delete these:
tdat<-tdat[!(tdat$site=="BGS" & tdat$datetime<"2018-07-01 00:00:00") , ] 

junkfile = "C:\\Users\\HaleyOhms\\Documents\\Carmel\\ArrayData\\BGS\\archive\\2019-05-11_BGS_March27_all"	
tdat <- tdat[!(tdat$srcfile==junkfile & year(tdat$datetime)<"2019") , ] #remove data left on reader prior to install

tdat$datetime[which(tdat$site=="CAWD1" & year(tdat$datetime)>"2019")] <- 
  tdat$datetime[which(tdat$site=="CAWD1" & year(tdat$datetime)>"2019")] - years(x=7) #couldn't set date to 2018, so set to 2025

tdat$datetime[which(tdat$site=="CAWD2" & year(tdat$datetime)>"2019")] <- 
  tdat$datetime[which(tdat$site=="CAWD2" & year(tdat$datetime)>"2019")] - years(x=7) #couldn't set date to 2018, so set to 2025

sh<-tdat[(tdat$site=="SH1"  & year(tdat$datetime)=="2014") , ]
max(sh$datetime)

#... Add in RSC Biomark data
## Add in Rancho San Carlos
tagcolnames_rsc <- c("datetime", "fracsec", "duration", "tagtype", "PITnum", "antnum", 
                     "consdetc", "arrint", "site", "manuf", "srcfile", "srcline", "compdate")
dbDir_rsc<-"C:/Users/HaleyOhms/Documents/Carmel/ArrayData/RSC_Biomark/CompiledData"
tdat_rsc <- read_csv(paste(dbDir_rsc,"/tagDB.csv", sep=""), col_names=tagcolnames_rsc,
                     col_types = cols(datetime=col_datetime(format = "%Y-%m-%d %H:%M:%S"),
                                      fracsec="d", duration="d", tagtype="c", PITnum="c",
                                      antnum = "i",
                                      consdetc="i", arrint="i", site="c", manuf="c",
                                      srcfile="c", srcline="i", compdate=col_date(format = "%Y-%m-%d")))

tdat_rsc$antnum<-NULL  ## Remove antnum

## Merge tdat and tdat_rsc
tdat<-rbind(tdat, tdat_rsc)


write_csv(tdat, path="C:/Users/HaleyOhms/Documents/Carmel/Database/AntennaData/tagDB.csv", col_names=F)
################################################################################################

########################################################
# metaDB_OR edits
########################################################
metaORcolNames <- c("datetime", "power", "rx", "tx", "ea", "charge", "listen", 
                  "temp", "noise", "site", "manuf", "srcfile", "srcline", "compdate")
mdat_OR<- read_csv(paste(dbDir,"/metaDB_OR.csv", sep=""), col_names = metacolnames, 
                col_types = cols(datetime = col_datetime(format = ""),
                                 power = "d", rx = "d", tx = "d", ea = "d", charge = "d", 
                                 listen = "d", temp = "d", noise = "d", site = "c",
                                 manuf = "c", srcfile = "c", srcline = "d",
                                 compdate = col_date(format = "")))

##########################################################
# May 13, 2019
#... Clean up site names
unique(mdat_OR$site)
mdat_OR$site[which(mdat_OR$site=="scarlett")] <- "SCAR"
mdat_OR$site[which(mdat_OR$site=="scarlett1")] <- "SCAR1"
mdat_OR$site[which(mdat_OR$site=="scarlett2")] <- "SCAR2"
mdat_OR$site[which(mdat_OR$site=="sh1")] <- "SH1"
mdat_OR$site[which(mdat_OR$site=="sh2")] <- "SH2"
mdat_OR$site[which(mdat_OR$site=="tALPsolo")] <- "ALPsolo"

write_csv(mdat_OR, path="C:/Users/HaleyOhms/Documents/Carmel/Database/AntennaData/metaDB_OR.csv", col_names=F)


########################################################
# metaDB_BM edits
########################################################
metaBMcolNames <- c("date", "time", "OpMo", "NMo", 
"EMo", "Sync", "ExVL", "TunP", "Caps", "TMem", "SMem",
"InV", "ExV", "AA", "FDXsig", "TPh", "Temp", "A1", "A2", 
"A3", "A4", "A5", "site", "manuf", "srcfile", "srcline", "compdate")
  
mdat_BM<- read_csv(paste(dbDir,"/metaDB_BM.csv", sep=""), col_names = metaBMcolNames)

################################################################################################
# May 13, 2019 changes
#... BLP date format incorrectly says 2018
mdat_BM$date[which(mdat_BM$site=="BLP" & mdat_BM$date<"2018-07-01")] <- 
  mdat_BM$date[which(mdat_BM$site=="BLP" & mdat_BM$date<"2018-07-01")] + years(x=1) 

#... BGS_March27 was incorrectly labeled, should have been BGSC
badFilePath = "C:\\Users\\HaleyOhms\\Documents\\Carmel\\ArrayData\\BGS\\archive\\2019-05-11_BGS_March27"	
mdat_BM$site[which(mdat_BM$srcfile==badFilePath)] <- "BGSC"
newFilePath = "C:\\Users\\HaleyOhms\\Documents\\Carmel\\ArrayData\\BGSC\\archive\\2019-05-11_BGSC_March27"
mdat_BM$srcfile[which(mdat_BM$srcfile==badFilePath)] <- newFilePath

write_csv(mdat_BM, path="C:/Users/HaleyOhms/Documents/Carmel/Database/AntennaData/metaDB_BM.csv", col_names=F)
################################################################################################


#... Test if duplicates is working

tagcolnames <- c("datetime", "fracsec", "duration", "tagtype", "PITnum", 
                 "consdetc", "arrint", "site", "manuf", "srcfile", "srcline", "compdate")
dbDir<-"C:/Users/HaleyOhms/Documents/Carmel/Database"
mDups <- read_csv(paste(dbDir,"/tagDB_mDups.csv", sep=""), col_names=tagcolnames,
                 col_types = cols(datetime=col_datetime(format = ""),
                                  fracsec="d", duration="d", tagtype="c", PITnum="c",
                                  consdetc="i", arrint="i", site="c", manuf="c",
                                  srcfile="c", srcline="i", compdate=col_date(format = "%Y-%m-%d")))

theDups <- read_csv(paste(dbDir,"/tagDupsTest.csv", sep=""), col_names=tagcolnames,
                  col_types = cols(datetime=col_datetime(format = ""),
                                   fracsec="d", duration="d", tagtype="c", PITnum="c",
                                   consdetc="i", arrint="i", site="c", manuf="c",
                                   srcfile="c", srcline="i", compdate=col_date(format = "%Y-%m-%d")))


theDups<-distinct(theDups, datetime, fracsec, duration, tagtype, PITnum, consdetc, arrint, site, manuf)
theDups1<-distinct(theDups, datetime, fracsec, duration, tagtype, PITnum, consdetc, arrint, site, manuf, .keep_all = T)

t<-names(theDups)

mDupsTest<-distinct(mDups, datetime, fracsec, duration, tagtype, PITnum, consdetc, arrint, site, manuf)

as.character(expression(datetime, fracsec, duration, tagtype, PITnum, consdetc, arrint, site, manuf))

anti_join(theDups, mDups, by="datetime","fracsec","duration",
          "tagtype", "PITnum","consdetc", "arrint", "site","manuf")

cs = c(datetime, fracsec, duration, tagtype, PITnum, consdetc, arrint, site, manuf)







###########################################################