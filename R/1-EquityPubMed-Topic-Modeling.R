library(tidytext)
library(tidymodels)
library(tidyr)
library(tidyverse)
library(stopwords)
library(easyPubMed)
library(visNetwork)
library(doParallel)
library(pubmedR)

api_key <- ""

# 1.1 Define a range of years and a search term -------
year <- 1944:2023   # Year range from YYYY to YYYY
term <- "Asian"     # Search term

lapply(paste0("data/Search-", term), dir.create)
lapply(paste0("data/Search-", term, "/", year), dir.create)

# 1.2 Generate all combinations of years and the search term, formatted for a specific query syntax -------
term_grid <-
  expand.grid(
    "year" =  sprintf(
      '(("%d/01/01"[Date - Publication] : "%d/12/31"[Date - Publication]))',
      year,
      year
    ),
    "term" = term |> paste0('[Title])')
  ) %>%
  dplyr::bind_cols(data.frame(year_search = year)) %>%
  dplyr::bind_cols(data.frame(term_search = term))

# 1.2 Generate all combinations of years and the search term, formatted for a specific query syntax -------
term_grid %>%
  dplyr::group_by(term_search, year_search) %>%
  ##use group_walk to apply function to a group
  dplyr::group_walk( ~ readr::write_csv(
    .x,
    path = paste0(
      "data/Search-",
      term,
      "/",
      .y$year_search,
      "/search_",
      .y$term_search,
      '.csv'
    ),
    num_threads = parallel::detectCores()
  ))

search_files <-
  list.files(
    paste0("data/Search-",term),
    full.names = T,
    recursive = T,
    pattern = "search_"
  )

lapply(paste0("data/Batch-", term), dir.create)
lapply(paste0("data/Batch-", term, "/", year), dir.create)

lapply(paste0("data/Article-", term), dir.create)
lapply(paste0("data/Article-", term, "/", year), dir.create)

foreach::foreach(
  i = 1:length(search_files),
  .combine = "rbind",
  .errorhandling = "pass"
) %do% {
  
  search_term_df <- readr::read_csv(search_files[i])
  
  data_query <-
    data.frame(final =  paste0(
      search_term_df$year,
      ' AND ',
      paste0('(', search_term_df$term, ')')
    ))
  
  out <-
    easyPubMed::batch_pubmed_download(
      data_query$final,
      dest_dir =  paste0("data/Batch-", term, "/", year[i]),
      dest_file_prefix = "articles_",
      format = "xml",
      api_key = api_key,
      batch_size = 5000
    )
  
  out2 <- foreach::foreach(j = 1:length(out)) %do% {
    out2 <- easyPubMed::table_articles_byAuth(
      paste0("data/Batch-", term, "/", year[i], "/", out[j]),
      included_authors = "first",
      max_chars = 10000,
      encoding = "ASCII"
    ) %>%
      dplyr::mutate(
        across(c("year","month","day"),as.integer)
      )  %>%
      dplyr::mutate(
        date = lubridate::make_date(year = year, month = month, day = day)
      )%>%
      dplyr::mutate(
        query = data_query$final
      )
    readr::write_csv(out2,file = paste0("data/Article-", term, "/", year[i], "/pubmed_",j, ".csv"),num_threads = 4)
  }
  
  rm(pubmed_df,out,out2,data_query,data_searchterms,search_term_df)
  gc()
}
