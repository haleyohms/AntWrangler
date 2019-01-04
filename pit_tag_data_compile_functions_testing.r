


library(tidyverse)
library(lubridate)


# list of time zones
#https://en.wikipedia.org/wiki/List_of_tz_database_time_zones


getDate = function(dateChunk){
  #dateChunk = "03/03/2018"
  
  if(nchar(dateChunk) == 10){
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
    str_squish() %>%
    str_split(' ')
  return(dataLines)
}

makeORFIDtagDF = function(tagDataDF){
  date = as.Date(tagDataDF[,2])
  time = as.character(tagDataDF[,3])
  fracsec = round(as.numeric(str_sub(time, 9, 11)), 2)
  datetime = strptime(paste(date, time),format='%Y-%m-%d %H:%M:%S', tz=tz)
  duration = period_to_seconds(hms(tagDataDF[,4]))
  tagtype = as.character(tagDataDF[,5])
  tagid = as.character(tagDataDF[,6])
  antnum = NA
  consdetc = as.numeric(tagDataDF[,7])
  arrint = as.character(tagDataDF[,8])
  arrint[arrint == '.'] = '65001'
  arrint = as.numeric(arrint)
  
  return(data.frame(date, time, fracsec, datetime, duration, tagtype, tagid, antnum, consdetc, arrint, stringsAsFactors = F))
}

makeBiomarkDF = function(tagDataDF){
  date = as.Date(do.call("c", lapply(as.character(tagDataDF[,4]), getDate)))
  time = as.character(str_sub(tagDataDF[,5], 1, 11))
  fracsec = round(as.numeric(str_sub(time, 9, 11)), 2)
  datetime = strptime(paste(date, time),format='%Y-%m-%d %H:%M:%S', tz=tz)
  duration = NA
  tagtype = NA
  tagid = as.character(str_replace(tagDataDF[,6], '[.]', '_')) #str_replace(tagDataDF[,6], '[.]', '_')
  antnum = NA
  consdetc = NA
  arrint = NA
  return(data.frame(date, time, fracsec, datetime, duration, tagtype, tagid, antnum, consdetc, arrint, stringsAsFactors = F))
}

parseORFIDmsg = function(line){
  date = as.Date(getDate(line[2]))
  time = as.character(line[3])
  msg = str_c(line, collapse=' ') #line[5:length(line)]
  return(data.frame(date, time, msg, stringsAsFactors = F))
}

parseBiomarkMsg = function(line){
  date = as.Date(getDate(line[4]))
  time = as.character(str_sub(line[5], 1, 11))
  msg = str_c(line, collapse=' ')
  return(data.frame(date, time, msg, stringsAsFactors = F))
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


parseScanLog = function(logFile, tz, dbDir){
  #logFile = logFiles[1]
  print(str_glue('    File: ', logFile))
  bname = basename(logFile)
  archiveFile = suppressWarnings(normalizePath(file.path(archiveDir,str_glue(as.character(Sys.Date()),'_',bname))))
  
  lines = read_lines(logFile)
  
  
  
  # is this file orfid or biomark - need to get site name
  lineLen = length(lines)
  end = ifelse(lineLen < 1000, lineLen, 1000)
  if(length(which(str_detect(lines[1:end], 'Oregon RFID Datalogger') == TRUE)) != 0){
    site = unlist(str_split(basename(logFile),'_'))[1]
    reader = 'ORFID'
    print(str_glue('        Reader: ',reader))
    lineStart = substr(lines, 1, 2)
    
    
    ########## DEAL WITH THE TAG DATA (D CODE)
    dataMaybe = which(lineStart == 'D ')
    dataMaybeLength = length(dataMaybe)
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
        tagDataMatrix = do.call(rbind, tagDataList)
        tagDataDF = as.data.frame(tagDataMatrix) %>%  #cbind(tagDataMatrix, tagDataLines)
          makeORFIDtagDF() %>%
          addInfo(tagDataLines, archiveFile, site, reader)
      }
      
      #... for dates that are good but the number of columns is incorrect, assume they are failed reads and put them in a separate DF
      tagDataFailLines = dataMaybe[which(lens != 8 & !is.na(dateCheck))]
      tagDataFailLinesLength = length(tagDataFailLines)
      if(tagDataFailLinesLength > 0){
        tagDataFailList = spaceDelim(lines[tagDataFailLines])
        tagDataFailDF = do.call("rbind", lapply(tagDataFailList, parseORFIDmsg)) %>%
          addInfo(tagDataFailLines, archiveFile, site, reader)
      }
      
      #... for D codes that have a bad date, put them in a separate DF  ---- NEED TO UNMOCK THIS
      tagDataJunkLines = dataMaybe[which(is.na(dateCheck))]
      tagDataJunkLinesLength = length(tagDataJunkLines)
      if(tagDataJunkLinesLength > 0){
        tagDataJunkVector = lines[tagDataJunkLines] %>%
          sub("\t", " ", .) %>%
          str_squish()
        tagDataJunkDF = data.frame(msg = tagDataJunkVector, stringsAsFactors = F) %>%
          addInfo(tagDataJunkLines, archiveFile, site, reader)
      }
    }
    
    
    ##########  DEAL WITH THE MESSAGE DATA (E AND B CODES)
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
    otherLines = which(lineStart != 'D ' & lineStart != 'E ' & lineStart != 'B ')
    otherLinesLength = length(otherLines)
    if(otherLinesLength > 0){
      otherVector = lines[otherLines] %>%
        sub("\t", " ", .) %>%
        str_squish()
      otherDF = data.frame(msg = otherVector, stringsAsFactors = F) %>%
        addInfo(otherLines, archiveFile, site, reader)
    }
    
    
  } else { #TODO - check to see if this is a biomark reader - we are assuming it is right now
    site = basename(dirname(dirname(logFile)))
    reader = 'Biomark'
    print(str_glue('        Reader: ',reader))
    lineStart = substr(lines, 1, 4)
    
    ########## DEAL WITH THE TAG DATA (TAG: CODE)
    dataMaybe = which(lineStart == 'TAG:')
    dataMaybeLength = length(dataMaybe)
    if(dataMaybeLength > 0){
      dataLines = spaceDelim(lines[dataMaybe])
      
      #...do a check on the date to make sure that its a proper date
      lens = lengths(dataLines)
      date = unlist(lapply(dataLines, function(l) {unlist(l[4])}))
      dateCheck = do.call("c", lapply(date, getDate)) # need to use do.call('c') here to unlist because unlist reformats the date
      
      #... for dates that are good and the number of columns is correct, assume they are tags and put them in a DF
      tagDataLines = dataMaybe[which(lens == 6 & !is.na(dateCheck))]
      tagDataLinesLength = length(tagDataLines)
      if(tagDataLinesLength > 0){
        tagDataList = spaceDelim(lines[tagDataLines])
        tagDataMatrix = do.call(rbind, tagDataList)
        
        #tagDataDF = head(as.data.frame(tagDataMatrix))
        tagDataDF = as.data.frame(tagDataMatrix) %>%  #cbind(tagDataMatrix, tagDataLines)
          makeBiomarkDF() %>%
          addInfo(tagDataLines, archiveFile, site, reader)
      }
      
      #... for dates that are good but the number of columns is incorrect, assume they are failed reads and put them in a separate DF
      tagDataFailLines = dataMaybe[which(lens != 6 & !is.na(dateCheck))]
      tagDataFailLinesLength = length(tagDataFailLines)
      if(tagDataFailLinesLength > 0){
        tagDataFailList = spaceDelim(lines[tagDataFailLines])
        tagDataFailDF = do.call("rbind", lapply(tagDataFailList, parseBiomarkMsg)) %>% 
          addInfo(tagDataFailLines, archiveFile, site, reader)
      }
      
      #... for TAG: codes that have a bad date, put them in a separate DF
      tagDataJunkLines = dataMaybe[which(is.na(dateCheck))]
      tagDataJunkLinesLength = length(tagDataJunkLines)
      if(tagDataJunkLinesLength > 0){
        tagDataJunkVector = lines[tagDataJunkLines] %>%
          sub("\t", " ", .) %>%
          str_squish()
        tagDataJunkDF = data.frame(msg = tagDataJunkVector, stringsAsFactors = F) %>%
          addInfo(tagDataJunkLines, archiveFile, site, reader)
      }
      
      
    }
    
    
    ##########  DEAL WITH THE MESSAGE DATA (ALM, NRP, SRP AND MSG CODES)
    msgMaybe = which(lineStart == 'ALM:' | lineStart == 'NRP:' | lineStart == 'SRP:' | lineStart == 'MSG:')
    msgMaybeLength = length(msgMaybe)
    if(dataMaybeLength > 0){
      msgLines = spaceDelim(lines[msgMaybe])
      
      #...do a check on the date to make sure that its a proper date
      lens = lengths(msgLines)
      date = unlist(lapply(msgLines, function(l) {unlist(l[4])}))
      dateCheck = do.call("c", lapply(date, getDate)) # need to use do.call('c') here to unlist because unlist reformats the date
      
      #... for dates that are good, assume they are messages and put them in a DF
      msgDataLines = msgMaybe[which(!is.na(dateCheck))]
      msgDataLinesLength = length(msgDataLines)
      if(msgDataLinesLength > 0){
        msgDataList = spaceDelim(lines[msgDataLines])
        msgDataDF = do.call("rbind", lapply(msgDataList, parseBiomarkMsg)) %>%
          addInfo(msgDataLines, archiveFile, site, reader)
      }
      
      #... for ALM, NRP, SRP and MSG codes that have a bad date, put them in a separate DF
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
    otherLines = which(lineStart != 'TAG:' & lineStart != 'ALM:' & lineStart != 'NRP:' & lineStart != 'SRP:' & lineStart != 'MSG:')
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
  tagDataFailDFfile = file.path(dbDir,'tagFailDB.csv')
  tagDataJunkDFfile = file.path(dbDir,'tagBadDB.csv')
  msgDataDFfile = file.path(dbDir,'msgDB.csv')
  msgDataJunkDFfile = file.path(dbDir,'msgBadDB.csv')
  otherDFfile = file.path(dbDir,'otherDB.csv')
  logFile = file.path(dbDir,'logDB.csv')
  
  # write them out
  if(exists('tagDataDF')){
    writeDF(tagDataDF, tagDataDFfile)
    tagDataDFnrow = nrow(tagDataDF)
    tagDataDFpercent = round((tagDataDFnrow/lineLen)*100)
  } else {
    tagDataDFnrow = 0
    tagDataDFpercent = 0
  }
  print(str_glue('        Tag lines: ', as.character(tagDataDFpercent),'%'))
  
  if(exists('tagDataFailDF')){
    writeDF(tagDataFailDF, tagDataFailDFfile)
    tagDataFailDFnrow = nrow(tagDataFailDF)
    tagDataFailDFpercent = as.character(round((tagDataFailDFnrow/lineLen)*100,2))
  } else {
    tagDataFailDFnrow = 0
    tagDataFailDFpercent = 0
  }
  print(str_glue('        Tag fail lines: ', as.character(tagDataFailDFpercent),'%'))
  
  if(exists('tagDataJunkDF')){
    writeDF(tagDataJunkDF, tagDataJunkDFfile)
    tagDataJunkDFnrow = nrow(tagDataJunkDF)
    tagDataJunkDFpercent = as.character(round((tagDataJunkDFnrow/lineLen)*100,2))
  } else {
    tagDataJunkDFnrow = 0
    tagDataJunkDFpercent = 0
  }
  print(str_glue('        Tag bad lines: ', as.character(tagDataJunkDFpercent),'%'))
  
  if(exists('msgDataDF')){
    writeDF(msgDataDF, msgDataDFfile)
    msgDataDFnrow = nrow(msgDataDF)
    msgDataDFpercent = as.character(round((msgDataDFnrow/lineLen)*100,2))
  } else {
    msgDataDFnrow = 0
    msgDataDFpercent = 0
  }
  print(str_glue('        Message lines: ', as.character(msgDataDFpercent),'%'))
  
  if(exists('msgDataJunkDF')){
    writeDF(msgDataJunkDF, msgDataJunkDFfile)
    msgDataJunkDFnrow = nrow(msgDataJunkDF)
    msgDataJunkDFpercent = as.character(round((msgDataJunkDFnrow/lineLen)*100,2))
  } else {
    msgDataJunkDFnrow = 0
    msgDataJunkDFpercent = 0
  }
  print(str_glue('        Message bad lines: ', as.character(msgDataJunkDFpercent),'%'))
  
  if(exists('otherDF')){
    writeDF(otherDF, otherDFfile)
    otherDFnrow = nrow(otherDF)
    otherDFpercent = as.character(round((otherDFnrow/lineLen)*100,2))
  } else {
    otherDFnrow = 0
    otherDFpercent = 0
  }
  print(str_glue('        Other lines: ', as.character(otherDFpercent),'%'))
  
  
  logDF = data.frame(
    site=site,
    reader=reader, 
    fname=archiveFile, 
    dateadded=Sys.Date(), 
    tagpct=tagDataDFpercent,
    tagfailpct=tagDataFailDFpercent,
    tagbadpct=tagDataJunkDFpercent,
    msgpct=msgDataDFpercent,
    msgbadpct=msgDataJunkDFpercent,
    otherpct=otherDFpercent,
    tagnrow=tagDataDFnrow,
    tagfailnrow=tagDataFailDFnrow,
    tagbadnrow=tagDataJunkDFnrow,
    msgnrow=msgDataDFnrow,
    msgbadnrow=msgDataJunkDFnrow,
    othernrow=otherDFnrow,
    totalnrow=lineLen,
    stringsAsFactors = F
  )
  
  write_csv(logDF, logFile, append=T)
  
  # move the file to the archive
  #file.rename(logFile, archiveFile)
  
}

PITcompile = function(dataDir, dbDir, timeZone){
  siteDirs = normalizePath(list.dirs(dataDir, recursive = F))
  tz = timeZone
  
  for(dir in siteDirs){
    print(str_glue('Site: ', dir))
    downloadDir = normalizePath(file.path(dir,"downloads"))
    archiveDir = normalizePath(file.path(dir,"archive"))
    logFiles = normalizePath(list.files(downloadDir, '*', full.names = T))
    if(length(logFiles) != 0){
      for(logFile in logFiles){
        parseScanLog(logFile, tz, dbDir)
      }
    } else {
      print(str_glue('    No log files for this site'))
      next
    }
  }
}



###############################################################################################################
###############################################################################################################
###############################################################################################################

dataDir = "C:\\Users\\braatenj\\Documents\\GitHub\\pit-tag-data-compile\\example"
dbDir = "C:\\Users\\braatenj\\Documents\\GitHub\\pit-tag-data-compile\\example"
timeZone = "America/Los_Angeles"



###############################################################################################################
###############################################################################################################
###############################################################################################################


siteDirs = normalizePath(list.dirs(dataDir, recursive = F))
tz = timeZone

for(dir in siteDirs){
  #dir = siteDirs[2]
  print(str_glue('Site: ', dir))
  downloadDir = normalizePath(file.path(dir,"downloads"))
  archiveDir = normalizePath(file.path(dir,"archive"))
  logFiles = normalizePath(list.files(downloadDir, '*', full.names = T))
  
  # if log files then parse it, else next
  if(length(logFiles) != 0){
    for(logFile in logFiles){
      
      parseScanLog(logFile, tz, dbDir)
      
      
      # logFile = logFiles[1]
      # print(str_glue('    File: ', logFile))
      # bname = basename(logFile)
      # archiveFile = suppressWarnings(normalizePath(file.path(archiveDir,str_glue(as.character(Sys.Date()),'_',bname))))
      # 
      # lines = read_lines(logFile)
      # 
      # 
      # 
      # # is this file orfid or biomark - need to get site name
      # lineLen = length(lines)
      # end = ifelse(lineLen < 100, lineLen, 100)
      # if(length(which(str_detect(lines[1:end], 'Oregon RFID Datalogger') == TRUE)) != 0){
      #   site = unlist(str_split(basename(logFile),'_'))[1]
      #   reader = 'ORFID'
      #   lineStart = substr(lines, 1, 2)
      #   
      #   
      #   ########## DEAL WITH THE TAG DATA (D CODE)
      #   dataMaybe = which(lineStart == 'D ')
      #   dataMaybeLength = length(dataMaybe)
      #   if(dataMaybeLength > 0){
      #     dataLines = spaceDelim(lines[dataMaybe])
      #     
      #     #...do a check on the date to make sure that its a proper date
      #     lens = lengths(dataLines)
      #     date = unlist(lapply(dataLines, function(l) {unlist(l[2])}))
      #     dateCheck = do.call("c", lapply(date, getDate)) # need to use do.call('c') here to unlist because unlist reformats the date
      #     
      #     #... for dates that are good and the number of columns is correct, assume they are tags and put them in a DF
      #     tagDataLines = dataMaybe[which(lens == 8 & !is.na(dateCheck))]
      #     tagDataLinesLength = length(tagDataLines)
      #     if(tagDataLinesLength > 0){
      #       tagDataList = spaceDelim(lines[tagDataLines])
      #       tagDataMatrix = do.call(rbind, tagDataList)
      #       tagDataDF = as.data.frame(tagDataMatrix) %>%  #cbind(tagDataMatrix, tagDataLines)
      #         makeORFIDtagDF() %>%
      #         addInfo(tagDataLines, archiveFile, site, reader)
      #     }
      #     
      #     #... for dates that are good but the number of columns is incorrect, assume they are failed reads and put them in a separate DF
      #     tagDataFailLines = dataMaybe[which(lens != 8 & !is.na(dateCheck))]
      #     tagDataFailLinesLength = length(tagDataFailLines)
      #     if(tagDataFailLinesLength > 0){
      #       tagDataFailList = spaceDelim(lines[tagDataFailLines])
      #       tagDataFailDF = do.call("rbind", lapply(tagDataFailList, parseORFIDmsg)) %>%
      #         addInfo(tagDataFailLines, archiveFile, site, reader)
      #     }
      #     
      #     #... for D codes that have a bad date, put them in a separate DF  ---- NEED TO UNMOCK THIS
      #     tagDataJunkLines = dataMaybe[which(is.na(dateCheck))]
      #     tagDataJunkLinesLength = length(tagDataJunkLines)
      #     if(tagDataJunkLinesLength > 0){
      #       tagDataJunkVector = lines[tagDataJunkLines] %>%
      #         sub("\t", " ", .) %>%
      #         str_squish()
      #       tagDataJunkDF = data.frame(msg = tagDataJunkVector, stringsAsFactors = F) %>%
      #         addInfo(tagDataJunkLines, archiveFile, site, reader)
      #     }
      #   }
      #   
      # 
      #   ##########  DEAL WITH THE MESSAGE DATA (E AND B CODES)
      #   msgMaybe = which(lineStart == 'E ' | lineStart == 'B ')
      #   msgMaybeLength = length(msgMaybe)
      #   if(msgMaybeLength > 0){
      #     msgLines = spaceDelim(lines[msgMaybe])
      #     
      #     #...do a check on the date to make sure that its a proper date
      #     date = unlist(lapply(msgLines, function(l) {unlist(l[2])}))
      #     dateCheck = do.call("c", lapply(date, getDate)) # need to use do.call('c') here to unlist because unlist reformats the date
      #     
      #     #... for dates that are good, assume they are messages and put them in a DF
      #     msgDataLines = msgMaybe[which(!is.na(dateCheck))]
      #     msgDataLinesLength = length(msgDataLines)
      #     if(msgDataLinesLength > 0){
      #       msgDataList = spaceDelim(lines[msgDataLines])
      #       msgDataDF = do.call("rbind", lapply(msgDataList, parseORFIDmsg)) %>%
      #         addInfo(msgDataLines, archiveFile, site, reader)
      #     }
      #     
      #     #... for E and B codes that have a bad date, put them in a separate DF
      #     msgDataJunkLines = msgMaybe[which(is.na(dateCheck))]
      #     msgDataJunkLinesLength = length(msgDataJunkLines)
      #     if(msgDataJunkLinesLength > 0){
      #       msgDataJunkVector = lines[msgDataJunkLines] %>%
      #         sub("\t", " ", .) %>%
      #         str_squish()
      #       msgDataJunkDF = data.frame(msg = msgDataJunkVector, stringsAsFactors = F) %>%
      #         addInfo(msgDataJunkLines, archiveFile, site, reader)
      #     }
      #   }
      #   
      # 
      #   ##########  DEAL WITH OTHER
      #   otherLines = which(lineStart != 'D ' & lineStart != 'E ' & lineStart != 'B ')
      #   otherLinesLength = length(otherLines)
      #   if(otherLinesLength > 0){
      #     otherVector = lines[otherLines] %>%
      #       sub("\t", " ", .) %>%
      #       str_squish()
      #     otherDF = data.frame(msg = otherVector, stringsAsFactors = F) %>%
      #       addInfo(otherLines, archiveFile, site, reader)
      #   }
      #   
      #   
      # } else {
      #   site = basename(dirname(dirname(logFile)))
      #   reader = 'Biomark'
      #   lineStart = substr(lines, 1, 4)
      # 
      #   ########## DEAL WITH THE TAG DATA (TAG: CODE)
      #   dataMaybe = which(lineStart == 'TAG:')
      #   dataMaybeLength = length(dataMaybe)
      #   if(dataMaybeLength > 0){
      #     dataLines = spaceDelim(lines[dataMaybe])
      #     
      #     #...do a check on the date to make sure that its a proper date
      #     lens = lengths(dataLines)
      #     date = unlist(lapply(dataLines, function(l) {unlist(l[4])}))
      #     dateCheck = do.call("c", lapply(date, getDate)) # need to use do.call('c') here to unlist because unlist reformats the date
      #     
      #     #... for dates that are good and the number of columns is correct, assume they are tags and put them in a DF
      #     tagDataLines = dataMaybe[which(lens == 6 & !is.na(dateCheck))]
      #     tagDataLinesLength = length(tagDataLines)
      #     if(tagDataLinesLength > 0){
      #       tagDataList = spaceDelim(lines[tagDataLines])
      #       tagDataMatrix = do.call(rbind, tagDataList)
      #       
      #       #tagDataDF = head(as.data.frame(tagDataMatrix))
      #       tagDataDF = as.data.frame(tagDataMatrix) %>%  #cbind(tagDataMatrix, tagDataLines)
      #         makeBiomarkDF() %>%
      #         addInfo(tagDataLines, archiveFile, site, reader)
      #     }
      #     
      #     #... for dates that are good but the number of columns is incorrect, assume they are failed reads and put them in a separate DF
      #     tagDataFailLines = dataMaybe[which(lens != 6 & !is.na(dateCheck))]
      #     tagDataFailLinesLength = length(tagDataFailLines)
      #     if(tagDataFailLinesLength > 0){
      #       tagDataFailList = spaceDelim(lines[tagDataFailLines])
      #       tagDataFailDF = do.call("rbind", lapply(tagDataFailList, parseBiomarkMsg)) %>% 
      #         addInfo(tagDataFailLines, archiveFile, site, reader)
      #     }
      #     
      #     #... for TAG: codes that have a bad date, put them in a separate DF
      #     tagDataJunkLines = dataMaybe[which(is.na(dateCheck))]
      #     tagDataJunkLinesLength = length(tagDataJunkLines)
      #     if(tagDataJunkLinesLength > 0){
      #       tagDataJunkVector = lines[tagDataJunkLines] %>%
      #         sub("\t", " ", .) %>%
      #         str_squish()
      #       tagDataJunkDF = data.frame(msg = tagDataJunkVector, stringsAsFactors = F) %>%
      #         addInfo(tagDataJunkLines, archiveFile, site, reader)
      #     }
      #     
      # 
      #   }
      #   
      #   
      #   ##########  DEAL WITH THE MESSAGE DATA (ALM, NRP, SRP AND MSG CODES)
      #   msgMaybe = which(lineStart == 'ALM:' | lineStart == 'NRP:' | lineStart == 'SRP:' | lineStart == 'MSG:')
      #   msgMaybeLength = length(msgMaybe)
      #   if(dataMaybeLength > 0){
      #     msgLines = spaceDelim(lines[msgMaybe])
      #     
      #     #...do a check on the date to make sure that its a proper date
      #     lens = lengths(msgLines)
      #     date = unlist(lapply(msgLines, function(l) {unlist(l[4])}))
      #     dateCheck = do.call("c", lapply(date, getDate)) # need to use do.call('c') here to unlist because unlist reformats the date
      #     
      #     #... for dates that are good, assume they are messages and put them in a DF
      #     msgDataLines = msgMaybe[which(!is.na(dateCheck))]
      #     msgDataLinesLength = length(msgDataLines)
      #     if(msgDataLinesLength > 0){
      #       msgDataList = spaceDelim(lines[msgDataLines])
      #       msgDataDF = do.call("rbind", lapply(msgDataList, parseBiomarkMsg)) %>%
      #         addInfo(msgDataLines, archiveFile, site, reader)
      #     }
      #     
      #     #... for ALM, NRP, SRP and MSG odes that have a bad date, put them in a separate DF
      #     msgDataJunkLines = msgMaybe[which(is.na(dateCheck))]
      #     msgDataJunkLinesLength = length(msgDataJunkLines)
      #     if(msgDataJunkLinesLength > 0){
      #       msgDataJunkVector = lines[msgDataJunkLines] %>%
      #         sub("\t", " ", .) %>%
      #         str_squish()
      #       msgDataJunkDF = data.frame(msg = msgDataJunkVector, stringsAsFactors = F) %>%
      #         addInfo(msgDataJunkLines, archiveFile, site, reader)
      #     }
      #   }
      #   
      #   ##########  DEAL WITH OTHER
      #   otherLines = which(lineStart != 'TAG:' | lineStart != 'ALM:' | lineStart != 'NRP:' | lineStart != 'SRP:' | lineStart != 'MSG:')
      #   otherLinesLength = length(otherLines)
      #   if(otherLinesLength > 0){
      #     otherVector = lines[otherLines] %>%
      #       sub("\t", " ", .) %>%
      #       str_squish()
      #     otherDF = data.frame(msg = otherVector, stringsAsFactors = F) %>%
      #       addInfo(otherLines, archiveFile, site, reader)
      #   }
      # 
      # }
      # 
      # # write out the files here
      # # make file names
      # tagDataDFfile = file.path(dbDir,'tagDB.csv')
      # tagDataFailDFfile = file.path(dbDir,'tagFailDB.csv')
      # tagDataJunkDFfile = file.path(dbDir,'tagBadDB.csv')
      # msgDataDFfile = file.path(dbDir,'msgDB.csv')
      # msgDataJunkDFfile = file.path(dbDir,'msgBadDB.csv')
      # otherDFfile = file.path(dbDir,'otherDB.csv')
      # logFile = file.path(dbDir,'logDB.csv')
      # 
      # # write them out
      # lineLen = length(lines)
      # if(exists('tagDataDF')){
      #   writeDF(tagDataDF, tagDataDFfile)
      #   tagDataDFnrow = nrow(tagDataDF)
      #   tagDataDFpercent = round((tagDataDFnrow/lineLen)*100)
      # } else {
      #   tagDataDFnrow = 0
      #   tagDataDFpercent = 0
      # }
      # print(str_glue('        % tag lines: ', as.character(tagDataDFpercent)))
      # 
      # if(exists('tagDataFailDF')){
      #   writeDF(tagDataFailDF, tagDataFailDFfile)
      #   tagDataFailDFnrow = nrow(tagDataFailDF)
      #   tagDataFailDFpercent = as.character(round((tagDataFailDFnrow/lineLen)*100))
      # } else {
      #   tagDataFailDFnrow = 0
      #   tagDataFailDFpercent = 0
      # }
      # print(str_glue('        % tag fail lines: ', as.character(tagDataFailDFpercent)))
      # 
      # if(exists('tagDataJunkDF')){
      #   writeDF(tagDataJunkDF, tagDataJunkDFfile)
      #   tagDataJunkDFnrow = nrow(tagDataJunkDF)
      #   tagDataJunkDFpercent = as.character(round((tagDataJunkDFnrow/lineLen)*100))
      # } else {
      #   tagDataJunkDFnrow = 0
      #   tagDataJunkDFpercent = 0
      # }
      # print(str_glue('        % tag junk lines: ', as.character(tagDataJunkDFpercent)))
      # 
      # if(exists('msgDataDF')){
      #   writeDF(msgDataDF, msgDataDFfile)
      #   msgDataDFnrow = nrow(msgDataDF)
      #   msgDataDFpercent = as.character(round((msgDataDFnrow/lineLen)*100))
      # } else {
      #   msgDataDFnrow = 0
      #   msgDataDFpercent = 0
      # }
      # print(str_glue('        % message lines: ', as.character(msgDataDFpercent)))
      # 
      # if(exists('msgDataJunkDF')){
      #   writeDF(msgDataJunkDF, msgDataJunkDFfile)
      #   msgDataJunkDFnrow = nrow(msgDataJunkDF)
      #   msgDataJunkDFpercent = as.character(round((msgDataJunkDFnrow/lineLen)*100))
      # } else {
      #   msgDataJunkDFnrow = 0
      #   msgDataJunkDFpercent = 0
      # }
      # print(str_glue('        % message junk lines: ', as.character(msgDataJunkDFpercent)))
      # 
      # if(exists('otherDF')){
      #   writeDF(otherDF, otherDFfile)
      #   otherDFnrow = nrow(otherDF)
      #   otherDFpercent = as.character(round((otherDFnrow/lineLen)*100))
      # } else {
      #   otherDFnrow = 0
      #   otherDFpercent = 0
      # }
      # print(str_glue('        % other lines: ', as.character(otherDFpercent)))
      # 
      # 
      # logDF = data.frame(
      #   site=site,
      #   reader=reader, 
      #   fname=archiveFile, 
      #   dateadded=Sys.Date(), 
      #   tagpct=tagDataDFpercent,
      #   tagfailpct=tagDataFailDFpercent,
      #   tagbadpct=tagDataJunkDFpercent,
      #   msgpct=msgDataDFpercent,
      #   msgbadpct=msgDataJunkDFpercent,
      #   otherpct=otherDFpercent,
      #   tagnrow=tagDataDFnrow,
      #   tagfailnrow=tagDataFailDFnrow,
      #   tagbadnrow=tagDataJunkDFnrow,
      #   msgnrow=msgDataDFnrow,
      #   msgbadnrow=msgDataJunkDFnrow,
      #   othernrow=otherDFnrow,
      #   totalnrow=lineLen,
      #   stringsAsFactors = F
      # )
      # 
      # write_csv(logDF, logFile, append=T)
      # 
      # # move the file to the archive
      # #file.rename(logFile, archiveFile)
      
    }
    
  } else {
    print(str_glue('    No log files for this site'))
    next
  }
}





