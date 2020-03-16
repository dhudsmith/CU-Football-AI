#clear global environment
rm(list=ls())

library(data.table)
library(lubridate)

# Time zone correction factor:
tz_corr <- 20

#load in aligned measurement times
# mtimes <- file.choose(new = F)
mtimes <- "aligned_player_velocities-missingvals_deleted.csv"
measurement <- (fread(mtimes)[,2])
measurement <- format(as.POSIXct(as_datetime(
  measurement$TimeStamp,format = "%I:%M:%S %p"))+hours(tz_corr),"%H:%M:%S")

#load in start/stop times
# stimes <- file.choose(new = F)
stimes <- "2019 season play times.csv"
start <- fread(stimes)[,6]
stop <- fread(stimes)[,7]

count = 1
inplay = matrix(0,length(measurement),1)
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
}

df <- read.csv(file = mtimes)
df$inplay <- inplay
write.csv(df,"inplay-determined.csv")