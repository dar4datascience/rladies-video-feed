# Function to fetch channel videos for a given page token
fetch_channel_videos_page <- function(channel_id, page_token = NULL) {
  list_channel_videos(
    channel_id,
    part = "snippet",
    max_results = 50,
    page_token = page_token,
    auth = "key",
    simplify = FALSE
  )
}

# Recursive function to fetch all channel videos
fetch_all_channel_videos <- function(channel_id, page_token = NULL, result_list = list()) {
  # Fetch videos for the current page
  current_page <- fetch_channel_videos_page(channel_id, page_token)
  
  # Append the current page's items to the result list
  result_list <- c(result_list, current_page[["items"]])
  
  # Check if there's a nextPageToken
  next_token <- current_page[["nextPageToken"]]
  message(
    "Checkin next page token: ", next_token
    )
  # If there's a nextPageToken, recursively fetch the next page
  if (!is.null(next_token)) {
    next_page <- fetch_all_channel_videos(channel_id, next_token, result_list)
    return(next_page)
  } else {
    return(result_list)
  }
}
