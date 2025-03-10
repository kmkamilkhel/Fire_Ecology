# Load required libraries
library(pROC)
library(ggplot2)
library(ggprism)
library(extrafont)
library(cowplot)

# Define burn severity class labels
class_labels <- c("Low Severity", "Moderate Low", "Moderate High", "High Severity")

# Get predicted probabilities from the RF model
test_probs <- predict(rf_model, newdata = test_data, type = "prob")

# Initialize containers
roc_data <- data.frame()
auc_values <- list()

# Loop to compute ROC and AUC for each class
for (i in seq_along(levels(test_data$severity))) {
  class_level <- levels(test_data$severity)[i]
  binary_truth <- ifelse(test_data$severity == class_level, 1, 0)
  
  roc_curve <- roc(binary_truth, test_probs[[class_level]])
  auc_values[[class_labels[i]]] <- auc(roc_curve)
  
  class_roc_df <- data.frame(
    fpr = 1 - roc_curve$specificities,
    tpr = roc_curve$sensitivities,
    class = class_labels[i]
  )
  
  roc_data <- rbind(roc_data, class_roc_df)
}

# Prepare AUC labels for the legend
auc_labels <- paste(names(auc_values), "(AUC =", round(unlist(auc_values), 2), ")")

# Create ROC plot for multi-class
multi_roc_plot <- ggplot(roc_data, aes(x = fpr, y = tpr, color = class)) +
  geom_line(size = 1.2) +
  geom_abline(linetype = "dashed", color = "black") +
  labs(
    x = "False Positive Rate", 
    y = "True Positive Rate", 
    color = "Burn Severity"
  ) +
  scale_color_manual(values = c("red", "green", "blue", "purple"), labels = auc_labels) +
  theme_prism(base_family = "Times New Roman") +
  theme(
    plot.title = element_blank(),
    axis.title = element_text(face = "bold", color = "black"),
    axis.text = element_text(color = "black"),
    legend.title = element_text(face = "bold"),
    legend.text = element_text(size = 10),
    plot.margin = unit(c(10, 10, 10, 10), "pt")
  )

# OPTIONAL: Save ROC plot
# ggsave("Analysis/BurnSeverity/fire_analysis_results/ML_Works/burn_severity_roc_curve.png",
#        plot = multi_roc_plot, width = 10, height = 6, dpi = 300)

# Assume `roc_plot_updated2` is the ROC plot for binary classification or index-based evaluation
roc_plot_labeled <- roc_plot_updated2 + 
  ggtitle("(A)") + 
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"))

multi_roc_labeled <- multi_roc_plot + 
  ggtitle("(B)") + 
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"))

# Combine both plots horizontally
combined_plots <- plot_grid(
  roc_plot_labeled, 
  multi_roc_labeled, 
  ncol = 2, 
  rel_widths = c(1, 1.2),
  align = "v"
)

# Final plot with overall annotation
final_combined_plot <- ggdraw() +
  draw_plot(combined_plots, 0, 0, 1, 1) +
  draw_label("Burn Severity Analysis", x = 0.5, y = 1, hjust = 0.5, size = 16, fontface = "bold")

# Print the final combined plot
print(final_combined_plot)
