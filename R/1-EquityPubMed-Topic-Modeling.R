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
  # You may not need one but it could be slower.
api_key <- "a5258909814eb462f42a649f78c5fbfaf208"

# Define a range of pub_years and a search term
pub_year <- 1944:2023   # Define the pub_year range
term <- "Asian"     # Define the search term

# Generate combinations of pub_years and the search term formatted for PubMed query syntax
term_grid <-
  expand.grid(
    "pub_year" =  sprintf(
      '(("%d/01/01"[Date - Publication] : "%d/12/31"[Date - Publication]))', pub_year, pub_year
    ),
    "term" = term |> paste0('[All])')
  ) %>%
  dplyr::bind_cols(data.frame(pub_year_search = pub_year)) %>%
  dplyr::bind_cols(data.frame(term_search = term)) %>%
  dplyr::mutate(query =  paste0(
    pub_year,
    ' AND ',
    paste0('(', term, ')')
  )
  )

# Create directories for batch and article data
lapply(paste0("data/Batch-", term), dir.create)
lapply(paste0("data/Batch-", term, "/", pub_year), dir.create)
lapply(paste0("data/Article-", term), dir.create)
lapply(paste0("data/Article-", term, "/", pub_year), dir.create)

# Download and process PubMed data
foreach::foreach(
  i = 1:length(pub_year),
  .combine = "rbind",
  .errorhandling = "pass"
) %do% {

  # Download articles from PubMed
  out <-
    easyPubMed::batch_pubmed_download(
      term_grid$query[i],
      dest_dir =  paste0("data/Batch-", term, "/", pub_year[i]),
      dest_file_prefix = "articles_",
      format = "xml",
      api_key = api_key,
      batch_size = 5000
    )
  
  # Process each downloaded batch
  out2 <- foreach::foreach(j = 1:length(out)) %do% {
    # Extract and format article data
    out2 <- easyPubMed::table_articles_byAuth(
      paste0("data/Batch-", term, "/", pub_year[i], "/", out[j]),
      included_authors = "first",
      max_chars = 10000,
      encoding = "ASCII"
    ) %>%
      dplyr::mutate(across(c("year", "month", "day"), as.integer)) %>%
      dplyr::mutate(query = term_grid$query[i]) %>%
      dplyr::mutate(pub_year = pub_year[i])
    
    
    # Write the processed data to CSV files
    readr::write_csv(out2, file = paste0("data/Article-", term, "/", pub_year[i], "/pubmed_", j, ".csv"), num_threads = 4)
  }
  
  # Clean up memory by removing temporary variables
  rm(pubmed_df, out, out2, data_query, data_searchterms, search_term_df)
  gc() # Call garbage collector to free up memory
}
