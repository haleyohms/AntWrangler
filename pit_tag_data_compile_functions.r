library(tidyverse)
library(lubridate)
readr.show_progress = F

### TESTING JUNK
#logFile = logFiles[1]
# logFile="C:/Users/HaleyOhms/Documents/GitHub/AntWrangler/example/NewORFIDformat/RSC_Downstream_20190719"
# archiveDir="C:/Users/HaleyOhms/Documents/GitHub/AntWrangler/example/NewORFIDformat"
# dbDir="C:/Users/HaleyOhms/Documents/GitHub/AntWrangler/example/NewORFIDformat"
# 
# logFile="C:/Users/HaleyOhms/Documents/GitHub/AntWrangler/NewFormTest/RSC/downloads/RSCDS_test2"
# dbDir="C:/Users/HaleyOhms/Documents/GitHub/AntWrangler/NewFormTest/RSC"
# archiveDir="C:/Users/HaleyOhms/Documents/GitHub/AntWrangler/NewFormTest/RSC"

# logFile = "C:/Users/HaleyOhms/Documents/Carmel/Code_notGit/BiomarkFormatTest_Feb2022/LT/downloads/LT_test"
# dbDir = "C:/Users/HaleyOhms/Documents/Carmel/Code_notGit/BiomarkFormatTest_Feb2022"
# archiveDir ="C:/Users/HaleyOhms/Documents/Carmel/Code_notGit/BiomarkFormatTest_Feb2022"
####################


getDate = function(dateChunk='thisisafillerdate'){
  #dateChunk = "03/03/2018"
  
  test = try(if(nchar(dateChunk)==10){'fail?'}) #, silent=T
  if(class(test) == "try-error"){return(NA)}
  
  if(nchar(dateChunk) == 10){ #10
    tryTheseFormats = c('%m-%d-%Y',
                        '%m/%d/%Y', 
                        '%Y-%m-%d', 
                        '%Y/%m/%d')
  } else{
    tryTheseFormats = c('%m/%d/%y',
                        '%m-%d-%y',
                        '%y/%m/%d',
                        '%y-%m-%d')
  }
  
  match=F
  i=0
  while(!match && i<length(tryTheseFormats)){
    i = i+1
    date = as.Date(dateChunk, format=tryTheseFormats[i])
    match = !is.na(date)
  }
  
  return(date)
}

spaceDelim = function(lines){
  dataLines = sub("\t", " ", lines) %>%
    sub("ms/", " ", .) %>%   #dot is the output from the previous pipe
    sub("ms", " ", .) %>%
    str_squish() %>%
    str_split(' ')
  return(dataLines)
}

commaDelim = function(lines){
  dataLines = sub("\t", ",", lines) %>%
    str_squish() %>%
    str_split(',')
  return(dataLines)
}

## Tells lubridate to include decimal seconds. Current settings are for no decimal seconds
#options(digits.secs=2)

makeORFIDtagDF = function(tagDataDF){
  date = as.Date(tagDataDF[,2])
  time = as.character(tagDataDF[,3])
  datetime = ymd_hms(paste(date, time), truncated = 3)
  #datetime = strftime(paste(date, time),format='%Y-%m-%d %H:%M:%S', tz=tz, usetz=FALSE)
  #datetime = strptime(paste(date, time),format='%Y-%m-%d %H:%M:%S', tz=tz)
  fracsec = round(as.numeric(str_sub(time, 9, 11)), 2)
  duration = period_to_seconds(hms(tagDataDF[,4]))
  tagtype = as.character(tagDataDF[,5])
  tagid = as.character(sub("_","",tagDataDF[,6]))
  consdetc = as.numeric(tagDataDF[,7])
  arrint = as.character(tagDataDF[,8])
  arrint[arrint == '.'] = '65001'
  arrint = as.numeric(arrint)

  return(data.frame(datetime, fracsec, duration, tagtype, tagid, consdetc, arrint, stringsAsFactors = F))
}

makeORFIDmetaDF = function(metaDataDF){ 
  #print(metaDataDF[,1])
  date = as.Date(metaDataDF[,1])
  time = as.character(metaDataDF[,2])
  datetime = ymd_hm(paste(date, time))
  #datetime = strftime(paste(date, time),format='%Y-%m-%d %H:%M:%S', tz=tz, usetz=FALSE)
  #datetime = strptime(paste(date, time),format='%Y-%m-%d %H:%M', tz=tz)
  power = as.numeric(sub("V", "", metaDataDF[,3]))  
  rx = as.numeric(sub("A", "",metaDataDF[,4]))
  tx = as.numeric(sub("A", "",metaDataDF[,5]))
  ea = as.numeric(sub("A", "",metaDataDF[,6]))
  charge = as.numeric(metaDataDF[,7])
  listen = as.numeric(metaDataDF[,8])
  # charge = as.numeric(sub("ms/", "",metaDataDF[,7]))
  # listen = as.numeric(sub("ms", "",metaDataDF[,8]))
  temp = as.numeric(sub("C", "",metaDataDF[,9]))
  noise = as.numeric(sub("N", "",metaDataDF[,10]))
  
  return(data.frame(datetime, power, rx, tx, ea, charge, listen, temp, noise, stringsAsFactors = F))
  #return(data.frame(date, time, datetime, power, rx, tx, ea, charge, listen, temp, noise, stringsAsFactors = F))
}

