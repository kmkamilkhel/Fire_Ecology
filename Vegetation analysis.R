
# Load required libraries
library(terra)
library(ggplot2)
library(ggprism)
library(patchwork)
library(extrafont)

# --------------------------------------------------------
# Load Burn Severity and Recovery Index Rasters
# --------------------------------------------------------
rbr <- rast("rbr.tif")
rdnbr <- rast("rdnbr.tif")
dNDVI <- rast("dNDVI.tif")
dKNDVI <- rast("dKNDVI.tif")

# Align RBR and RdNBR with dNDVI spatially
rbr_aligned <- resample(rbr, dNDVI)
rdnbr_aligned <- resample(rdnbr, dNDVI)

# --------------------------------------------------------
# Burn Severity Classification (Based on RBR/RdNBR)
# --------------------------------------------------------
severity_matrix <- matrix(c(
  -Inf, -0.1, -1,   # Enhanced Regrowth (ER)
  -0.1,  0.1,  0,   # Unburned (UB)
  0.1,  0.27, 1,    # Low Severity (LS)
  0.27, 0.44, 2,    # Moderate-Low Severity (MLS)
  0.44, 0.66, 3,    # Moderate-High Severity (MHS)
  0.66,  Inf, 4     # High Severity (HS)
), ncol = 3, byrow = TRUE)

classified_rbr <- classify(rbr_aligned, severity_matrix)
classified_rdnbr <- classify(rdnbr_aligned, severity_matrix)

# --------------------------------------------------------
# Mask Recovery Indices by Classified RBR Severity
# --------------------------------------------------------
dNDVI_masked <- mask(dNDVI, classified_rbr)
dKNDVI_masked <- mask(dKNDVI, classified_rbr)

# --------------------------------------------------------
# Classify Recovery into Categories
# --------------------------------------------------------
recovery_matrix <- matrix(c(
  -Inf, -0.5, -1,  # Severe Loss
  -0.5,  0.0,  0,  # Moderate Loss
  0.0,  0.5,  1,   # Moderate Gain
  0.5,  Inf,  2    # High Gain
), ncol = 3, byrow = TRUE)

dNDVI_classified <- classify(dNDVI_masked, recovery_matrix)
dKNDVI_classified <- classify(dKNDVI_masked, recovery_matrix)

# Save classified rasters
writeRaster(dNDVI_classified, "Analysis/BurnSeverity/fire_analysis_results/dNDVI_Recovery_byRBR.tif", overwrite = TRUE)
writeRaster(dKNDVI_classified, "Analysis/BurnSeverity/fire_analysis_results/dKNDVI_Recovery_byRBR.tif", overwrite = TRUE)

# --------------------------------------------------------
# Area Calculation for Recovery Classes
# --------------------------------------------------------
area_table <- function(classified_raster) {
  area_df <- expanse(classified_raster, unit = "ha", byValue = TRUE)
  colnames(area_df) <- c("Layer", "Class", "Area_ha")
  total_area <- sum(area_df$Area_ha)
  area_df$Percentage <- (area_df$Area_ha / total_area) * 100
  recovery_labels <- c("Severe Loss", "Moderate Loss", "Moderate Gain", "High Gain")
  area_df$Class_Name <- recovery_labels[area_df$Class + 2]  # Shift for negative values
  return(area_df)
}

area_dNDVI <- area_table(dNDVI_classified)
area_dKNDVI <- area_table(dKNDVI_classified)

print(area_dNDVI)
print(area_dKNDVI)

# --------------------------------------------------------
# Correlation Between Severity and Recovery
# --------------------------------------------------------
# Extract values
df <- data.frame(
  RBR = values(classified_rbr),
  dNDVI = values(dNDVI),
  dKNDVI = values(dKNDVI)
)

# Remove NA rows
df <- df[complete.cases(df), ]

# Compute correlation
cor_ndvi <- cor(df$RBR, df$dNDVI, use = "complete.obs")
cor_kndvi <- cor(df$RBR, df$dKNDVI, use = "complete.obs")

cat("Correlation (RBR vs dNDVI):", round(cor_ndvi, 3), "\n")
cat("Correlation (RBR vs dKNDVI):", round(cor_kndvi, 3), "\n")

# --------------------------------------------------------
# Visualization: Burn Severity vs Vegetation Recovery
# --------------------------------------------------------
# Sample for scatter plot
set.seed(123)
sample_n <- 10000
df_sample <- df[sample(1:nrow(df), min(sample_n, nrow(df))), ]

# Severity labels
severity_labels <- c("-1" = "ER", "0" = "UB", "1" = "LS", "2" = "MLS", "3" = "MHS", "4" = "HS")

# Plot A: RBR vs dNDVI
plot_a <- ggplot(df_sample, aes(x = as.numeric(RBR), y = dNDVI)) +
  geom_point(alpha = 0.6, color = "blue") +
  geom_smooth(method = "lm", color = "red", se = FALSE) +
  scale_x_continuous(breaks = as.numeric(names(severity_labels)),
                     labels = severity_labels) +
  labs(title = "(a)", x = "Burn Severity", y = "dNDVI") +
  theme_prism(base_family = "Times New Roman") +
  theme(axis.title = element_text(size = 14, face = "bold"),
        axis.text = element_text(size = 12),
        plot.title = element_text(size = 16, face = "bold"))

# Plot B: RBR vs dKNDVI
plot_b <- ggplot(df_sample, aes(x = as.numeric(RBR), y = dKNDVI)) +
  geom_point(alpha = 0.6, color = "darkgreen") +
  geom_smooth(method = "lm", color = "red", se = FALSE) +
  scale_x_continuous(breaks = as.numeric(names(severity_labels)),
                     labels = severity_labels) +
  labs(title = "(b)", x = "Burn Severity", y = "dKNDVI") +
  theme_prism(base_family = "Times New Roman") +
  theme(axis.title = element_text(size = 14, face = "bold"),
        axis.text = element_text(size = 12),
        plot.title = element_text(size = 16, face = "bold"))

# Combine Plots
combined_plot <- plot_a + plot_b + plot_layout(ncol = 2)

# Save final plot
ggsave("MapsAndPlots/BurnSeverity_vs_Recovery_dNDVI_dKNDVI.png",
       plot = combined_plot, width = 12, height = 6, dpi = 400)
