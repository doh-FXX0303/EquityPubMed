# 1. Set Up Environment  -------

## 1.1 Load the targets library  -------
library(targets)

## 1.2 Source external R script containing custom functions  -------
source("R/functions.R")

## 1.3 Set Target Options  -------
targets::tar_option_set(packages = 
                          c("tidytext", "tidyverse", "easyPubMed",
                            "stopwords","tidymodels","visNetwork"))
## 1.4 Set API key variable  -------
api_key <- ""

# 2. Define Targets  -------
list(
  ## Target 2.1: Define a file target for 'search_terms.csv'  -------
  tar_target(file, "data/search_terms.csv", format = "file"),
  
  ## Target 2.2: Process the 'search_terms.csv' file to obtain search terms  -------
  tar_target(search_terms, get_data(file)),
  
  ## Target 2.3: Format the search terms for querying  -------
  targets::tar_target(search_term_df, get_formatted_search_term(search_terms)),
  
  ## Target 2.4: Create search queries from the formatted search terms  -------
  targets::tar_target(search_query, create_search_queries(search_term_df)),
  
  ## Target 2.5: Retrieve article IDs using the generated search queries  -------
  targets::tar_target(article_id, get_article_id(search_query)),
  
  ## Target 2.6: Fetch XML data for the articles using their IDs  -------
  targets::tar_target(xml_articles, get_xml_articles(article_id)),
  
  ## Target 2.7: Extract author information from the fetched XML articles  -------
  targets::tar_target(pubmed_list, get_authors(xml_articles)),
  
  ## Target 2.8: Combine article data with author information  -------
  tar_target(pubmed_df, get_combined_article_author(pubmed_list)),
  
  ## Target 2.9: Remove duplicate articles from the combined data frame  -------
  tar_target(pubmed_df_final, remove_duplicate_articles(pubmed_df))
)
