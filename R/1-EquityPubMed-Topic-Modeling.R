# 1. Load necessary libraries: targets for workflow management, and visNetwork for visualization -------
library(targets)
library(visNetwork)


# 2. Define a range of years and a search term -------
year <- 2000:2000   # Year range from YYYY to YYYY
term <- "Asian"     # Search term

# 3. Generate all combinations of years and the search term, formatted for a specific query syntax -------
expand.grid("year" =  sprintf('(("%d/01/01"[Date - Publication] : "%d/12/31"[Date - Publication]))',
                              year,
                              year), 
            "term" = term |> paste0('[Title])')) %>% 
  readr::write_csv("data/search_terms.csv")  # Write the generated combinations to a CSV file

# 4. Initialize and visualize the targets workflow  -------
targets::tar_manifest(fields = all_of("command"))  # Create a manifest of workflow steps
targets::tar_visnetwork()                          # Visualize the workflow as a network

# 5. Execute the workflow  -------
targets::tar_make()                                # Run the workflow

# 6. Visualize the workflow again (optional, can be repeated to see progress or changes)
targets::tar_visnetwork()                          # Visualize the workflow after execution
targets::tar_visnetwork()                          # Additional visualization (optional)

# 7. Check which parts of the workflow are outdated  -------
targets::tar_outdated()                            # List targets that need to be rerun

# 8. Read the final processed data set from the workflow  -------
pubmed_df_final <- targets::tar_read(pubmed_df_final) # Read the final data product

# 9. Save the current R session state  -------
save.image(file = paste0("snapshot",Sys.Date(),".RData")) # Save the current workspace

