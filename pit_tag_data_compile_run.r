
#####################################################################################################################
### INPUTS ##########################################################################################################
#####################################################################################################################

functionsPath = "C:/Users/HaleyOhms/.../pit_tag_data_compile_functions.r"
dataDir = "C:/Users/HaleyOhms/.../example"
dbDir = "C:/Users/HaleyOhms/.../example"
timeZone = "America/Los_Angeles"


#####################################################################################################################


source(functionsPath)  
PITcompile(dataDir, dbDir, timeZone)
rmdups(dbDir)



