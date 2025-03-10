# Random Forest Training and Evaluation Script

# Load necessary packages
library(caret)
library(ranger)

# Split data into training (70%) and testing (30%) sets
set.seed(42)  # For reproducibility
train_index <- createDataPartition(points_cleaned$severity, p = 0.7, list = FALSE)
train_data <- points_cleaned[train_index, ]
test_data <- points_cleaned[-train_index, ]

# Rename class levels in `severity`
train_data$severity <- factor(train_data$severity,
                              levels = c(3, 4, 5, 6),
                              labels = c("Class3", "Class4", "Class5", "Class6"))
test_data$severity <- factor(test_data$severity,
                             levels = c(3, 4, 5, 6),
                             labels = c("Class3", "Class4", "Class5", "Class6"))

# Define tuning grid and train control
tuneGrid <- expand.grid(
  mtry = c(2, 4, 6),
  splitrule = c("gini", "extratrees"),
  min.node.size = c(1, 3, 5)
)

control <- trainControl(
  method = "cv",
  number = 10,
  classProbs = TRUE  # Enable probability predictions
)

# Train the Ranger Model
set.seed(42)
rf_model <- train(
  severity ~ .,
  data = train_data,
  method = "ranger",
  trControl = control,
  tuneGrid = tuneGrid,
  importance = "impurity"
)

# Output model summary
print(rf_model)

# Save the trained model
saveRDS(rf_model, file = "Analysis/BurnSeverity/fire_analysis_results/ML_Works/final_rf_model.rds")

# Predict on test data
predictions <- predict(rf_model, newdata = test_data)

# Evaluate using confusion matrix
conf_matrix <- confusionMatrix(predictions, test_data$severity)
print(conf_matrix)
