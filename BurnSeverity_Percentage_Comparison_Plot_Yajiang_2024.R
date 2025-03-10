# Clear environment
rm(list = ls(all=TRUE))
cat("\014")
graphics.off()
options(scipen = 999)
gc()

# Load necessary libraries
library(ggplot2)
library(tidyr)
library(dplyr)
library(ggprism)
library(extrafont)
library(RColorBrewer)

# Set working directory
setwd("Working Dir")

# Burn severity data
burn_severity_data <- data.frame(
  Class = 1:6,
  Class_Name = c("Enhanced Regrowth", "Unburned", "Low Severity", 
                 "Moderate-Low Severity", "Moderate-High Severity", "High Severity"),
  Area_RBR = c(2619.43, 14805.94, 7604.78, 10392.94, 3964.32, 0.97),
  Percentage_RBR = c("6.65%", "37.59%", "19.31%", "26.39%", "10.06%", "0.00%"),
  Area_RdNBR = c(2205.06, 6938.34, 3498.44, 2415.75, 3869.73, 14256.32),
  Percentage_RdNBR = c("6.65%", "20.91%", "10.54%", "7.28%", "11.66%", "42.96%"),
  Area_dBAIS2 = c(8778.59, 9696.59, 4973.41, 6155.02, 7684.53, 2100.24),
  Percentage_dBAIS2 = c("22.29%", "24.62%", "12.63%", "15.63%", "19.51%", "5.33%"),
  Area_dNBR = c(2943.23, 13401.56, 6114.89, 6365.00, 8154.96, 2408.72),
  Percentage_dNBR = c("7.47%", "34.02%", "15.52%", "16.16%", "20.70%", "6.12%")
)

# Convert percentage columns to numeric
burn_severity_data <- burn_severity_data %>%
  mutate(across(starts_with("Percentage"), ~as.numeric(gsub("%", "", .x))))

# Reshape to long format
burn_severity_long <- burn_severity_data %>%
  pivot_longer(
    cols = starts_with("Percentage"),
    names_to = "Index",
    values_to = "Percentage"
  ) %>%
  mutate(
    Index = factor(Index, 
                  levels = c("Percentage_RBR", "Percentage_RdNBR", "Percentage_dBAIS2", "Percentage_dNBR"),
                  labels = c("RBR", "RdNBR", "dBAIS2", "dNBR")),
    Class_Name = factor(Class_Name, 
                        levels = c("Enhanced Regrowth", "Unburned", "Low Severity", 
                                   "Moderate-Low Severity", "Moderate-High Severity", "High Severity"),
                        labels = c("EG", "UB", "LS", "MLS", "MHS", "HS"))
  )

# Plot with RColorBrewer palette
severity_plot <- ggplot(burn_severity_long, aes(x = Index, y = Percentage, fill = Class_Name)) +
  geom_bar(stat = "identity", position = "stack", width = 0.7) +
  geom_text(
    aes(label = sprintf("%.1f%%", Percentage)),
    position = position_stack(vjust = 0.5),
    size = 3, family = "Times New Roman", fontface = "bold"
  ) +
  labs(
    x = "Index",
    y = "Percentage (%)",
    fill = "Severity Class"
  ) +
  theme_prism() +
  scale_fill_brewer(palette = "YlOrRd") +
  theme(
    text = element_text(family = "Times New Roman"),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    legend.text = element_text(size = 12),
    legend.title = element_text(size = 13, face = "bold"),
    plot.title = element_blank()
  )

# Display the plot
print(severity_plot)

# Save the plot
ggsave("MapsAndPlots/Severity_Percentage_Comparison.png", severity_plot, width = 7, height = 5, dpi = 400)