library(boot)
library(MASS)
library(plyr)
library(dplyr)
library(ggplot2)
library(tibble)
library(reshape2)
library(epitools)
library(readxl)
library(tidyverse)
library(readr)
library(arsenal)
source("https://raw.githubusercontent.com/koundy/ggplot_theme_Publication/master/ggplot_theme_Publication-2.R")
library(patchwork)
library(palmerpenguins)
library(viridis)
library(gt)
library(gtExtras)
library(RColorBrewer)
library(reshape2)
library(knitr)
library(vtable)
library(ggrepel)

#####Setup#####

#--------------any libraries needed are loaded and displayed below--------------
#
library(dplyr)
library(zoo)
library(kableExtra)
#
#--------------make project folders and folder paths----------------------------

library(httpgd)
hgd()

wd <- getwd()  # working directory

folders <- c("Data Output", "Figures")
# function to create folders below
for(i in 1:length(folders)){
  if(file.exists(folders[i]) == FALSE)
    dir.create(folders[i])
}


# we also need to store the paths to these new folders
data.output.path <- paste(wd, "/", folders[1], sep = "")
figures.path <- paste(wd, "/", folders[2], sep = "")


# now we can access and save stuff to these folders!



#---------------------Below, we upload and clean the data----------


#first, lets load in out data. Do this either by selecting the drop down menu
#go to file, import data, import data Future_Bio_Riskom excel, and import your data
#copy and paste the output Future_Bio_Riskom the console tab below, like I did here
#alternativley, just run my code below
#make sure you name and assign your new spreadsheet, below I assign this import
#by naming it "nuseds" below, now when I use the name nuseds, it will be called
#on in the program
data.path <- paste(wd, "/", "Data", sep = "")

#################### Risk Table ####################
FWRA <- read_excel(paste(data.path, "FWRA_2021_RESULTS_MASTER.xlsx", sep = "/"), sheet = 1)


FWRA <- subset(FWRA, LF_Number != "23" & LF_Number != "24")

#add "LF" before LF number
FWRA$LF <- paste("LF", FWRA$LF_Number, sep = "")

FWRA$Current_Bio_Risk <- as.character(FWRA$Current_Bio_Risk)
FWRA$Future_Bio_Risk <- as.character(FWRA$Future_Bio_Risk)

#change all numeric values to character
FWRA$Current_Bio_Risk[FWRA$Current_Bio_Risk=="1"]<-"VL"
FWRA$Current_Bio_Risk[FWRA$Current_Bio_Risk=="2"]<-"L"
FWRA$Current_Bio_Risk[FWRA$Current_Bio_Risk=="3"]<-"M"
FWRA$Current_Bio_Risk[FWRA$Current_Bio_Risk=="4"]<-"H"
FWRA$Current_Bio_Risk[FWRA$Current_Bio_Risk=="5"]<-"VH"
FWRA$Current_Bio_Risk[FWRA$Current_Bio_Risk=="0"]<-"LPDG"
FWRA$Current_Bio_Risk[FWRA$Current_Bio_Risk=="-1"]<-"HPDG"


FWRA$Future_Bio_Risk[FWRA$Future_Bio_Risk=="1"]<-"VL"
FWRA$Future_Bio_Risk[FWRA$Future_Bio_Risk=="2"]<-"L"
FWRA$Future_Bio_Risk[FWRA$Future_Bio_Risk=="3"]<-"M"
FWRA$Future_Bio_Risk[FWRA$Future_Bio_Risk=="4"]<-"H"
FWRA$Future_Bio_Risk[FWRA$Future_Bio_Risk=="5"]<-"VH"
FWRA$Future_Bio_Risk[FWRA$Future_Bio_Risk=="0"]<-"LPDG"
FWRA$Future_Bio_Risk[FWRA$Future_Bio_Risk=="-1"]<-"HPDG"


####Risk Ranked Across All LFs and Spatial Scales####
# remove HPDG and LPDG from data
library(tidyr)
library(dplyr)

# Add 0s to missing values in current risk column and future risk column
FWRA$Current_Bio_Risk[FWRA$Current_Bio_Risk==""]<-"0"
FWRA$Future_Bio_Risk[FWRA$Future_Bio_Risk==""]<-"0"



# Define a function to add missing columns to a data frame and fill them with 0s
add_missing_columns <- function(df, columns) {
  for (column in columns) {
    if (!column %in% colnames(df)) {
      df[[column]] <- 0
    }
  }
  return(df)
}

