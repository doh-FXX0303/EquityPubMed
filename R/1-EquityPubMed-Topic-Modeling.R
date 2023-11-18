# Load necessary libraries
library(tidytext)       # For text processing
library(tidymodels)     # For modeling and statistical analysis
library(tidyr)          # For data tidying
library(tidyverse)      # For data manipulation and visualization
library(stopwords)      # For accessing stop words
library(easyPubMed)     # For interacting with PubMed data
library(visNetwork)     # For network visualization
library(doParallel)     # For parallel computing
library(pubmedR)        # For accessing PubMed data

# Set the API key for PubMed access
api_key <- ""

# Define a range of years and a search term
year <- 1944:2023   # Define the year range
term <- "Asian"     # Define the search term

# Create directories for storing search results
lapply(paste0("data/Search-", term), dir.create)           # Create main directory for each search term
lapply(paste0("data/Search-", term, "/", year), dir.create) # Create subdirectories for each year

# Generate combinations of years and the search term formatted for PubMed query syntax
term_grid <-
  expand.grid(
    "year" =  sprintf(
      '(("%d/01/01"[Date - Publication] : "%d/12/31"[Date - Publication]))', year, year
    ),
    "term" = term |> paste0('[Title])')
  ) %>%
  dplyr::bind_cols(data.frame(year_search = year)) %>%
  dplyr::bind_cols(data.frame(term_search = term))

# Write the query combinations to CSV files
term_grid %>%
  dplyr::group_by(term_search, year_search) %>%
  dplyr::group_walk( ~ readr::write_csv(
    .x,
    path = paste0("data/Search-", term, "/", .y$year_search, "/search_", .y$term_search, '.csv'),
    num_threads = parallel::detectCores()
  ))

# List the files containing search queries
search_files <-
  list.files(
    paste0("data/Search-", term),
    full.names = TRUE,
    recursive = TRUE,
    pattern = "search_"
  )

# Create directories for batch and article data
lapply(paste0("data/Batch-", term), dir.create)
lapply(paste0("data/Batch-", term, "/", year), dir.create)
lapply(paste0("data/Article-", term), dir.create)
lapply(paste0("data/Article-", term, "/", year), dir.create)

# Download and process PubMed data
foreach::foreach(
  i = 1:length(search_files),
  .combine = "rbind",
  .errorhandling = "pass"
) %do% {
  # Read the search term data frame
  search_term_df <- readr::read_csv(search_files[i])
  
  # Construct the data query
  data_query <-
    data.frame(final =  paste0(
      search_term_df$year,
      ' AND ',
      paste0('(', search_term_df$term, ')')
    ))
  
  # Download articles from PubMed
  out <-
    easyPubMed::batch_pubmed_download(
      data_query$final,
      dest_dir =  paste0("data/Batch-", term, "/", year[i]),
      dest_file_prefix = "articles_",
      format = "xml",
      api_key = api_key,
      batch_size = 5000
    )
  
  # Process each downloaded batch
  out2 <- foreach::foreach(j = 1:length(out)) %do% {
    # Extract and format article data
    out2 <- easyPubMed::table_articles_byAuth(
      paste0("data/Batch-", term, "/", year[i], "/", out[j]),
      included_authors = "first",
      max_chars = 10000,
      encoding = "ASCII"
    ) %>%
      dplyr::mutate(across(c("year", "month", "day"), as.integer)) %>%
      dplyr::mutate(date = lubridate::make_date(year = year, month = month, day = day)) %>%
      dplyr::mutate(query = data_query$final)
    
    # Write the processed data to CSV files
    readr::write_csv(out2, file = paste0("data/Article-", term, "/", year[i], "/pubmed_", j, ".csv"), num_threads = 4)
  }
  
  # Clean up memory by removing temporary variables
  rm(pubmed_df, out, out2, data_query, data_searchterms, search_term_df)
  gc() # Call garbage collector to free up memory
}
