# Plot daily upwelling

library(tidyverse)

#locations <- c("45N", "39N", "33N")
locations <- c("30N","36N","42N","48N")

data_list <- lapply(locations, function(loc) {
  
  # Construct the dynamic URL
  base_url <- "https://oceanview.pfeg.noaa.gov/erddap/tabledap/cciea_OC_UI_day.csv"
  query <- paste0('?time,upwelling_index&time>=now-90days&lat="', loc, '"')
  url <- URLencode(paste0(base_url, query))
  
  # Fetch headers and data ERDDAP .csv has a header row and a units row (hence skip = 2)
  headers <- read.csv(url, skip = 0, header = FALSE, nrows = 1, as.is = TRUE)
  data_temp <- read.csv(url, skip = 2, header = FALSE)
  colnames(data_temp) <- headers
  
  # Rename the upwelling index column to the specific location (e.g., "45N")
  colnames(data_temp)[2] <- loc
  
  return(data_temp)
  })

  # Join all data frames into one then pivot to make use of ggplot auto legend
  df_combined <- data_list %>% 
  reduce(full_join, by = "time")

  df_combined$time <- as.Date(df_combined$time)

  df_long <- df_combined %>%
  pivot_longer(cols = -time, names_to = "Lat", values_to = "upwelling_index")
    
  ggplot(df_long, aes(x = time, y = upwelling_index, color = Lat)) +
    geom_hline(yintercept = 0, color = "gray70", linewidth = 0.5) +  geom_line(linewidth = 0.8) +
    guides(color = guide_legend(nrow = 1, byrow = TRUE, reverse = TRUE)) +
    theme_minimal() + 
    theme(
      # Remove all gridlines
      panel.grid.minor = element_blank(),
      # Add the dark box around the plot
      panel.border = element_rect(colour = "black", fill = NA, linewidth = 1),
      # Adjust the right margin so tick label isn't cut off unit(t, r, b, l) -> top, right, bottom, left
      plot.margin = unit(c(.5, 2, 1, 1), "lines"),
      axis.text = element_text(color = "black", size = 10), 
      axis.ticks = element_line(colour = "black"),
      # This gives a deprecation error, but only way to get the legend and title on the same line
#      legend.position = c(1, 1.05),
     legend.position = "top",
#      legend.location="top",
      legend.justification = c("right"), # Anchors the legend's corner 
      legend.direction = "horizontal", # Ensure the overall direction is horizontal (often default when position is top/bottom)
      # Add a white background to the legend so lines don't run through it
      legend.background = element_rect(fill = "white", color = "black", linewidth = 0.2),
      legend.box.margin = margin(0, 0, -5, 0),
      plot.title=element_text(hjust=0, vjust=-15),
      plot.subtitle=element_text(hjust=.6, vjust=-18, size = 9, face = "italic")
      ) +
    labs(
      title = "Bakun Daily Upwelling Index",
      subtitle = paste0("updated ",tail(df_combined$time,1)),
      x = "",
      y = "Upwelling Index",
      color = ""
      ) +
    scale_x_date(date_labels = "%b %d, %Y", date_breaks = "2 weeks")
  
ggsave(
  filename = "images/daily_upwell.png", 
  plot = last_plot(),         # Saves the most recent plot
  device = "png",             # File format
  width = 10,                 # Width in inches
  height = 5,                 # Height in inches
  dpi = 300,                  # High resolution for printing/presentations
  bg = "white"                # Ensures the background isn't transparent
)

