

library(tidyverse)


# define the data compilation file path 
inFile = "D:\\work\\proj\\pittag\\all_pit_data\\tagDBclean.csv"




# read in the date
df = read_csv(inFile, col_names = F)

# print the unique tag ids
uniIDs = unique(df$X9)
print(uniIDs)

# print how many unique ids
length(uniIDs)

# get count per unique tag id
countsPertag = as.data.frame(dplyr::count(df, X9))
print(countsPertag)