# ------------------------------------------------------------------
# Initialization and Setup
# ------------------------------------------------------------------
rm(list = ls(all = TRUE))
cat("\014"); graphics.off(); shell("cls")
options(scipen = 999)
gc()

library(randomForest)
library(iml)
library(ggplot2)
library(ggprism)
library(extrafont)


# ------------------------------------------------------------------
# Load Cleaned Data
# ------------------------------------------------------------------
points_cleaned <- read.csv("Analysis/BurnSeverity/fire_analysis_results/ML_Works/ML_points_cleaned.csv")
points_cleaned$severity <- as.factor(points_cleaned$severity)

# ------------------------------------------------------------------
# Prepare Training Data for RF
# ------------------------------------------------------------------
X <- points_cleaned[, -which(names(points_cleaned) == "severity")]
y <- points_cleaned$severity

# Check class levels
levels(y)

# ------------------------------------------------------------------
# Train Random Forest Model
# ------------------------------------------------------------------
set.seed(123)
rf_model_new <- randomForest(
  x = X,
  y = y,
  ntree = 500,
  mtry = 6,
  importance = TRUE
)

print(rf_model_new)
print(rf_model_new$confusion)
varImpPlot(rf_model_new, type = 1, main = "Variable Importance (Mean Decrease Accuracy)")

# ------------------------------------------------------------------
# SHAP Analysis using IML
# ------------------------------------------------------------------

# Define custom predict function
predict_function <- function(model, newdata) {
  colnames(newdata) <- colnames(X)
  predict(model, newdata = newdata, type = "prob")
}

# Create iml Predictor object
rf_predictor <- Predictor$new(
  model = rf_model_new,
  data = X,
  y = y,
  predict.fun = predict_function,
  type = "prob"
)

# Sample 100 observations for SHAP
num_samples <- 100
sample_indices <- sample(1:nrow(X), num_samples)

# Compute SHAP values
shapley <- Shapley$new(
  predictor = rf_predictor,
  x.interest = X[sample_indices, ],
  sample.size = 100
)

# Extract SHAP plot data
shap_plot <- plot(shapley)
shap_data <- shap_plot$data

# ------------------------------------------------------------------
# Customize and Save SHAP Plot for Multiple Classes
# ------------------------------------------------------------------

# Map severity classes to names
severity_labels <- c("3" = "Low Severity", "4" = "Moderate Low", 
                     "5" = "Moderate High", "6" = "High Severity")

# Generate SHAP plot
customized_plot <- ggplot(shap_data, aes(x = phi, y = feature, fill = class)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  geom_text(aes(label = round(phi, 3)),
            hjust = ifelse(shap_data$phi > 0, -0.2, 1.2),
            size = 3) +
  facet_wrap(~class, labeller = labeller(class = severity_labels)) +
  scale_fill_manual(values = c("3" = "#F8766D", "4" = "#7CAE00", 
                               "5" = "#00BFC4", "6" = "#C77CFF")) +
  labs(x = "SHAP Value (phi)", y = "Features") +
  theme_prism(base_size = 14, base_family = "Times New Roman") +
  theme(
    strip.text = element_text(size = 12, face = "bold"),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 10),
    legend.position = "none"
  )

# Display and save plot
print(customized_plot)

ggsave("Analysis/BurnSeverity/fire_analysis_results/ML_Works/SHAP_MultiClass_RF.png",
       plot = customized_plot, width = 9, height = 5, dpi = 400)

# ------------------------------------------------------------------
# Global Feature Importance (SHAP)
# ------------------------------------------------------------------
feature_imp <- FeatureImp$new(
  predictor = rf_predictor,
  loss = "ce"  # Cross-entropy for classification
)

# Plot and save
global_plot <- plot(feature_imp) +
  ggtitle("Global Feature Importance based on SHAP Values") +
  theme_minimal(base_family = "Times New Roman")

print(global_plot)

ggsave("Analysis/BurnSeverity/fire_analysis_results/ML_Works/SHAP_Global_RF.png",
       plot = global_plot, width = 8, height = 6, dpi = 400)
