#clear global environment
rm(list=ls())

library(data.table)
library(lubridate)

# Time zone correction factor:
tz_corr <- 8

#load in aligned measurement times
# mtimes <- file.choose(new = F)
mtimes <- "C:\\Users\\carle\\R\\project_football\\inplay-determined-MissingValuesDeleted-TimeStamp.csv"
measurement <- (fread(mtimes)[,2])
measurement <- format(as.POSIXct(as_datetime(
  measurement$TimeStamp,format = "%H:%M:%S"))+hours(tz_corr),"%H:%M:%S")

#load in start/stop times
# stimes <- file.choose(new = F)
stimes <- "C:\\Users\\carle\\R\\project_football\\2019 season play times.csv"
start <- fread(stimes)[,6]
stop <- fread(stimes)[,7]

count = 1
inplay = matrix(NA,length(measurement),1)
pprint <- 1
for (i in 1:length(measurement)){
  if (measurement[i] > start$`Start Time`[count] & measurement[i] < 
      stop$`Stop Time`[count]){
    inplay[i] <- 1
  }
  else if(measurement[i] >= stop$`Stop Time`[count] & measurement[i] <= 
          start$`Start Time`[count+1]){
    count <- count + 1
    if (measurement[i] > start$`Start Time`[count] & measurement[i] < 
        stop$`Stop Time`[count]){
      inplay[i] <- 1
    }
  }
  if (count==57 & pprint <200) {
    print(measurement[i])
    pprint <- pprint + 1
    print(inplay[i])
    print(start$`Start Time`[count])
    print(stop$`Stop Time`[count])
  }
}

df <- read.csv(file = mtimes)
df$inplay <- inplay
write.csv(df,"inplay-determined.csv")