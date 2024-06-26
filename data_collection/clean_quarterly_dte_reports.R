
rm(list=ls())

library(tidyverse)
library(pdftools)

datadir <- "../Data/DTE_Quarterly_Reporting_MPSC"
outdir <- "outputs/DTE_quarter_reports"
quarter_reports <- sort(list.files(file.path(datadir)))

get_section_lines <- function(data, section_regexpr, num_lines_to_keep = 2) {
  # remove all commas (ie 1,500) and separate by new line character
  lines <-  gsub(",", "", data) %>%
    read_lines()
  
  section_lines <- c()
  # Keep relevant lines
  for (i in 1:length(lines)) {
    if (str_detect(lines[i], section_regexpr)) {
      j <- 1
      lines_added <- 1
      # data_regexpr <- "\\s+\\d+\\s+|\\s+\\d+\\s+\\d+\\s+|\\s+\\d+\\s+\\d+\\s+\\d+\\s+|\\s+\\d+\\s+\\d+\\s+\\d+\\s+\\d+\\s+"
      data_header_regexpr <- "^\\s*[A-Za-z]\\."
      while (lines_added <= num_lines_to_keep) {
        if (str_detect(lines[i+j], data_header_regexpr)) {
          section_lines <- c(section_lines, lines[i+j])
          lines_added <- lines_added + 1
        }
        
        j <- j + 1
      }
      
      break
    }
  }
  
  return(section_lines)
}

format_data <- function(lines, year, quarter, item_title, items, val_header) {
  
  if (quarter == 1) {
    headers <- c(
      "item_col",
      paste("01-01-", year, sep = ""),
      paste("01-02-", year, sep = ""),
      paste("01-03-", year, sep = "")
    )
  } else if (quarter == 2) {
    headers <- c(
      "item_col",
      paste("01-04-", year, sep = ""),
      paste("01-05-", year, sep = ""),
      paste("01-06-", year, sep = "")
    )
  } else if (quarter == 3) {
    headers <- c(
      "item_col",
      paste("01-07-", year, sep = ""),
      paste("01-08-", year, sep = ""),
      paste("01-09-", year, sep = "")
    )
  } else if (quarter == 4) {
    headers <- c(
      "item_col",
      paste("01-10-", year, sep = ""),
      paste("01-11-", year, sep = ""),
      paste("01-12-", year, sep = "")
    )
  } else {
    return(data.frame())
  }
  
  num_items <- length(items)
  
  df <- data.frame()
  
  for (i in 1:num_items) {
    
    curr_item_data <- unlist(str_extract_all(lines[i], "\\d+"))
    df <- df %>%
      bind_rows(data.frame(
        item = items[i],
        a = curr_item_data[1],
        b = curr_item_data[2],
        c = curr_item_data[3]
      ))
  }
  
  colnames(df) <- headers
  df <- df %>%
    pivot_longer(-c(item_col), names_to = "date", values_to = val_header)
  
  colnames(df) <- c(item_title, "date", val_header)
  
  
  return(df)
}

