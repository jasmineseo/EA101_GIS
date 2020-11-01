################################################

# Setup
install.packages("devtools")
install.packages("AirSensor")
install.packages("dplyr")


library(devtools) # install if needed
library(dplyr)

install_github("MazamaScience/AirSensor")
# choose 1 for update all
# analyze low-cost sensors 

#################################3

library(AirSensor)
library(stringr)
library(rlang)
library(openair)
library(worldmet)


setArchiveBaseUrl("http://smoke.mazamascience.com/data/PurpleAir")


####################################################

# functiont that converts PM2.5 concentration to AQI
pm_to_aqi <- function(pm){
  if (is.na(pm)) return (NA)
  if (pm < 0) return (pm)
  if (pm > 1000) return (NA)
  
  ih <- 0
  il <- 0
  ch <- 0
  cl <- 0
  if (pm > 350.5) {
    ih <- 500
    il <- 401
    ch <- 500
    cl <- 350.5
  } else if (pm > 250.5) {
    ih <- 400
    il <- 301
    ch <- 350.4
    cl <- 250.5
  } else if (pm > 150.5) {
    ih <- 300
    il <- 201
    ch <- 250.4
    cl <- 150.5
  } else if (pm > 55.5) {
    ih <- 200
    il <- 151
    ch <- 150.4
    cl <- 55.5
  } else if (pm > 35.5) {
    ih <- 150
    il <- 101
    ch <- 55.4
    cl <- 35.5
  } else if (pm > 12.1) {
    ih <- 100
    il <- 51
    ch <- 35.4
    cl <- 12.1
  } else if (pm >= 0) {
    ih <- 50
    il <- 0
    ch <- 12
    cl <- 0
  } else {
    return (NA)
  }
  
  aqi = round((ih-il)/(ch-cl)*(pm-cl)) + il
  return (aqi)
}

# function that converts time seires PM2.5 concentration to AQI
pm_to_aqi_time_series <- function(pm_time_series){
  aqi <- c()
  for (row in 1:nrow(pm_time_series)){
    currAQI <- pm_to_aqi(pm_time_series[row, 2])
    aqi <- append(aqi, currAQI)
  }
  pm_time_series$AQI <- aqi
  return (pm_time_series)
}


####################################################

#loads most recent pas
pas <- pas_load()

# loads a version of the pas that includes every sensor installed (i.e., inactive ones)
#pas <- pas_load("20191010", archival = TRUE)


# map
pas_leaflet(pas)

####################################################

# filter 10 sensors near Clarmeont
claremont <- pas %>% pas_filterArea(w = -117.76, e = -117.65, s = 34.07, n = 34.145)
pas_leaflet(claremont)
#remove their B channel
claremont_A <- claremont %>% pas_filter(str_detect(label, "[B]$", negate=TRUE))


# # for each of 10 sensors: get hourly PM2.5 data between 11/4 and 11/10
# for (row in 1:nrow(claremont_A)) {
#   currentSensorName <- paste("claremont_sensor", row, sep="")
#   sensorName <- claremont_A$label[row]
#   # get timeseries data
#   currentPat <- pat_createNew(pas, sensorName, startdate = 20191202, enddate = 20191208)
#   currentSensor <- pat_createAirSensor(currentPat, period="1 hour", parameter = "pm25", qc_algorithm = "hourly_AB_01", min_count = 20)
#   currentSensorData <- currentSensor$data
#   currentSensorData <- pm_to_aqi_time_series(currentSensorData)
# 
#   currentFileName <- paste(currentSensorName, "_20191202_20191208.csv", sep="")
#   currentFileName <- paste("Documents/Harvey\ Mudd/2019-2020/Fall\ 2019/EA101/final\ project/data/",currentFileName, sep="")
#   # assign(currentFileName, currentSensorData)
#   write.csv(currentSensorData,currentFileName)
# }

# for each of 10 sensors: get hourly PM2.5 data between 12/2 and 12/9 and compile to one csv
fileName <- ""

columns <- c("datetime", "PM2.5", "AQI", "latitude", "longitude")
df <- data.frame(datetime=double(), PM2.5=double(), AQI = integer(), latitude=double(), longitude=double() )
for (row in 1:nrow(claremont_A)) {

  # get sensor info
  sensorName <- claremont_A$label[row]
  currLat <- claremont_A$latitude[row]
  currLong <- claremont_A$longitude[row]
  
  # get timeseries data (12/18-12/20)
  currentPat <- pat_createNew(pas, sensorName, startdate = 20191218, enddate = 20191220)
  currentSensor <- pat_createAirSensor(currentPat, period="15 min", parameter = "pm25", qc_algorithm = "hourly_AB_01", min_count = 20)
  
  # get timeseries data (12/02-12/08)
  # currentPat <- pat_createNew(pas, sensorName, startdate = 20191202, enddate = 20191208)
  # currentSensor <- pat_createAirSensor(currentPat, period="1 hour", parameter = "pm25", qc_algorithm = "hourly_AB_01", min_count = 20)
  currentSensorData <- currentSensor$data
  # convert to AQI
  currentSensorData <- pm_to_aqi_time_series(currentSensorData)
  # compile to df
  currentSensorData$latitude <- rep(currLat,nrow(currentSensorData))
  currentSensorData$longitude <- rep(currLong,nrow(currentSensorData))
  colnames(currentSensorData) <- columns # rename columns
  df <- rbind(df, currentSensorData) # combine into one file
}
# 10 sensors in Claremont 12/2-12/9
write.csv(df,"Documents/Harvey\ Mudd/2019-2020/Fall\ 2019/EA101/final\ project/data2/claremont_sensors_compiled.csv")
# sensors in Claremont
write.csv(claremont_A,"Documents/Harvey\ Mudd/2019-2020/Fall\ 2019/EA101/final\ project/data2/claremont_sensors.csv")
# sensor <- pat_createAirSensor(example_pat, period = "1 hour", parameter = "pm25", qc_algorithm = "hourly_AB_01", min_count = 20)

