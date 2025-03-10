# Yajiang Fire Analysis Script

# ----------------------------------------------------------
# Environment Setup
# ----------------------------------------------------------
rm(list = ls(all = TRUE))
cat("\014")
graphics.off()
shell("cls")
options(scipen = 999)
gc()

library(terra)
library(tidyterra)
library(tidyverse)
library(ggplot2)
# ----------------------------------------------------------
# Load Raster Stack and Subset Indices
# ----------------------------------------------------------
masked_rasters_stack <- rast('Analysis/BurnSeverity/FireIndices_Yajiang_24.tif')

nbr_stack <- subset(masked_rasters_stack, grep("_NBR$", names(masked_rasters_stack)))
ndvi_stack <- subset(masked_rasters_stack, grep("_NDVI$", names(masked_rasters_stack)))
bais2_stack <- subset(masked_rasters_stack, grep("_BAIS2$", names(masked_rasters_stack)))

# ----------------------------------------------------------
# Summary Statistics for BAIS2
# ----------------------------------------------------------
bais2_summary <- data.frame(
  Month = names(bais2_stack),
  Min = numeric(nlyr(bais2_stack)),
  Max = numeric(nlyr(bais2_stack)),
  Mean = numeric(nlyr(bais2_stack)),
  Median = numeric(nlyr(bais2_stack)),
  SD = numeric(nlyr(bais2_stack))
)

for (i in 1:nlyr(bais2_stack)) {
  values_i <- values(bais2_stack[[i]], na.rm = TRUE)
  bais2_summary[i, 2:6] <- c(min(values_i), max(values_i), mean(values_i), median(values_i), sd(values_i))
}

bais2_summary$Month <- as.Date(paste0(sub("_BAIS2", "", bais2_summary$Month), "-01"), "%Y-%m-%d")

ggplot(bais2_summary, aes(x = Month)) +
  geom_line(aes(y = Mean, color = "Mean"), size = 1) +
  geom_line(aes(y = Median, color = "Median"), linetype = "dashed") +
  geom_line(aes(y = SD, color = "SD"), linetype = "dotted") +
  scale_color_manual(values = c("Mean" = "blue", "Median" = "green", "SD" = "red")) +
  labs(title = "BAIS2 Monthly Trends", x = "Month", y = "BAIS2 Value", color = "Legend") +
  theme_minimal()

# ----------------------------------------------------------
# Fire Detection Using BAIS2
# ----------------------------------------------------------
fire_threshold <- 0.85
binary_stack <- app(bais2_stack, fun = function(x) ifelse(x > fire_threshold, 1, 0))
names(binary_stack) <- names(bais2_stack)

result <- data.frame(
  Month = names(binary_stack),
  CountAboveThreshold = sapply(1:nlyr(binary_stack), function(i) {
    sum(values(binary_stack[[i]]) == 1, na.rm = TRUE)
  })
)
print(result[result$CountAboveThreshold > 0, ])

writeRaster(binary_stack, "Analysis/BurnSeverity/fire_analysis_results/Yajian-bais2_stack_24.tif", overwrite = TRUE)

# ----------------------------------------------------------
# Fire Detection Using NBR
# ----------------------------------------------------------
nbr_threshold <- -0.1
binary_stack_nbr <- app(nbr_stack, fun = function(x) ifelse(x > nbr_threshold, 0, 1))
names(binary_stack_nbr) <- names(nbr_stack)

result_nbr <- data.frame(
  Month = names(binary_stack_nbr),
  CountAboveThreshold = sapply(1:nlyr(binary_stack_nbr), function(i) {
    sum(values(binary_stack_nbr[[i]]) == 1, na.rm = TRUE)
  })
)
print(result_nbr[result_nbr$CountAboveThreshold > 0, ])

writeRaster(binary_stack_nbr, "Yajiang-nbr_stack_24.tif", overwrite = TRUE)

