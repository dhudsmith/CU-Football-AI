library(lubridate)
library(dplyr)
library(reshape2)
library(ggplot2)

rm(list=ls())

setwd('C:/Users/Carl/Documents/R/project_football')

##
## Prove logic of loading data and formatting time stamps

data_files <- list.files('TAM/', pattern='*.csv', full.names = TRUE)


#################################
# THIS SECTION JUST FOR TESTING #
#################################

# # read first line with reference time and convert into a time format (UTC timezone)
# con <- file(data_files[1], 'r')
# line <- readLines(con, n=1)
# close(con)
# rm(con)
# 
# time <- strsplit(line, ': ')[[1]][2]
# time_ld <- lubridate::mdy_hms(time)
# str(time_ld)
# 
# # read in datafile and shift all times by reference time
# df <- readr::read_csv(data_files[1], skip=3, col_types = paste('t',paste(rep('d',26),collapse = ""),sep=''))
# # warning: may be losing data. See parsing failures in readr output
# # df_copy <- df
# # df <- df_copy
# 
# df <- df %>% mutate(TimeStamp = time_ld + TimeStamp)
# 
# df %>% head() %>% View()
# # note: may be losing data for hundredths of seconds
# # may be better to use centiseconds

##################################
# ABOVE SECTION JUST FOR TESTING #
##################################


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

# fn_readPlayerData(data_files[1]) %>% head() %>% View()

# Running into memory overload issues. Have to split the data files into chunks.
max_chunk_size = 8 #### MODIFY: LARGER = FASTER, BUT TAKES MORE MEMORY. IF MEMORY FAILURE OCCURS, LOWER.
data_files_chunked <- split(data_files, ceiling(seq_along(data_files)/max_chunk_size))
dfc_length <- length(data_files_chunked)
aligned_player_velocity_csv_filenames <- NULL
aligned_player_velocity_playercounts <- NULL

# apply function to all of the data
for (i in seq_along(data_files_chunked)) {
  chunk <- data_files_chunked[[i]]
  length_of_chunk <- length(chunk)
  df_all <- plyr::ldply(chunk, fn_readPlayerData)
  
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
  rm(df_all)
  
  # turn single player column into multiple columns
  df_wide <- 
    df_all_agg %>%
    melt(id.vars = c('TimeStamp', 'player')) %>% 
    dcast(TimeStamp ~ player + variable)
  rm(df_all_agg)
  
  # Write processed chunk to csv
  csv_name <- paste('aligned_player_velocities_chunk_',i,'_of_',dfc_length,sep='')
  readr::write_csv(df_wide, csv_name)
  rm(df_wide)
  
  # Record the name of the csv
  aligned_player_velocity_csv_filenames <- c(aligned_player_velocity_csv_filenames,csv_name)
  aligned_player_velocity_playercounts <- c(aligned_player_velocity_playercounts,length_of_chunk)
}


# Now try to combine them (might have memory problems here again):
csv_name <- aligned_player_velocity_csv_filenames[1]
csv_size <- aligned_player_velocity_playercounts[1]
df <- readr::read_csv(csv_name, 
                      col_types = paste('T',paste(rep('d',csv_size),collapse = ""),sep=''))
while (length(aligned_player_velocity_csv_filenames) > 1) {
  aligned_player_velocity_csv_filenames <- aligned_player_velocity_csv_filenames[-1]
  aligned_player_velocity_playercounts <- aligned_player_velocity_playercounts[-1]
  df <- merge(x=df, 
              y=readr::read_csv(
                aligned_player_velocity_csv_filenames[1],
                col_types = paste('T',paste(rep('d',aligned_player_velocity_playercounts[1]),
                                            collapse = ""),sep='')),
              by="TimeStamp",all=TRUE)
}
readr::write_csv(df, 'aligned_player_velocities')
