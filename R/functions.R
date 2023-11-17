# 1. Get Data from File -------
get_data <- function(file) {
  # Reads data from the specified file and automatically determines column types.
  read_csv(file, col_types = cols())
}

# 2. Format Search Terms -------
get_formatted_search_term <- function(search_terms){
  # Formats search terms by combining year and terms with logical operators for query generation.
  data.frame(
    final =  paste0(search_terms$year, ' AND ',
                    paste0('(',
                           search_terms$term,
                           ')'
                    )
    )
  )
}

# 3. Create Search Queries -------
create_search_queries <- function(search_term_df) {
  # Generates search queries by combining formatted search terms with various state names.
  expand.grid(
    "query" = search_term_df$final,
    "states" = states <-
      c("Blank", "United States", datasets::state.name)
  ) %>%
    dplyr::mutate(
      final = ifelse(
        states == "Blank",
        paste0(query),
        paste0(query, ' AND ', states)
      ))
}

# 4. Retrieve Article IDs -------
get_article_id <- function(search_query) {
  # Retrieves PubMed article IDs for each search query using the easyPubMed package.
  lapply(search_query$final,
         easyPubMed::get_pubmed_ids,
         api_key = api_key)
}

# 5. Fetch XML Data for Articles -------
get_xml_articles <- function(article_id) {
  # Fetches detailed article data in XML format for each article ID, ensuring API limits are respected.
  ## Use lapply to not get banned from the API ----
  lapply(
    article_id,
    easyPubMed::fetch_pubmed_data,
    retmax = 5000
  )
}
 
# 6. Extract Authors from XML Data -------
get_authors <- function(xml) {
  # Extracts author information from XML data, focusing on the first author and keyword extraction.
  ## Use lapply to not get banned from the API ----
  lapply(
    xml,
    easyPubMed::table_articles_byAuth,
    included_authors = "first",
    getKeywords = TRUE,
    max_chars = 10000
  )
}

# 7. Combine Article and Author Data -------
get_combined_article_author <- function(pubmed_list) {
  # Combines article and author data, including the original query strings that produced the results.
  # Add the query strings that produced the results
  do.call(rbind, Map(cbind, pubmed_list, "query" = final, "terms" = terms))
}

# 8. Remove Duplicate Articles -------
remove_duplicate_articles <- function(pm_df) {
  # Removes duplicate articles from the data frame to ensure uniqueness in the dataset.
  pm_df[!duplicated(pm_df),] # Exclude duplicates
}
