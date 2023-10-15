library(dplyr)
library(reticulate)
library(here)
library(tuber)
library(purrr)
library(tidytext)
library(topicmodels)
library(ggplot2)
library(tidyr)
library(openai)
library(stringr)

source(here("R scripts", "adhoc_youtube_functions.R"))
# Use environment variables
yt_oauth(app_id = Sys.getenv("YT_APP_ID"),
         app_secret = Sys.getenv("YT_APP_SECRET"))
# TidyX -------------------------------------------------------------------

# Call the recursive function to fetch all channel videos
channel_id <- "UCP8l94xtoemCH_GxByvTuFQ"
tidy_x_videos_list <- fetch_all_channel_videos(channel_id)
# test_df <- fetch_channel_videos_page(channel_id, page_token = NULL)
# test2_df <- fetch_channel_videos_page(channel_id, page_token = test_df[["nextPageToken"]])

# Convert the result to a data frame
# List all tidyX videos
tidy_x_videos_df <- tidy_x_videos_list |> 
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
      "https://yt3.googleusercontent.com/ytc/APkrFKadUXFAW9OBku2xSEtxGPQugWZyc0jxVIaT4bYu=s176-c-k-c0x00ffffff-no-rj", # LOGO OF TIDY
      "' alt='Logo for TidyX' width='40'></img>",
      "<a href='https://www.youtube.com/channel/",
      snippet.channelId,
      "' target='_blank'>",
      "TidyX",
      "</a>"
    ),
    date = as.Date(str_sub(snippet.publishedAt, 1, 10))
  ) |> 
  dplyr::arrange(desc(snippet.publishedAt))

# Generic Stop Words
data(stop_words)
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

episode_titles <- word_counts |> 
  distinct(document) |> 
  pull()

per_episode_topics <- episode_titles |> 
  map(
    \(episode_title)
    obtain_topics_per_tidy_x_episode(word_counts, episode_title)
    ) |> 
  list_rbind()

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

create_gpt_descriptions <- function(descriptions) {
  results <- vector("character", length(descriptions))
  
  for (i in seq_along(descriptions)) {
    prompt <- glue::glue("Summarize this description to 2 or 3 small sentences: {descriptions[i]}")
    completion <- create_chat_completion(
      model = "gpt-3.5-turbo",
      messages = list(
        list(
          "role" = "system",
          "content" = "You are a helpful assistant who generates 2 sentence summaries from text given by the user, in your summaries you will not write to follow anyones social media or supporting their Patreon nor patron."
        ),
        list(
          "role" = "user",
          "content" = prompt
        )
      )
    )
    
    results[i] <- completion$choices$message.content
  }
  
  return(results)
}

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
  mutate(
    episode_topics = format_to_html_list(episode_topics),
    gpt_descriptions = create_gpt_descriptions(snippet.description)
  ) 


full_tidy_x_per_video_tags |> 
  ungroup() |> 
  select(
    date, channel_url, video_url,
    episode_topics,
    gpt_descriptions
  ) |> 
DT::datatable(
  colnames = c('Date', 'Channel', 'Video', 'Episode Topics',
               'Description'),
  filter = 'top',
  escape = FALSE,
  height = '1000',
  elementId = 'dashboard',
  options = list(columnDefs = list(
    list(className = 'dt-middle', targets = "_all")
  ))
)

# Julia Silge -------------------------------------------------------------




# David Robinson ----------------------------------------------------------




# Dude creator de shiny ---------------------------------------------------


