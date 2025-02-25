#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#################  FUNCTION TO DETERMINE POPULATION AND DISTRIBUTION STATISTICS FOR TABLE 1  ##################
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# Purpose: This function determines the population statistics for age, sex, race, and mortality status along  
#          with the distribution statistics for each physiological indicators 
#          
# Inputs: dataset_merged - dataframe containing the demographics, physiological indicators, mortality info for 
#                          each participant 
#         dataset_stats - dataframe containing the statistics and include criteria for each physiological 
#                         indicator
#         dataset_body_systems - dataframe containing the name and body system of the physiological indicator
#
# Outputs: none - population statistics are printed to the console 
#                 distribution statistics for the physiological indicators are viewed in another window

determine_statistics_for_table_1 <- function(dataset_merged
                                             , dataset_stats
                                             , dataset_body_systems)
{
  # Define a column for age and time_to_death for legibility 
  dataset_merged <- dataset_merged %>%
    mutate(age = RIDAGEYR
           , time_to_death = PERMTH_INT)
  
  # Define a vector of codenames for pertinent variables
  other_variables <- c("SEQN"
                       , "PERMTH_INT"
                       , "MORTSTAT"
                       , "SDMVPSU"
                       , "SDMVSTRA"
                       , "WTINT2YR"
                       , "RIAGENDR"
                       , "RIDAGEYR"
                       , "RIDRETH1")
  
  # Determine the number of participant with no follow-up data
  num_with_no_follow_up <- dataset_merged %>%
    filter(PERMTH_INT == 0) %>%
    nrow(.)
  
  # View(dataset_merged %>%
  #        filter(PERMTH_INT == 0) %>%
  #        select(MORTSTAT, ELIGSTAT, RIDAGEYR, RIAGENDR, RIDRETH1))
  print("Number of participants with no follow-up data")
  print(num_with_no_follow_up)
  
  # Determine the number of participants with no mortality data
  num_with_no_mortality_data <- dataset_merged %>%
    filter(is.na(PERMTH_INT) == TRUE) %>%
    nrow(.)
  
  print("Number of participants with no mortality data")
  print(num_with_no_mortality_data)
  
  # Determine a dataset containing only participants with data available for the pertinent variables
  dataset_complete <- dataset_merged %>%
    # Select only the pertinent variables 
    dplyr::select(other_variables) %>%
    na.omit(.) %>% 
    # Exclude participants with no follow-up data
    filter(PERMTH_INT > 0) %>% 
    # Exclude participants with missing data
    na.omit(.) 
  
  # Determine the SEQN for participants who do not have mortality data
  seqn_missing <- outersect(dataset_merged$SEQN, dataset_complete$SEQN)
  
  # Determine a subset with participants who do not have mortality data
  dataset_missing <- dataset_merged %>%
    filter(SEQN %in% seqn_missing)
  
  # Determine the number of participants by eligibility status
  df_stats_missing <- dataset_missing %>%
    group_by(ELIGSTAT) %>%
    summarise(num_participants = n())
  print(df_stats_missing)
  
  # View(dataset_missing %>%
  #        select(all_of(other_variables), ELIGSTAT))
  
  # Determine the number of participants with complete data for all pertinent variables
  num_with_covariates <- dim(dataset_complete)[1]
  print("Number of participants with complete data for mortality, gender, race, and age")
  print(num_with_covariates)
  
  # Determine the number of participants with complete data for all pertinent variables
  num_with_covariates_missing <- dim(dataset_missing)[1]
  print("Number of participants with missing data for mortality")
  print(num_with_covariates_missing)

  # Determine for each variable, the number of participants for each category
  list_pop_stats <- sapply(dataset_complete, summary.factor)
  
  # Determine for each variable, the number of participants for each category
  list_pop_stats_missing <- sapply(dataset_missing, summary.factor)

  # Determine the number and percentages of alive or deceased participants
  print("Number of participants by mortality status")
  print(list_pop_stats$MORTSTAT)
  print(round(list_pop_stats$MORTSTAT/num_with_covariates*100
              , digits = 1))

  # Determine the number and percentages of participants by gender
  print("NHANES complete - Number of participants by gender")
  print(list_pop_stats$RIAGENDR)
  print(round(list_pop_stats$RIAGENDR/num_with_covariates*100
              , digits = 1))
  
  # Determine the number and percentages of participants by gender for NHANES missing
  print("NHANES excluded - number of participants by gender ")
  print(list_pop_stats_missing$RIAGENDR)
  print(round(list_pop_stats_missing$RIAGENDR/num_with_covariates_missing*100
              , digits = 1))

  # Determine the number and percentages of participants by race
  print("NHANES complete - Number of participants by race")
  print(list_pop_stats$RIDRETH1)
  print(round(list_pop_stats$RIDRETH1/num_with_covariates*100
              , digits = 1))
  
  # Determine the number and percentages of participants by race
  print("NHANES excluded - Number of participants by race")
  print(list_pop_stats_missing$RIDRETH1)
  print(round(list_pop_stats_missing$RIDRETH1/num_with_covariates_missing*100
              , digits = 1))
  
  # Determine the distribution of age for the excluded NHANES subpopulation
  print("NHANES excluded - Age distribution")
  age_distribution_excluded <- dataset_missing %>%
    summarise(min = min(RIDAGEYR)
              , perc_01 = quantile(RIDAGEYR, probs = 0.01)
              , perc_05 = quantile(RIDAGEYR, probs = 0.05)
              , perc_10 = quantile(RIDAGEYR, probs = 0.10)
              , median = quantile(RIDAGEYR, probs = 0.5)
              , interquartile_range = quantile(RIDAGEYR, probs = 0.75) - quantile(RIDAGEYR, probs = 0.25)
              , mean = mean(RIDAGEYR)
              , sd = sd(RIDAGEYR)
              , perc_90 = quantile(RIDAGEYR, probs = 0.90)
              , perc_95 = quantile(RIDAGEYR, probs = 0.95)
              , perc_99 = quantile(RIDAGEYR, probs = 0.99)
              , max = max(RIDAGEYR))
  print(age_distribution_excluded)

  # Define a vector of the codenames for the included physiological indicators
  pi_include <- dataset_stats %>%
    filter(include == "Yes") %>%
    dplyr::select(pi) %>%
    unlist(., use.names = FALSE)

  # Define a vector of all continuous variables used in the analyses
  continuous_variables <- c(pi_include
                            , "RIDAGEYR"
                            , "PERMTH_INT")

  # Determine the index pertaining to the column containing the codenames of the physiological indicators
  index_colname_pi <- which(colnames(dataset_body_systems) == "pi")

  # Rename the column name as "continuous_variable" for ease of mergining
  colnames(dataset_body_systems)[index_colname_pi] <- "continuous_variable"

  # Define a dataset of the codenames and names of the physiological indicators
  labels_dataset_merged <- data.frame(continuous_variable = colnames(dataset_merged)
                                      , names = get_label(dataset_merged))


  # View(dataset_merged[,c(other_variables, pi_include)] %>%
  #         # Exclude participants with no follow-up data
  #         filter(PERMTH_INT > 0))
  
  # Determine the distribution statistics for each continuous variables
  dataset_continous_stats <- dataset_merged[,c(other_variables, pi_include)] %>%
    # Exclude participants with no follow-up data
    filter(PERMTH_INT > 0) %>%
    # Format from wide to long version
    gather(., continuous_variable, values, continuous_variables) %>%
    # Remove participants with missing data
    na.omit(.) %>%
    group_by(continuous_variable) %>%
    summarise(counts = length(values)
              , min = min(values)
              , perc_01 = quantile(values, probs = 0.01)
              , perc_05 = quantile(values, probs = 0.05)
              , perc_10 = quantile(values, probs = 0.10)
              , median = quantile(values, probs = 0.5)
              , interquartile_range = quantile(values, probs = 0.75) - quantile(values, probs = 0.25)
              , mean = mean(values) 
              , sd = sd(values)
              , perc_90 = quantile(values, probs = 0.90)
              , perc_95 = quantile(values, probs = 0.95)
              , perc_99 = quantile(values, probs = 0.99)
              , max = max(values)) %>%
    ungroup(.) %>%
    # Incorporate the names for the physiological indicators
    left_join(.
              , labels_dataset_merged
              , by = "continuous_variable") %>%
    # Incorporate the body system categories for the physiological indicators
    left_join(.
              , dataset_body_systems
              , by = "continuous_variable")

  # Output the distribution statistics for the continuous variables as a csv file
  # View(dataset_continous_stats)
  write.csv(x = dataset_continous_stats
            , file = "NHANES - Percentiles of Continuous Variables.csv")
  
}