for (i in 1:length(quarter_reports)) {
  print(paste("processing", quarter_reports[i]))
  curr_year <- substr(quarter_reports[i], 1, 4)
  curr_quarter <- substr(quarter_reports[i], 6, 6)

  # Read in pdf file as text
  data <- pdf_text(file.path(datadir, quarter_reports[i]))
  
  # Remove all commas
  data <- gsub(",", "", data)
  
  # Special cases for alternative shutoff protection plans
  special_case_a <- "K\\. Total enrolled in program at end of month\\s+Non low-income and non-seniors are included in the month end count for Total\n"
  replace_a <- "K\\. Total enrolled in program at end of month\\s+Non low-income and non-seniors are included in the month end count for Total"
  data <- gsub(pattern = special_case_a, replacement = replace_a, data)
  
  special_case_b <- "K\\. Total enrolled in program at end of month\\s+Non low-income and non-seniors are included in the month end count for Total enrolled in\n"
  replace_b <- "K\\. Total enrolled in program at end of month\\s+Non low-income and non-seniors are included in the month end count for Total enrolled in"
  data <- gsub(pattern = special_case_b, replacement = replace_b, data)
  
  special_case_c <- "K. Total enrolled in program at end of month\\s+Non low-income and non-seniors are included in the month end count for Total enrolled\n"
  replace_c <- "K. Total enrolled in program at end of month\\s+Non low-income and non-seniors are included in the month end count for Total enrolled"
  data <- gsub(pattern = special_case_c, replacement = replace_c, data)
  
  special_case_d <- "K. Total enrolled in program at end of month\\s+Non low-income and non-seniors are included in the month end count for Total enrolled in the\n"
  replace_d <- "K. Total enrolled in program at end of month\\s+Non low-income and non-seniors are included in the month end count for Total enrolled in the"
  data <- gsub(pattern = special_case_d, replacement = replace_d, data)
  
  special_case_e <- "b.   Number of seniors enrolled at end of month\\s+count for Total enrolled in the program\n"
  replace_e <- "b.   Number of seniors enrolled at end of month\\s+count for Total enrolled in the program"
  data <- gsub(pattern = special_case_e, replacement = replace_e, data)
  
  special_case_f <- "I. Total enrolled in program at the end of the month\\s+The month end count is higher than the combined senior and low-income customers\n"
  replace_f <- "I. Total enrolled in program at the end of the month\\s+The month end count is higher than the combined senior and low-income customers"
  data <- gsub(pattern = special_case_f, replacement = replace_f, data)
  
  special_case_g <- "I\\.\n"
  replace_g <- "I\\."
  data <- gsub(pattern = special_case_g, replacement = replace_g, data)
  
  special_case_h <- "I. Total enrolled in program at the end of the month\\s+The month end count is higher than the combined senior and low-income customers because DTE has\n"
  replace_h <- "I. Total enrolled in program at the end of the month\\s+The month end count is higher than the combined senior and low-income customers because DTE has"
  data <- gsub(pattern = special_case_h, replacement = replace_h, data)
  
  special_case_i <- "I.\\s+The month end count is higher than the combined senior and low-income customers\n"
  replace_i <- "I.\\s+The month end count is higher than the combined senior and low-income customers"
  data <- gsub(pattern = special_case_i, replacement = replace_i, data)
  
  # Collecting disconnections due to non-payment from PDF to CSV
  shutoff_lines <- get_section_lines(data, "Total of customers physically discontinued due to non-payment", 2)
  shutoffs <- format_data(shutoff_lines, curr_year, curr_quarter,
                          "utility", c("Electric", "Natural Gas"), "disconnections")
  disconnections_outfile <- paste("disconnections_", curr_year, "_q", curr_quarter, ".csv", sep = "")
  write.csv(shutoffs, file.path(outdir, disconnections_outfile), row.names = FALSE)
  
  # Collecting total number of customers restored
  restoration_lines <- get_section_lines(data, "Total number of customers restored", 2)
  restorations <- format_data(restoration_lines, curr_year, curr_quarter,
                              "utility", c("Electric", "Natural Gas"), "restorations")
  restorations_outfile <- paste("restorations_", curr_year, "_q", curr_quarter, ".csv", sep = "")
  write.csv(restorations, file.path(outdir, restorations_outfile), row.names = FALSE)
  
  # Collecting total number of enrollments in alternative shutoff protection plan
  # Note this has to include total enrollments to calculate number of non low income non seniors
  alt_shutoff_lines <- get_section_lines(data, "Alternative Shutoff Protection Plan", 3)
  alt_shutoff_enrollments <- format_data(alt_shutoff_lines, curr_year, curr_quarter,
                                         "customer_grp", c("total", "low_income", "seniors"), "enrollments")
  alt_shutoff_outfile <- paste("alternative_shutoff_protection_plan_", curr_year, "_q", curr_quarter, ".csv", sep = "")
  write.csv(alt_shutoff_enrollments, file.path(outdir, alt_shutoff_outfile), row.names = FALSE)
  
  # Collecting total number of enrollments in alternative shutoff protection plan
  # Note this has to include total enrollments to calculate number of non low income non seniors
  wpp_lines <- get_section_lines(data, "Winter Protection Plan \\(WPP\\)", 3)
  wpp_enrollments <- format_data(wpp_lines, curr_year, curr_quarter,
                                         "customer_grp", c("total", "low_income", "seniors"), "enrollments")
  wpp_outfile <- paste("winter_protection_plan_", curr_year, "_q", curr_quarter, ".csv", sep = "")
  write.csv(wpp_enrollments, file.path(outdir, wpp_outfile), row.names = FALSE)
  
  print(paste("writing", curr_year, curr_quarter))
}

print("DONE")