makeBiomarkDF = function(tagDataDF){
  date = as.Date(do.call("c", lapply(as.character(tagDataDF[,3]), getDate)))
  time = as.character(str_sub(tagDataDF[,4], 1, 11))
  fracsec = round(as.numeric(str_sub(time, 9, 11)), 2)
  datetime = ymd_hms(paste(date, time))
  #datetime = strftime(paste(date, time),format='%Y-%m-%d %H:%M:%S', tz=tz, usetz=FALSE)
  #datetime = strptime(paste(date, time),format='%Y-%m-%d %H:%M:%S', tz=tz)
  duration = NA
  tagtype = NA
  tagid = as.character(str_replace(tagDataDF[,5], '[.]', '')) 
  #antnum = as.numeric(tagDataDF[,3])
  consdetc = NA
  arrint = NA
  return(data.frame(datetime, fracsec, duration, tagtype, tagid, consdetc, arrint, stringsAsFactors = F))
}

parseORFIDmsg = function(line){
  date = as.Date(getDate(line[2]))
  time = as.character(line[3])
  msg = str_c(line, collapse=' ') #line[5:length(line)]
  return(data.frame(date, time, msg, stringsAsFactors = F))
}

parseBiomarkSrp = function(line){
  date = as.Date(getDate(line[3]))
  time = as.character(str_sub(line[4], 1, 11))
  deets = unlist(strsplit(line[5], ","))
  OpMo = deets[1]
  NMo = deets[2]
  EMo = deets[3]
  Sync = deets[4]
  ExVL = deets[5]
  TunP = deets[6]
  Caps = deets[7]
  TMem = deets[8]
  SMem = deets[9]
  InV = deets[10]
  ExV = deets[11]
  AA = deets[12]
  FDXsig = deets[13]
  TPh = deets[14]
  Temp = deets[15]
  A1 = deets[16]
  A2 = deets[17]
  A3 = deets[18]
  A4 = deets[19]
  A5 = deets[20]
  return(data.frame(date, time, OpMo, NMo, 
                    EMo, Sync, ExVL, TunP, Caps, TMem, SMem,
                    InV, ExV, AA, FDXsig, TPh, Temp, A1, A2, A3, A4, A5,
                    stringsAsFactors = F))
}

addInfo = function(df, lineNumbers, archiveFile, site, reader){
  df$site = site
  df$reader = reader
  df$fname = archiveFile
  df$line = lineNumbers
  df$dateadded = Sys.Date()
  return(df)
}

writeDF = function(df, fname){
  if(nrow(df) == 0){return()}
  df = df[!duplicated(df),]
  write_csv(df, fname, append=T)
}

isJunkMetaFn = function(line){
  return(str_squish(unlist(line)[5]))
}

# isJunkTagFn = function(line){
#   tag<-str_squish(unlist(line)[6])
#   tag<-sub("_", "",tag)
#   return(grepl("^[0-9]+$",tag)) #Returns T or F on whether tag is numeric
# }

#Find junk ORFID tags. Fails on non-numeric characters and tag prefixes that are not listed
isJunkTagFn = function(line){
  tag<-str_squish(unlist(line)[6])
  tag<-sub("_", "",tag)
  pre = substr(tag, start = 1, stop = 3)
  return(grepl("^[0-9]+$",tag) &
           grepl("000|900|982|985|999", pre))}

#ID junk Biomark tags. Remove . in tag number
isBMJunkTagFn = function(line){
  tag<-str_squish(unlist(line)[5])
  tag<-sub("\\.", "",tag)
  return(grepl("^[A-Za-z0-9]+$",tag)) #Returns T or F on whether tag is alpha or numeric (Hex dec is OK)
}

#Remove column (HDX) from new ORFID format
  ## Could also add HDX to W here if wanted to preserve HDX
rmNewColFn = function(line){
  newline <- unlist(line)[-5] # remove the 5th element of the line
  return(newline)
}

