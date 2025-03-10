rm(list = ls(all=TRUE))
cat("\014")
graphics.off()
shell("cls")
options(scipen = 999)
gc()

library(terra)
library(reshape2)
library(ggplot2)
library(ggprism)
library(extrafont)

setwd("D:\\New Volume S\\PHD\\PHD-2024-26\\writeups\\Shoaib_SheraniPlusMargalla")

Nbr_burned <- rast("Yajiang-nbr_stack_24.tif")
Bai2_burned <- rast("Yajian-bais2_stack_24.tif")

# Function to calculate burned area in hectares and percentage
calculate_burned_area <- function(raster_stack) {
  results <- data.frame(
    Month = names(raster_stack),
    Burned_Area_ha = numeric(length(raster_stack)),
    Burned_Percentage = numeric(length(raster_stack))
  )
  for (i in 1:nlyr(raster_stack)) {
    layer <- raster_stack[[i]]
    area_by_value <- expanse(layer, unit = "ha", byValue = TRUE)
    burned_area_ha <- area_by_value[area_by_value$value == 1, "area"]
    total_area_ha <- sum(area_by_value$area)
    burned_percentage <- (burned_area_ha / total_area_ha) * 100
    results$Burned_Area_ha[i] <- ifelse(length(burned_area_ha) > 0, burned_area_ha, 0)
    results$Burned_Percentage[i] <- ifelse(length(burned_percentage) > 0, burned_percentage, 0)
  }
  return(results)
}

nbr_burned_results <- calculate_burned_area(Nbr_burned)
bai2_burned_results <- calculate_burned_area(Bai2_burned)

nbr_burned_results$Burned_Area_ha[nbr_burned_results$Month == "2024-01_NBR"] <- 0
nbr_burned_results$Month <- factor(nbr_burned_results$Month, 
                                   levels = c("2024-01_NBR", "2024-03_NBR", "2024-04_NBR", "2024-08_NBR", "2024-10_NBR"))

j <- ggplot(nbr_burned_results, aes(x = Month, y = Burned_Area_ha, fill = Burned_Area_ha)) +
  geom_bar(stat = "identity", width = 0.6) +
  geom_text(aes(label = round(Burned_Area_ha, 0)), vjust = -0.5, color = "black", size = 5, family = "Times New Roman", fontface = "bold") +
  scale_fill_gradient(low = "black", high = "darkred") +
  scale_y_continuous(
    breaks = seq(0, max(nbr_burned_results$Burned_Area_ha), length.out = 5),
    labels = scales::comma
  ) +
  labs(
    title = "Monthly Burned Area",
    x = "Month",
    y = "Burned Area (ha)"
  ) +
  scale_x_discrete(labels = c("Jan", "Mar", "Apr", "Aug", "Oct")) +
  theme_prism() +
  theme(
    plot.title = element_text(size = 18, face = "bold", family = "Times New Roman", color = "black"),
    axis.title = element_text(size = 16, face = "bold", family = "Times New Roman", color = "black"),
    axis.text = element_text(size = 14, face = "bold", family = "Times New Roman", color = "black"),
    legend.position = "none",
    panel.grid = element_blank(),
    plot.caption = element_text(size = 12, face = "bold", family = "Times New Roman", color = "black", hjust = 0.5)
  )

print(j)

ggsave(
  filename = "MapsAndPlots/MonthlyBurntareas.png",
  plot = j,
  dpi = 400,
  width = 6,
  height = 6
)
