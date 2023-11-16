# 1. Load necessary libraries -------
library(targets)
library(visNetwork)
library(tidytext)
library(tidymodels)
library(translations)

## Purpose: Identify articles with specific keywords in their titles 
## Keywords: "Asian", "Asia", or "Asian American"

# 2. Process and filter the dataset -------
pm_df_tidy <- 
  pm_df  %>%
  # Convert title, abstract, and keywords to uppercase for consistent matching
  dplyr::mutate(across(c("title","abstract","keywords"), stringr::str_to_upper)) %>%
  # Group data by PubMed ID (pmid)
  group_by(pmid) %>%
  # Create new columns to count occurrences of specific keywords in the title
  mutate(line = row_number(),
         asian1 = cumsum(str_detect(title, regex("^ASIAN", ignore_case = TRUE))),
         asian2 = cumsum(str_detect(title, regex("^ASIAN-AMERICAN", ignore_case = TRUE))),
         asian3 = cumsum(str_detect(title, regex("^ASIAN-AMERICANS", ignore_case = TRUE))),
         asian4 = cumsum(str_detect(title, regex("^ASIANS", ignore_case = TRUE)))) %>%
  # Ungroup the data frame after transformations
  ungroup() %>%
  # Select relevant columns for analysis
  dplyr::select(all_of(c("pmid","title","line","asian1","asian2","year","month","day"))) %>%
  # Filter articles where the keywords appear more than once
  dplyr::filter(asian1 > 1 | asian2 > 1)

# 3. Create a table to summarize the occurrences of the keywords -------
table(pm_df_tidy$asian1, pm_df_tidy$asian2)

# 4. Aggregate and summarize articles by year -------
asian_articles <- 
  pm_df_tidy %>%
  # Group by year
  dplyr::group_by(year) %>%
  # Summarise the number of distinct PMIDs per year
  dplyr::summarise(
    pmid_count = n_distinct(pmid, na.rm = T)
  ) %>%
  # Ungroup the data frame
  dplyr::ungroup()

# 5. Calculate the total number of articles with the specified keywords -------
sum(asian_articles$pmid_count)
