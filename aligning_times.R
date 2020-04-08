library(lubridate)
library(dplyr)
library(reshape2)
library(ggplot2)

rm(list=ls())

setwd('C:/Users/Carl/Documents/R/project_football')

##
## Prove logic of loading data and formatting time stamps

data_files <- list.files('TAM/', pattern='*.csv', full.names = TRUE)

# read first line with reference time and convert into a time format (UTC timezone)
con <- file(data_files[1], 'r')
line <- readLines(con, n=1)
close(con)
rm(con)

time <- strsplit(line, ': ')[[1]][2]
time_ld <- lubridate::mdy_hms(time)
str(time_ld)

# read in datafile and shift all times by reference time
df <- readr::read_csv(data_files[1], skip=3, col_types = paste('t',paste(rep('d',26),collapse = ""),sep=''))
# warning: may be losing data. See parsing failures in readr output
# df_copy <- df
# df <- df_copy

df <- df %>% mutate(TimeStamp = time_ld + TimeStamp)

df %>% head() %>% View()
# note: may be losing data for hundredths of seconds
# may be better to use centiseconds


##
## Sytematically apply above logic 

fn_readPlayerData <- function(full_path){
  con <- file(full_path, 'r')
  line <- readLines(con, n=1)
  close(con)
  rm(con)
  
  time <- strsplit(line, ': ')[[1]][2]
  time_ld <- lubridate::mdy_hms(time)
  
  # read in datafile and shift all times by reference time
  df <- readr::read_csv(full_path, skip=3, col_types = paste('t',paste(rep('d',26),collapse = ""),sep=''))
  # warning: may be losing data. See parsing failures in readr output
  # df_copy <- df
  # df <- df_copy
  
  df <- df %>% mutate(TimeStamp = time_ld + lubridate::hms(TimeStamp))
  df$player <- full_path
  
  return(df)
}

fn_readPlayerData(data_files[1]) %>% head() %>% View()

# apply function to all of the data
df_all <- plyr::ldply(data_files, fn_readPlayerData)

##
## reshape the data with players as columns

# split - apply - combine workflow:
# split: group to unique player, second
# apply: take the average velocity
# combine: create a new dataframe 
df_all_agg <-
  df_all %>%
  filter(!is.na(RawVelocity)) %>%
  dplyr::group_by(TimeStamp=lubridate::ymd_hms(TimeStamp), player) %>%
  dplyr::summarise(
    mean_velocity = mean(RawVelocity, na.rm=TRUE),
#    mean_heart_rate = mean(HeartRate)
  )

# turn single player column into multiple columns
df_wide <- 
  df_all_agg %>%
  melt(id.vars = c('TimeStamp', 'player')) %>% 
  dcast(TimeStamp ~ player + variable)

readr::write_csv(df_wide, "aligned_player_velocities.csv")

df_all_agg %>% 
  group_by(TimeStamp) %>%
  summarize(mean_velocity = mean(mean_velocity, na.rm = T)) %>%
  ggplot(aes(x=TimeStamp, y=mean_velocity)) +
  geom_point()
  

