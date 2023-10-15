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

load_tidy_x_stop_words <- function(){
  
  # Relevant Stop Words
  tidy_x_stop_words <- tibble(
    word = c(
      "tidyx",
      "https",
      "github.com",
      "tidy_explained",
      "thebioengineer",
      "episode",
      "code",
      "comments",
      "data",
      "master",
      "twitter",
      "questions",
      "patreon",
      "links",
      "subscribe",
      "www.patreon.com",
      "suggestions",
      "email",
      "ellis_hughes",
      "gmail.com",
      "osppatrick",
      "tidy.explained",
      "tree",
      "object",
      "tidytuesday_explained",
      "github",
      "issue",
      "page",
      "issues",
      "patron",
      "sign",
      # "package",
      # "shiny",
      "week",
      "viewers",
      "ellis",
      "patrick",
      "leave",
      "hear",
      "love",
      "tidytuesday",
      "bit.ly",
      # "series",
      # "rmarkdown",
      # "model",
      "talk",
      #"post",
      # "set",
      # "create",
      # "discuss",
      # "status",
      "twitter.com",
      "functions",
      "time",
      # "plots",
      "weeks",
      "explain",
      # "source",
      # "explore",
      # "plotly",
      # "app",
      # "function",
      # "generate",
      # "tidymodels",
      # "apply",
      # "classification",
      # "objects",
      # "bayes",
      # "blob",
      # "pitch",
      # "plot",
      # "based",
      # "creating",
      # "dataset",
      # "object",
      # "player",
      # "cleaning",
      # "database",
      # "models",
      # "start",
      # "users",
      # "interactive",
      # "mlb",
      # "results",
      # "techniques",
      # "excel",
      "media",
      "social",
      "submission",
      as.character(seq(1, 200)) # remove numeric values 
      # "tables",
      # "visualization",
      # "base",
      # "finally",
      # "formatting",
      # "multiple",
      # "reports",
      # "statistics",
      # "visualize",
      # "analysis",
      # "styling",
      # "performance",
      # "user"
    )
    
  )
}

process_youtube_video_list <- function(youtube_videos_list, 
                                      channel_name,
                                      logo_of_channel){
  youtube_videos_list |> 
    map(unlist) |>
    map(~as.data.frame(t(.x), stringsAsFactors = FALSE)) |>
    list_rbind() |> 
    dplyr::mutate(
      video_url = paste0(
        "<a href='https://www.youtube.com/watch?v=",
        snippet.resourceId.videoId,
        "' target='_blank'>",
        snippet.title,
        "</a>"
      ),
      channel_url = paste0(
        "<img src='",
        logo_of_channel, 
        glue::glue("' alt='Logo for {channel_name}' width='40'></img>"),
        "<a href='https://www.youtube.com/channel/",
        snippet.channelId,
        "' target='_blank'>",
        channel_name,
        "</a>"
      ),
      date = as.Date(str_sub(snippet.publishedAt, 1, 10))
    ) |> 
    dplyr::arrange(desc(snippet.publishedAt))
  
}

obtain_topics_per_tidy_x_episode <- function(word_counts,
                                             episode_title) {
  filtered_word_counts <- word_counts |>
    filter(document == episode_title)
  
  chapters_dtm <- filtered_word_counts |>
    cast_dtm(document, word, n)
  
  # get 4 topics per video
  chapters_lda <-
    LDA(chapters_dtm, k = 2, control = list(seed = 1234))
  
  
  chapter_topics <- tidy(chapters_lda, matrix = "beta")
  
  
  top_terms <- chapter_topics |>
    group_by(topic) |>
    slice_max(beta, n = 5) |>
    ungroup() |>
    arrange(topic, -beta)
  #
  # top_terms |>
  #   mutate(term = reorder_within(term, beta, topic)) |>
  #   ggplot(aes(beta, term, fill = factor(topic))) +
  #   geom_col(show.legend = FALSE) +
  #   facet_wrap(~ topic, scales = "free") +
  #   scale_y_reordered()
  
  episode_topics <- top_terms |>
    filter(beta > 0.0500) |>
    slice_max(beta, n = 6) |>
    distinct(term)
  
  episode_topics_df <- tibble(episode_title = episode_title,
                              episode_topics = episode_topics)
  
  return(episode_topics_df)
}

format_to_html_list <- function(input_vector) {
  html_lists <- vector("list", length(input_vector))
  
  for (i in seq_along(input_vector)) {
    elements <- strsplit(input_vector[i], "\\|")[[1]]
    html_list <- "<ul>\n"
    
    for (element in elements) {
      html_list <- paste0(html_list, "    <li>", element, "</li>\n")
    }
    
    html_list <- paste0(html_list, "</ul>")
    html_lists[[i]] <- html_list
  }
  
  return(html_lists)
}

topic_model_tidy_x_videos <- function(tidy_x_videos_df){
  # Generic Stop Words
  data(stop_words)
  #load tidy_x_stop_words
  tidy_x_stop_words <- load_tidy_x_stop_words()
  
  
  tidy_x_descriptions <- tidy_x_videos_df |> 
    select(snippet.title,
           snippet.description) |> 
    unnest_tokens(word, snippet.description) |> 
    anti_join(stop_words) |> 
    anti_join(tidy_x_stop_words)
  
  
  word_counts <- tidy_x_descriptions |> 
    group_by(snippet.title) |> 
    count(word, sort = TRUE) |> 
    rename(
      "document" = snippet.title
    ) |> 
    ungroup()
  
  
  episode_titles <- word_counts |> 
    distinct(document) |> 
    pull()
  
  per_episode_topics <- episode_titles |> 
    map(
      \(episode_title)
      obtain_topics_per_tidy_x_episode(word_counts, episode_title)
    ) |> 
    list_rbind()
  
  
  full_tidy_x_per_video_tags <- tidy_x_videos_df |> 
    select(snippet.title,
           snippet.description,
           date,
           video_url,
           channel_url,
           snippet.thumbnails.maxres.url) |> 
    full_join(per_episode_topics,
              join_by(snippet.title == episode_title)) |>
    group_by(snippet.title) |> 
    mutate(
      episode_topics = episode_topics |> 
        map_chr(
          \(tibble_of_topics)
          glue::glue_collapse(tibble_of_topics, 
                              sep = '|')
        )
    ) |> 
    distinct() |>  
    ungroup() |> 
    mutate(
      episode_topics = format_to_html_list(episode_topics)
    ) 
  
  return(full_tidy_x_per_video_tags)
}