# we can make this better by launching multiple workers
# crew controller
library(furrr)
# Set a "plan" for how the code should run.
plan(multisession,
     workers = 6) 
create_gpt_descriptions <- function(descriptions) {
  # set progress bar
  p <- progressr::progressor(steps = length(descriptions))
  
  # Wrap the loop with with_progress to display the progress bar
  # run in parallel
  future_results <- future_map(1:length(descriptions), ~{
    max_retries <- 3  # specify the maximum number of retry attempts
    retry_count <- 0  # initialize a counter for retry attempts
    
    while (retry_count < max_retries) {
      tryCatch(
        {
          p()
          prompt <- glue::glue("Summarize this description to 2 or 3 small sentences: '{descriptions[.x]}' ")
          completion <- create_chat_completion(
            model = "gpt-3.5-turbo",
            messages = list(
              list(
                "role" = "system",
                "content" = "You are a helpful assistant who generates 2 sentence summaries from text given by the user, in your summaries you will not write to follow anyone's social media or supporting their Patreon nor patron."
              ),
              list(
                "role" = "user",
                "content" = prompt
              )
            )
          )
          
          chat_message <- completion$choices$message.content
          
          return(chat_message)
        },
        error = function(e) {
          # Handle error: print message and increment retry counter
          print(paste("Error:", e$message, "Attempt:", retry_count + 1))
          retry_count <- retry_count + 1
          
          # If max retries reached, return NA or a message
          if (retry_count == max_retries) {
            return(NA_character_)
          }
          
          # Wait for 1 minute before retrying
          Sys.sleep(60)
        }
      )
      
      # If the tryCatch block was successful, break out of the while loop
      if (!is.na(chat_message)) {
        break
      }
    }
  })
  
  
  return(future_results)
}

handlers(handler_txtprogressbar(char = cli::col_red(cli::symbol$heart)))
handlers(global = TRUE)

generate_chatgpt_descriptions_4_tidy_x <- function(full_tidy_x_per_video_tags){
  # chatgpt descriptions
  source(here("R scripts", "chatgpt_functions.R"))
  
  
  # THIS MIGHT CRASH ALOT so its better to safely try
  # get results save. and try later for rest
  chatgpt_descriptions <- full_tidy_x_per_video_tags |>
    pull(snippet.description) |>
    create_gpt_descriptions()
  
  tbl_tidy_x_videos_processed <- full_tidy_x_per_video_tags |> 
    mutate(
      gpt_descriptions = unlist(chatgpt_descriptions),
      episode_topics = unlist(episode_topics)
    ) |>
    ungroup() |> 
    select(
      date, channel_url, video_url,
      episode_topics,
      gpt_descriptions
    ) 
  
  return(tbl_tidy_x_videos_processed)
}