parseScanLog = function(logFile, dbDir, archiveDir){
  print(str_glue('    File: ', logFile))
  bname = basename(logFile)
  archiveFile = suppressWarnings(normalizePath(file.path(archiveDir,str_glue(as.character(Sys.Date()),'_',bname))))
  
  lines = read_lines(logFile)
  lineLen = length(lines)
  

### Is this file orfid or biomark? - need to get site name
  end = ifelse(lineLen < 150, lineLen, 150) #if ll is <150 use ll, if its greater, use only first 150 lines
  readerTestLines = spaceDelim(lines[1:end])
  biomark = c()
  for(i in 1:length(readerTestLines)){
    tmp = as.character(unlist(readerTestLines[i])[1])
    inIt = tmp %in% c("MSG:", "TAG:", "SRP:", "ALM:", "*TAG:", "*SRP:")
    biomark = c(biomark,inIt)
  }
  
  if(!any(biomark)){
    site = unlist(str_split(basename(logFile),'_'))[1]
    reader = 'ORFID'
    print(str_glue('        Reader: ',reader))
    lineStart = substr(lines, 1, 2)

    # see if first column is a date - used later to determine if lines are metadata (isDate == T)
    isDate = spaceDelim(lines)
    date = unlist(lapply(isDate, function(l) {unlist(l[1])}))
    dateCheck = do.call("c", lapply(date, getDate))
    isDate = !is.na(dateCheck)
    
    #####################################################################################
    
    ########## OLD ORFID READER DATA FORMAT ####################
    ########## PULL OUT THE TAG DATA (D CODE) 
    dataMaybe = which(lineStart == 'D ') 
    dataMaybeLength = length(dataMaybe)
    
    #make an empty df in case there are no bad tags (as a holder for rbind below)
    tagDataBadDF <- data.frame(msg=character(),
                               site=character(),
                               reader=character(), 
                               fname=character(), 
                               line=integer(), 
                               dateadded=as.Date(character()),
                               stringsAsFactors=FALSE) 
    
    if(dataMaybeLength > 0){
      dataLines = spaceDelim(lines[dataMaybe])

      #...do a check on the date to make sure that its a proper date
      lens = lengths(dataLines)
      date = unlist(lapply(dataLines, function(l) {unlist(l[2])}))
      dateCheck = do.call("c", lapply(date, getDate)) # need to use do.call('c') here to unlist because unlist reformats the date
      
      #... for dates that are good and the number of columns is correct, assume they are tags and put them in a DF
      tagDataLines = dataMaybe[which(lens == 8 & !is.na(dateCheck))] 
      tagDataLinesLength = length(tagDataLines)
      if(tagDataLinesLength > 0){
        tagDataList = spaceDelim(lines[tagDataLines])
        #print(head(tagDataList)[1])
        isGoodTag = lapply(tagDataList,isJunkTagFn) #Remove underscore, test for numeric
        #isGoodTag = do.call("c",lapply(tagDataList,isJunkTagFn)) #Remove underscore, test for numeric
        tagDataGood = which(isGoodTag==T) 
        tagDataGoodLength = length(tagDataGood)
        
        if(tagDataGoodLength>0){
          tagDataLinesGood = spaceDelim(lines[tagDataLines[tagDataGood]])
          tagDataMatrixGood = do.call(rbind, tagDataLinesGood)
          tagDataDF = as.data.frame(tagDataMatrixGood) %>%  #cbind(tagDataMatrix, tagDataLines)
            makeORFIDtagDF() %>%
            #makeORFIDtagDF(tz) %>%
            addInfo(dataMaybe[tagDataGood], archiveFile, site, reader)
        }
        
         tagDataBad = which(isGoodTag==F) # any tags that have non-numeric characters
         tagDataBadLength = length(tagDataBad)
        if(tagDataBadLength > 0){
            tagDataBadVector = lines[dataMaybe[tagDataBad]] %>% 
              sub("\t", " ", .) %>%
              str_squish()
            tagDataBadDF = data.frame(msg=tagDataBadVector, stringsAsFactors = F) %>%
              addInfo(dataMaybe[tagDataBad], archiveFile, site, reader)
          }
        
      }
      
      #... for dates that are good but the number of columns is incorrect, assume they are 
      #... failed reads and put them in a separate DF
      tagDataFailLines = dataMaybe[which(lens != 8 & !is.na(dateCheck))]
      tagDataFailLinesLength = length(tagDataFailLines)
  
      #make an empty df in case there are no bad tags
      tagDataFailDF <- data.frame(msg=character(),
                                   site=character(),
                                   reader=character(), 
                                   fname=character(), 
                                   line=integer(), 
                                   dateadded=as.Date(character()),
                                   stringsAsFactors=FALSE) 
        
        
      if(tagDataFailLinesLength > 0){
        tagDataFailVector = lines[tagDataFailLines] %>% 
          sub("\t", " ", .) %>%
          str_squish()
        tagDataFailDF = data.frame(msg=tagDataFailVector, stringsAsFactors = F) %>%
          addInfo(tagDataFailLines, archiveFile, site, reader)
      }
      
      #... for D codes that have a bad date, put them in a separate DF
      tagDataJunkLines = dataMaybe[which(is.na(dateCheck))]
      tagDataJunkLinesLength = length(tagDataJunkLines)

      #make an empty df in case there are no bad tags
      tagDataJunkieDF <- data.frame(msg=character(),
                                  site=character(),
                                  reader=character(), 
                                  fname=character(), 
                                  line=integer(), 
                                  dateadded=as.Date(character()),
                                  stringsAsFactors=FALSE) 
      
      if(tagDataJunkLinesLength > 0){
        tagDataJunkVector = lines[tagDataJunkLines] %>%
          sub("\t", " ", .) %>%
          str_squish()
        tagDataJunkieDF = data.frame(msg = tagDataJunkVector, stringsAsFactors = F) %>%
          addInfo(tagDataJunkLines, archiveFile, site, reader)
      }
      
      tagDataJunkDF <- rbind(tagDataJunkieDF, tagDataFailDF, tagDataBadDF) #bind the junk data together
      #tagDataJunkDF <- tagDataJunkDF[complete.cases(tagDataJunkDF),]
      
    }
    
    #####################################################################################
    ########## NEW ORFID READER DATA FORMAT #################### Thanks, not.
    
    #... Pull out the tag data (S code) 
    newDataMaybe = which(lineStart == 'S ') 
    newDataMaybeLength = length(newDataMaybe)
    
    #make an empty df in case there are no bad tags (as a holder for rbind below)
    tagDataBadDF <- data.frame(msg=character(),
                               site=character(),
                               reader=character(), 
                               fname=character(), 
                               line=integer(), 
                               dateadded=as.Date(character()),
                               stringsAsFactors=FALSE) 
    
    if(newDataMaybeLength > 0){
      newdataLines = spaceDelim(lines[newDataMaybe])
      
      #...do a check on the date to make sure that its a proper date
      newLens = lengths(newdataLines)
      newDate = unlist(lapply(newdataLines, function(l) {unlist(l[2])}))
      dateCheck = do.call("c", lapply(newDate, getDate)) # need to use do.call('c') here to unlist because unlist reformats the date
      
      #... for dates that are good and the number of columns is correct, assume they are tags and put them in a DF
      newTagDataLines = newDataMaybe[which(newLens == 9 & !is.na(dateCheck))] 
      newTagDataLinesLength = length(newTagDataLines)
      if(newTagDataLinesLength > 0){
        newTagDataList = spaceDelim(lines[newTagDataLines])
        newTagDataList2 = lapply(newTagDataList,rmNewColFn) #Remove new 5th column
        newisGoodTag = lapply(newTagDataList2,isJunkTagFn) #Remove underscore, test for numeric
        newTagDataGood = which(newisGoodTag==T) 
        newTagDataGoodLength = length(newTagDataGood)
        
        if(newTagDataGoodLength>0){
          newTagDataLinesGood = spaceDelim(lines[newTagDataLines[newTagDataGood]])
          newTagDataMatrixGood = do.call(rbind, newTagDataLinesGood)
          newTagDataMatrixGood = newTagDataMatrixGood[,-5]  #Remove new 5th column
          tagDataDF = as.data.frame(newTagDataMatrixGood) %>%  #cbind(tagDataMatrix, newTagDataLines) #NOTE: leaving tagDataDF name for now, may need to change
            makeORFIDtagDF() %>%
            addInfo(newDataMaybe[newTagDataGood], archiveFile, site, reader)
        }
        
        tagDataBad = which(newisGoodTag==F) # any tags that have non-numeric characters
        tagDataBadLength = length(tagDataBad)
        if(tagDataBadLength > 0){
          tagDataBadVector = lines[newDataMaybe[tagDataBad]] %>% 
            sub("\t", " ", .) %>%
            str_squish()
          tagDataBadDF = data.frame(msg=tagDataBadVector, stringsAsFactors = F) %>%
            addInfo(newDataMaybe[tagDataBad], archiveFile, site, reader)
        }
        
      }
      
      #... for dates that are good but the number of columns is incorrect, assume they are 
      #... failed reads and put them in a separate DF
      tagDataFailLines = newDataMaybe[which(newLens != 9 & !is.na(dateCheck))]
      tagDataFailLinesLength = length(tagDataFailLines)
      
      #make an empty df in case there are no bad tags
      tagDataFailDF <- data.frame(msg=character(),
                                  site=character(),
                                  reader=character(), 
                                  fname=character(), 
                                  line=integer(), 
                                  dateadded=as.Date(character()),
                                  stringsAsFactors=FALSE) 
      
      
      if(tagDataFailLinesLength > 0){
        tagDataFailVector = lines[tagDataFailLines] %>% 
          sub("\t", " ", .) %>%
          str_squish()
        tagDataFailDF = data.frame(msg=tagDataFailVector, stringsAsFactors = F) %>%
          addInfo(tagDataFailLines, archiveFile, site, reader)
      }
      
      #... for D codes that have a bad date, put them in a separate DF
      tagDataJunkLines = newDataMaybe[which(is.na(dateCheck))]
      tagDataJunkLinesLength = length(tagDataJunkLines)
      
      #make an empty df in case there are no bad tags
      tagDataJunkieDF <- data.frame(msg=character(),
                                    site=character(),
                                    reader=character(), 
                                    fname=character(), 
                                    line=integer(), 
                                    dateadded=as.Date(character()),
                                    stringsAsFactors=FALSE) 
      
      if(tagDataJunkLinesLength > 0){
        tagDataJunkVector = lines[tagDataJunkLines] %>%
          sub("\t", " ", .) %>%
          str_squish()
        tagDataJunkieDF = data.frame(msg = tagDataJunkVector, stringsAsFactors = F) %>%
          addInfo(tagDataJunkLines, archiveFile, site, reader)
      }
      
      tagDataJunkDF <- rbind(tagDataJunkieDF, tagDataFailDF, tagDataBadDF) #bind the junk data together
      #tagDataJunkDF <- tagDataJunkDF[complete.cases(tagDataJunkDF),]
      
    }
    
    
    #####################################################################################
    
    ##########  DEAL WITH THE MESSAGE DATA (E AND B CODES) #Kept the same for old and new ORFID data formats; may need to change
    msgMaybe = which(lineStart == 'E ' | lineStart == 'B ')
    msgMaybeLength = length(msgMaybe)
    if(msgMaybeLength > 0){
      msgLines = spaceDelim(lines[msgMaybe])
      
      #...do a check on the date to make sure that its a proper date
      date = unlist(lapply(msgLines, function(l) {unlist(l[2])}))
      dateCheck = do.call("c", lapply(date, getDate)) # need to use do.call('c') here to unlist because unlist reformats the date
      
      #... for dates that are good, assume they are messages and put them in a DF
      msgDataLines = msgMaybe[which(!is.na(dateCheck))]
      msgDataLinesLength = length(msgDataLines)
      if(msgDataLinesLength > 0){
        msgDataList = spaceDelim(lines[msgDataLines])
        msgDataDF = do.call("rbind", lapply(msgDataList, parseORFIDmsg)) %>%
          addInfo(msgDataLines, archiveFile, site, reader)
      }
      
      #... for E and B codes that have a bad date, put them in a separate DF
      msgDataJunkLines = msgMaybe[which(is.na(dateCheck))]
      msgDataJunkLinesLength = length(msgDataJunkLines)
      if(msgDataJunkLinesLength > 0){
        msgDataJunkVector = lines[msgDataJunkLines] %>%
          sub("\t", " ", .) %>%
          str_squish()
        msgDataJunkDF = data.frame(msg = msgDataJunkVector, stringsAsFactors = F) %>%
          addInfo(msgDataJunkLines, archiveFile, site, reader)
      }
    }
    
    
    ##########  DEAL WITH OTHER
    otherLines = which(lineStart != 'D ' & lineStart != 'E ' & lineStart != 'B ' 
                       & lineStart != 'S ' & isDate != T) #and not date
    otherLinesLength = length(otherLines)
    if(otherLinesLength > 0){
      otherVector = lines[otherLines] %>%
        sub("\t", " ", .) %>%
        str_squish()
      otherDF = data.frame(msg = otherVector, stringsAsFactors = F) %>%
        addInfo(otherLines, archiveFile, site, reader)
    }
    
    
  ##########  DEAL WITH METADATA
  #   #### SOMEWHERE IN HERE DEAL WITH DETECT DATA AND PUT IT INTO JUNK METADATA

  metaLines = which(isDate == T)  
  metaLinesLength = length(metaLines)
  if(metaLinesLength > 0){
    metaDataList = spaceDelim(lines[metaLines])
    isJunkMeta = do.call("c", lapply(metaDataList, isJunkMetaFn)) 
    isJunkMetaNchar = nchar(isJunkMeta)
    isJunkMeta = substring(isJunkMeta, isJunkMetaNchar,isJunkMetaNchar) # condition on 5th character being an A
    isJunkMeta = isJunkMeta != 'A' | is.na(isJunkMeta) # true false - is thing junk
    junkMetaLines = which(isJunkMeta == T)
    notJunkMetaLines = which(isJunkMeta == F)

    #identify good and bad lines here; each need to go into a separate dataframe
    if(length(notJunkMetaLines) != 0){
      metaDataMatrix = do.call(rbind, metaDataList[notJunkMetaLines])
      metaDataDF = as.data.frame(metaDataMatrix) %>%  #cbind(tagDataMatrix, tagDataLines)
        makeORFIDmetaDF() %>% 
        #makeORFIDmetaDF(tz) %>%   
        addInfo(metaLines[notJunkMetaLines], archiveFile, site, reader)
    } 
    if(length(junkMetaLines) != 0){
      junkMetaData = lines[metaLines][junkMetaLines] %>%
        sub("\t", " ", .) %>%
        str_squish()
      junkMetaDataDF = data.frame(msg = junkMetaData, stringsAsFactors = F) %>%
        addInfo(metaLines[junkMetaLines], archiveFile, site, reader)
    }
  }
    
  #############################################  
# Biomark parsing starts here  #################
  #############################################
    
  } else { #TODO - check to see if this is a biomark reader - we are assuming it is right now
    #site = basename(dirname(dirname(logFile)))
    site = unlist(str_split(basename(logFile),'_'))[1]
    reader = 'Biomark'
    print(str_glue('        Reader: ',reader))
    lineStart = substr(lines, 1, 4)
    
    ########## DEAL WITH THE TAG DATA (TAG: CODE)
    #make an empty df in case there are no bad tags (as a holder for rbind below)
    tagDataBadDF <- data.frame(msg=character(),
                               site=character(),
                               reader=character(), 
                               fname=character(), 
                               line=integer(), 
                               dateadded=as.Date(character()),
                               stringsAsFactors=FALSE) 
    
      dataMaybe = which(lineStart == '*TAG' | lineStart == 'TAG:')
      #MCdat: dataMaybe = which(lineStart == 'TAG:') 
      dataMaybeLength = length(dataMaybe)
     
    if(dataMaybeLength > 0){
      dataLines = spaceDelim(lines[dataMaybe])
      
      #...do a check on the date to make sure that its a proper date
      lens = lengths(dataLines)
      #MCdat: date = unlist(lapply(dataLines, function(l) {unlist(l[4])}))
      date = unlist(lapply(dataLines, function(l) {unlist(l[3])}))
      dateCheck = do.call("c", lapply(date, getDate)) # need to use do.call('c') here to unlist because unlist reformats the date
      
      #... for dates that are good and the number of columns is correct, assume they are tags and put them in a DF
      tagDataLines = dataMaybe[which(lens == 5 | lens == 7 & !is.na(dateCheck))] #added length of 6 to accomodate new Biomark format on test tags (mv in 6th col.)
      #tagDataLines = dataMaybe[which(lens == 5 & !is.na(dateCheck))] original: working as of 2/22/22
      #MCdat: tagDataLines = dataMaybe[which(lens == 6 & !is.na(dateCheck))]
      tagDataLinesLength = length(tagDataLines)
      if(tagDataLinesLength > 0){
        tagDataList = spaceDelim(lines[tagDataLines])
        isGoodTag = lapply(tagDataList, isBMJunkTagFn) #Check for bad characters
        tagDataGood = which(isGoodTag==T) 
        tagDataGoodLength = length(tagDataGood)
        
        if(tagDataGoodLength>0){
          tagDataLinesGood = spaceDelim(lines[tagDataLines[tagDataGood]])
          
          # Take out first 5 values only; ignore the mV addition (2 add'l columns) for test tag data; Biomark format change 2/2022
          tagDataLinesGood = tagDataLinesGood %>% 
            map(., function(x) c(x[[1]], x[[2]], x[[3]], x[[4]], x[[5]]))
          
          tagDataMatrixGood = do.call(rbind, tagDataLinesGood)
          tagDataDF = as.data.frame(tagDataMatrixGood) %>%  #cbind(tagDataMatrix, tagDataLines)
            makeBiomarkDF() %>%
            #makeBiomarkDF(tz) %>%
            addInfo(dataMaybe[tagDataGood], archiveFile, site, reader)
        }
        
        tagDataBad = which(isGoodTag==F) # any tags that have non-alpha-numeric characters
        tagDataBadLength = length(tagDataBad)
        if(tagDataBadLength > 0){
          tagDataBadVector = lines[dataMaybe[tagDataBad]] %>% 
            sub("\t", " ", .) %>%
            str_squish()
          tagDataBadDF = data.frame(msg=tagDataBadVector, stringsAsFactors = F) %>%
            addInfo(dataMaybe[tagDataBad], archiveFile, site, reader)
        }
        
      }
        
       # ORIGINAL 3/6
       # tagDataMatrix = do.call(rbind, tagDataList)
        # 
        # #tagDataDF = head(as.data.frame(tagDataMatrix))
        # tagDataDF = as.data.frame(tagDataMatrix) %>%  #cbind(tagDataMatrix, tagDataLines)
        #   makeBiomarkDF(tz) %>%
        #   addInfo(tagDataLines, archiveFile, site, reader)
      #}
      
      # ORIGINAL
      # #... for dates that are good but the number of columns is incorrect, assume they are failed reads and put them in a separate DF
      # tagDataFailLines = dataMaybe[which(lens != 6 & !is.na(dateCheck))]
      # tagDataFailLinesLength = length(tagDataFailLines)
      # if(tagDataFailLinesLength > 0){
      #   tagDataFailList = spaceDelim(lines[tagDataFailLines])
      #   tagDataFailDF = do.call("rbind", lapply(tagDataFailList, parseBiomarkMsg)) %>% 
      #     addInfo(tagDataFailLines, archiveFile, site, reader)
      # }
      
      
      
      #... for dates that are good but the number of columns is incorrect, assume they are 
      #... failed reads and put them in a separate DF
      tagDataFailLines = dataMaybe[which(lens != 5 & !is.na(dateCheck))] #NOTE: This means test tag values with new mV show up here, even though they were also parsed as good. Leaving for now (2/22/22) to see if we can change format on Biomark end
      tagDataFailLinesLength = length(tagDataFailLines)
      
      #make an empty df in case there are no bad tags
      tagDataFailDF <- data.frame(msg=character(),
                                  site=character(),
                                  reader=character(), 
                                  fname=character(), 
                                  line=integer(), 
                                  dateadded=as.Date(character()),
                                  stringsAsFactors=FALSE) 
      
      
      if(tagDataFailLinesLength > 0){
        tagDataFailVector = lines[tagDataFailLines] %>% 
          sub("\t", " ", .) %>%
          str_squish()
        tagDataFailDF = data.frame(msg=tagDataFailVector, stringsAsFactors = F) %>%
          addInfo(tagDataFailLines, archiveFile, site, reader)
      }
      
     #ORIGINAL 
      #     #... for TAG: codes that have a bad date, put them in a separate DF
      # tagDataJunkLines = dataMaybe[which(is.na(dateCheck))]
      # tagDataJunkLinesLength = length(tagDataJunkLines)
      # if(tagDataJunkLinesLength > 0){
      #   tagDataJunkVector = lines[tagDataJunkLines] %>%
      #     sub("\t", " ", .) %>%
      #     str_squish()
      #   tagDataJunkDF = data.frame(msg = tagDataJunkVector, stringsAsFactors = F) %>%
      #     addInfo(tagDataJunkLines, archiveFile, site, reader)
      # }
      
      
      #... for TAG: codes that have a bad date, put them in a separate DF
      tagDataJunkLines = dataMaybe[which(is.na(dateCheck))]
      tagDataJunkLinesLength = length(tagDataJunkLines)
      
      #make an empty df in case there are no bad tags
      tagDataJunkieDF <- data.frame(msg=character(),
                                    site=character(),
                                    reader=character(), 
                                    fname=character(), 
                                    line=integer(), 
                                    dateadded=as.Date(character()),
                                    stringsAsFactors=FALSE) 
      
      if(tagDataJunkLinesLength > 0){
        tagDataJunkVector = lines[tagDataJunkLines] %>%
          sub("\t", " ", .) %>%
          str_squish()
        tagDataJunkieDF = data.frame(msg = tagDataJunkVector, stringsAsFactors = F) %>%
          addInfo(tagDataJunkLines, archiveFile, site, reader)
      }
      
      tagDataJunkDF <- rbind(tagDataJunkieDF, tagDataFailDF, tagDataBadDF) 
      
    }
    
      
      
    ##########  DEAL WITH THE STATUS REPORT DATA (*SRP AND SRP CODES)
    srpMaybe = which(lineStart == 'SRP:' | lineStart == '*SRP')
    srpMaybeLength = length(srpMaybe)
    if(srpMaybeLength > 0){
      srpLines = spaceDelim(lines[srpMaybe])
      
      #...do a check on the date to make sure that its a proper date
      lens = lengths(srpLines)
      date = unlist(lapply(srpLines, function(l) {unlist(l[3])}))
      dateCheck = do.call("c", lapply(date, getDate)) # need to use do.call('c') here to unlist because unlist reformats the date
      
      #...do a check to make sure msg series in [5] has 20 pieces
      #msgParts = unlist(lapply(msgLines, function(l) {unlist(l[5])}))
      
      #... for dates that are good, assume they are messages and put them in a DF
      srpDataLines = srpMaybe[which(!is.na(dateCheck))]
      srpDataLinesLength = length(srpDataLines)
      if(srpDataLinesLength > 0){
        srpDataList = spaceDelim(lines[srpDataLines])
        srpDataDF = do.call("rbind", lapply(srpDataList, parseBiomarkSrp)) %>%
          addInfo(srpDataLines, archiveFile, site, reader)
      }
      
      #... for SRP and *SRP codes that have a bad date, put them into the msgJunk DF
      msgDataJunkLines = srpMaybe[which(is.na(dateCheck))]
      msgDataJunkLinesLength = length(msgDataJunkLines)
      if(msgDataJunkLinesLength > 0){
        msgDataJunkVector = lines[msgDataJunkLines] %>%
          sub("\t", " ", .) %>%
          str_squish()
        msgDataJunkDF = data.frame(msg = msgDataJunkVector, stringsAsFactors = F) %>%
          addInfo(msgDataJunkLines, archiveFile, site, reader)
      }
    }
    
   ##########  DEAL WITH OTHER: Including ALM, NRP, MSG
      ########    Note: NRP may be important in future and will need to parse it
    otherLines = which(lineStart != 'TAG:' & lineStart != '*TAG' 
                       & lineStart != 'SRP:' & lineStart != '*SRP')
    otherLinesLength = length(otherLines)
    if(otherLinesLength > 0){
      otherVector = lines[otherLines] %>%
        sub("\t", " ", .) %>%
        str_squish()
      otherDF = data.frame(msg = otherVector, stringsAsFactors = F) %>%
        addInfo(otherLines, archiveFile, site, reader)
    }
    
  }
  
  # write out the files here
  # make file names
  tagDataDFfile = file.path(dbDir,'tagDB.csv')
  #tagDataFailDFfile = file.path(dbDir,'tagFailDB.csv')
  tagDataJunkDFfile = file.path(dbDir,'tagBadDB.csv')
  msgDataDFfile = file.path(dbDir,'msgDB.csv')  
  msgDataJunkDFfile = file.path(dbDir,'msgBadDB.csv')
  otherDFfile = file.path(dbDir,'otherDB.csv')
  lineLogFile = file.path(dbDir,'logDB.csv')
  metaDataDFfile = file.path(dbDir, 'metaDB_OR.csv')
  metaDataDFBMfile = file.path(dbDir,'metaDB_BM.csv')
  junkMetaDataDFfile = file.path(dbDir, 'metaBadDB.csv')
  
  
  # write them out
  if(exists('tagDataDF')){
    writeDF(tagDataDF, tagDataDFfile)
    tagDataDFnrow = nrow(tagDataDF)
    tagDataDFpercent = round((tagDataDFnrow/lineLen)*100,2)
  } else {
    tagDataDFnrow = 0
    tagDataDFpercent = 0
  }
  print(str_glue('        Tag lines: ', as.character(tagDataDFpercent),'%'))
  
  # if(exists('tagDataFailDF')){
  #   writeDF(tagDataFailDF, tagDataFailDFfile)
  #   tagDataFailDFnrow = nrow(tagDataFailDF)
  #   tagDataFailDFpercent = round((tagDataFailDFnrow/lineLen)*100,2)
  # } else {
  #   tagDataFailDFnrow = 0
  #   tagDataFailDFpercent = 0
  # }
  # print(str_glue('        Tag fail lines: ', as.character(tagDataFailDFpercent),'%'))
  # 
  if(exists('tagDataJunkDF')){
    writeDF(tagDataJunkDF, tagDataJunkDFfile)
    tagDataJunkDFnrow = nrow(tagDataJunkDF)
    tagDataJunkDFpercent = round((tagDataJunkDFnrow/lineLen)*100,2)
  } else {
    tagDataJunkDFnrow = 0
    tagDataJunkDFpercent = 0
  }
  print(str_glue('        Tag bad lines: ', as.character(tagDataJunkDFpercent),'%'))
  
  if(exists('msgDataDF')){
    writeDF(msgDataDF, msgDataDFfile)
    msgDataDFnrow = nrow(msgDataDF)
    msgDataDFpercent = round((msgDataDFnrow/lineLen)*100,2)
  } else {
    msgDataDFnrow = 0
    msgDataDFpercent = 0
  }
  print(str_glue('       Message lines: ', as.character(msgDataDFpercent),'%'))
  

  if(exists('msgDataJunkDF')){
    writeDF(msgDataJunkDF, msgDataJunkDFfile)
    msgDataJunkDFnrow = nrow(msgDataJunkDF)
    msgDataJunkDFpercent = round((msgDataJunkDFnrow/lineLen)*100,2)
  } else {
    msgDataJunkDFnrow = 0
    msgDataJunkDFpercent = 0
  }
  print(str_glue('        Message bad lines: ', as.character(msgDataJunkDFpercent),'%'))
  
  if(exists('otherDF')){
    writeDF(otherDF, otherDFfile)
    otherDFnrow = nrow(otherDF)
    otherDFpercent = round((otherDFnrow/lineLen)*100,2)
  } else {
    otherDFnrow = 0
    otherDFpercent = 0
  }
  print(str_glue('        Other lines: ', as.character(otherDFpercent),'%'))
  
  if(exists('metaDataDF')){
    writeDF(metaDataDF, metaDataDFfile)
    metaDataDFnrow = nrow(metaDataDF)
    metaDataDFpercent = round((metaDataDFnrow/lineLen)*100,2)
  } else {
    metaDataDFnrow = 0
    metaDataDFpercent = 0
  }
  print(str_glue('       ORFID meta lines: ', as.character(metaDataDFpercent),'%'))
  
  if(exists('srpDataDF')){
    writeDF(srpDataDF, metaDataDFBMfile)
    srpDataDFnrow = nrow(srpDataDF)
    srpDataDFpercent = round((srpDataDFnrow/lineLen)*100,2)
  } else {
    srpDataDFnrow = 0
    srpDataDFpercent = 0
  }
  print(str_glue('       Biomark meta lines: ', as.character(srpDataDFpercent),'%'))
  
  if(exists('junkMetaDataDF')){
    writeDF(junkMetaDataDF, junkMetaDataDFfile)
    metaDataBadDFnrow = nrow(junkMetaDataDF)
    metaDataBadDFpercent = round((metaDataBadDFnrow/lineLen)*100,2)
  } else {
    metaDataBadDFnrow = 0
    metaDataBadDFpercent = 0
  }
  print(str_glue('        Metadata bad lines: ', as.character(metaDataBadDFpercent),'%'))
  
  
    logDF = data.frame(
    site=site,
    reader=reader, 
    fname=archiveFile, 
    dateadded=Sys.Date(), 
    # metapct=metaDataDFpercent,
    # metabadpct=metaDataBadDFpercent,
    # tagpct=tagDataDFpercent,
    # tagfailpct=tagDataFailDFpercent,
    # tagbadpct=tagDataJunkDFpercent,
    # msgpct=msgDataDFpercent,
    # msgbadpct=msgDataJunkDFpercent,
    # otherpct=otherDFpercent,
    tagnrow=tagDataDFnrow,
    #tagfailnrow=tagDataFailDFnrow,
    tagbadnrow=tagDataJunkDFnrow,
    metanrow_OR=metaDataDFnrow,
    metanrow_BM=srpDataDFnrow,
    metabadnrow=metaDataBadDFnrow,
    msgnrow=msgDataDFnrow,
    msgbadnrow=msgDataJunkDFnrow,
    othernrow=otherDFnrow,
    totalnrow=lineLen,
    stringsAsFactors = F
  )
  
  write_csv(logDF, lineLogFile, append=T)
  
  #move the file to the archive
    file.rename(logFile, archiveFile)
    #file.remove(logFile)
}

