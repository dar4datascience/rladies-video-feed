# Install pacman if you haven't already
# install.packages("pacman")

# Load packages using pacman::p_load
pacman::p_load(
  dplyr,
  reticulate,
  here,
  tuber,
  purrr,
  tidytext,
  topicmodels,
  ggplot2,
  tidyr,
  openai,
  stringr,
  progressr
)


source(here("R scripts", "adhoc_youtube_functions.R"))
# Use environment variables
yt_oauth(app_id = Sys.getenv("YT_APP_ID"),
         app_secret = Sys.getenv("YT_APP_SECRET"))

# How to find channel id at: https://www.youtube.com/watch?v=0oDy2sWPF38

# TidyX -------------------------------------------------------------------

# Call the recursive function to fetch all channel videos
channel_id <- "UCP8l94xtoemCH_GxByvTuFQ"
tidy_x_videos_list <- fetch_all_channel_videos(channel_id)


# Convert the result to a data frame
tidy_x_videos_df <- process_youtube_video_list(tidy_x_videos_list,
                    channel_name = "TidyX",                          logo_of_channel = "https://yt3.googleusercontent.com/ytc/APkrFKadUXFAW9OBku2xSEtxGPQugWZyc0jxVIaT4bYu=s176-c-k-c0x00ffffff-no-rj")

# Topic Modelling
full_tidy_x_per_video_tags <- topic_model_tidy_x_videos(tidy_x_videos_df)


tbl_tidy_x_videos_processed <- generate_chatgpt_descriptions_4_tidy_x(full_tidy_x_per_video_tags)


# save to google sheets for practicallity and publicity
library(googlesheets4)
gs4_auth(email = "danielamieva@dar4datascience.com")
# make public for others to see
# Create once
# gs4_create("shiny-youtube-adhoc-search", 
#            sheets = c("TidyX Videos"))
# can leave title for reading purposes
# tbl_tidy_x_videos_processed |> 
#   write_sheet(ss = gs4_find("shiny-youtube-adhoc-search"),
#               sheet = "TidyX Videos")

# Julia Silge -------------------------------------------------------------
julia_silge_channel_id <- "UCTTBgWyJl2HrrhQOOc710kA"
julia_silge_channel_image <- "https://yt3.googleusercontent.com/ytc/APkrFKa98GyCrxTk9lHWRV-hBAyaUVGjRTbyfSs8jKsLR4I=s900-c-k-c0x00ffffff-no-rj"

julia_silge_video_list <- fetch_all_channel_videos(julia_silge_channel_id)
# convert result to df
julia_silge_video_df <- process_youtube_video_list(julia_silge_video_list,
                                               channel_name = "Julia Silge",                          logo_of_channel = julia_silge_channel_image)
#her descriptions are great no need for gpt





# David Robinson ----------------------------------------------------------
david_robinson_channel_id <- "UCeiiqmVK07qhY-wvg3IZiZQ"
david_robinson_channel_image <- "https://yt3.googleusercontent.com/ytc/APkrFKZgKECiNJ3snfsqQ0MtErNKS3rs9APRHmz9Hwj1=s900-c-k-c0x00ffffff-no-rj
"

david_robinson_video_list <- fetch_all_channel_videos(david_robinson_channel_id)

# convert result to df
david_robinson_video_df <- process_youtube_video_list(david_robinson_video_list,
                                               channel_name = "David Robinson",                          logo_of_channel = david_robinson_channel_image)
#also descriptions are great no need for gpt

# Posit Videos ------------------------------------------------------------
posit_channel_id <- "UC3xfbCMLCw1Hh4dWop3XtHg"
posit_channel_image <- "https://yt3.googleusercontent.com/tdMVAbii6ge_T_QDGQ5uZfm9cHPWo89-vUzMoO-5_NizdY07Zv0K47JyH-CXNJLW7IwMf3iELQ=s900-c-k-c0x00ffffff-no-rj"