# Define a function to process filtered data: calculate proportions, sort risks, and save to a CSV file
process_filtered_data <- function(filtered_data, risk_column, file_suffix) {
  risk_summary <- filtered_data %>%
    mutate(VH = ifelse(!!sym(risk_column) %in% c("VH"), 1, 0),
           H = ifelse(!!sym(risk_column) %in% c("H"), 1, 0),
           M = ifelse(!!sym(risk_column) %in% c("M"), 1, 0),
           L = ifelse(!!sym(risk_column) %in% c("L"), 1, 0),
           VL = ifelse(!!sym(risk_column) %in% c("VL"), 1, 0), 
           LPDG = ifelse(!!sym(risk_column) %in% c("LPDG"), 1, 0),
            HPDG = ifelse(!!sym(risk_column) %in% c("HPDG"), 1, 0)) %>%
            
    group_by(LF_Number) %>%
    summarise(VH_total_count = sum(VH),
              H_total_count = sum(H),
              M_total_count = sum(M),
              L_total_count = sum(L),
              VL_total_count = sum(VL),
              LPDG_total_count = sum(LPDG),
              HPDG_total_count = sum(HPDG),
              total_count = n()) %>% # Count the total number of rows in the filtered_data
    mutate(VH_total_prop = VH_total_count / total_count,
           H_total_prop = H_total_count / total_count,
           M_total_prop = M_total_count / total_count,
           L_total_prop = L_total_count / total_count,
           VL_total_prop = VL_total_count / total_count,
           LPDG_total_prop = LPDG_total_count / total_count,
            HPDG_total_prop = HPDG_total_count / total_count)

  # Sort the risk summary data frame by the highest proportion for each risk level in the order of risk levels
  sorted_risks <- risk_summary %>%
    arrange(desc(VH_total_prop), desc(H_total_prop), desc(M_total_prop), desc(L_total_prop), desc(VL_total_prop))

  # Print the sorted risks data frame to the console
  cat("\nSorted Risks for", file_suffix, ":\n")
  print(sorted_risks)

  # Save the sorted risks data frame to a CSV file
  write.csv(sorted_risks, file = paste0(data.output.path, "/sorted_risks_", file_suffix, ".csv"))
}


# Get unique values for LF_Number, CU_ACRO, Area, and SYSTEM_SITE
unique_lf_numbers <- unique(FWRA$LF_Number)
unique_cu_acros <- unique(FWRA$CU_ACRO)
unique_areas <- unique(FWRA$Area)
unique_system_sites <- unique(FWRA$SYSTEM_SITE)

# Loop for CU_ACRO current risk
    for (cu_acro in unique_cu_acros) {
      filtered_data <- FWRA %>%
        filter(CU_ACRO == cu_acro)
      process_filtered_data(filtered_data, "Current_Bio_Risk", paste("CU_ACRO_Current", cu_acro, sep="_"))
    }

# Loop for CU_ACRO future risk
    for (cu_acro in unique_cu_acros) {
      filtered_data <- FWRA %>%
        filter(CU_ACRO == cu_acro)
      process_filtered_data(filtered_data, "Future_Bio_Risk", paste("CU_ACRO_Future", cu_acro, sep="_"))
    }

# Loop for Area current risk
    for (area in unique_areas) {
      filtered_data <- FWRA %>%
        filter(Area == area)
      process_filtered_data(filtered_data, "Current_Bio_Risk", paste("Area_Current", area, sep="_"))
    }

# Loop for Area future risk
    for (area in unique_areas) {
      filtered_data <- FWRA %>%
        filter(Area == area)
      process_filtered_data(filtered_data, "Future_Bio_Risk", paste("Area_Future", area, sep="_"))
    }

# Loop for SYSTEM_SITE current risk
    for (system_site in unique_system_sites) {
      filtered_data <- FWRA %>%
        filter(SYSTEM_SITE == system_site)
      process_filtered_data(filtered_data, "Current_Bio_Risk", paste("SYSTEM_SITE_Current", system_site, sep="_"))
    }

# Loop for SYSTEM_SITE future risk
    for (system_site in unique_system_sites) {
      filtered_data <- FWRA %>%
        filter(SYSTEM_SITE == system_site)
      process_filtered_data(filtered_data, "Future_Bio_Risk", paste("SYSTEM_SITE_Future", system_site, sep="_"))
    }