PITcompile = function(dataDir, dbDir, timeZone){
  #logFile = "C:/Users/HaleyOhms/Documents/Carmel Project/Array data/BGS/downloads/BGS_JAN15.txt"
  #dataDir = "C:/Users/HaleyOhms/Documents/Carmel Project/Array data"
  siteDirs = normalizePath(list.dirs(dataDir, recursive = F))
  #tz = timeZone
  
  for(dir in siteDirs){
    #dir = siteDirs[3]
    print(str_glue('Site: ', dir))
    downloadDir = normalizePath(file.path(dir,"downloads"))
    archiveDir = normalizePath(file.path(dir,"archive"))
    logFiles = normalizePath(list.files(downloadDir, '*', full.names = T))
    if(length(logFiles) != 0){
      for(logFile in logFiles){
        parseScanLog(logFile, dbDir, archiveDir)
        #parseScanLog(logFile, tz, dbDir, archiveDir)
      }
    } else {
      print(str_glue('    No log files for this site'))
      next
    }
  }
}

########################################################
# Check For Duplicates
########################################################
## NOTE: distinct is a faster package, may want to consider that in the future

#dbDir = dbDir = "C:/Users/HaleyOhms/Documents/Carmel/Database"

rmdups = function(dbDir){
  # make a list of file names and columns to use to check duplicates
  rmDupInfo = list(
    list(fn='metaBadDB.csv', cols=c(1:3)),
    list(fn='metaDB_BM.csv', cols=c(1:24)),
    list(fn='metaDB_OR.csv', cols=c(1:11)),
    list(fn='msgBadDB.csv', cols=c(1:3)),
    list(fn='msgDB.csv', cols=c(1:5)),
    list(fn='otherDB.csv', cols=c(1:3)),
    list(fn='tagBadDB.csv', cols=c(1:3)),
    list(fn='tagDB.csv', cols=c(1:9))
    )

  # loop through all the files defined in above list and remove duplicates
  #i=1
  for(i in 1:length(rmDupInfo)){
    path = file.path(dbDir, rmDupInfo[[i]]$fn)
    if(file.exists(path)){
      print(paste("Checking", rmDupInfo[[i]]$fn, "for duplicate rows"), quote = F)
      dat = read_csv(file=path, col_names=F)   # might need to set col_types parameter
      dups = duplicated(dat[,rmDupInfo[[i]]$cols])
      ndups = length(which(dups == T))
      print(paste("   Found", as.character(ndups), "duplicates"), quote = F)
      if(ndups != 0){
        dat = dat[!dups,]
        write_csv(dat, path=path, col_names=F)
        # singleDat = dat[!dups,]
        # write_csv(singleDat, path="C:/Users/HaleyOhms/Documents/Carmel/Database/tagDB_mDups.csv", col_names=F)
        # dupDat = dat[dups,]
        # write_csv(dupDat, path="C:/Users/HaleyOhms/Documents/Carmel/Database/tagDupsTest.csv", col_names=F)
      }
    }
  }
}







