# 🔥 Fire_Ecology

## Supplementary Data and Analysis

This repository contains all scripts, processed datasets, and supporting visualizations used for mapping burned areas, assessing fire severity, and monitoring post-fire vegetation recovery in heterogeneous forested landscapes. The analysis leverages **Sentinel-2 imagery**, **spectral indices**, and **Random Forest modeling** within R and Google Earth Engine (GEE).

---

## 📁 Repository Structure

### 🛰️ Google Earth Engine Scripts

- `gee_index_computation.js`  
  Cloud-masked median composites and spectral index calculations (NBR, NDVI, BAIS2, CSI, VARI, MSAVI, MIRBI) from Sentinel-2.

---

### 💻 R Scripts

#### 🔹 `01_FireIndices_Processing.R`
- Loads raster stacks of monthly fire indices.
- Computes summary statistics.
- Identifies burn months using BAIS2 and NBR thresholds.

#### 🔹 `02_BurnedArea_Extraction.R`
- Calculates monthly burned area (ha and %).
- Generates bar plots (`MonthlyBurntareas.png`).

#### 🔹 `03_BurnSeverity_RF_Model.R`
- Performs stratified sampling.
- Trains Random Forest using indices (pre-, post-, differenced).
- Saves trained model as `.rds`.

#### 🔹 `04_ModelPerformance_Visualization.R`
- ROC curve visualization (per-class and multi-class).
- Outputs: `burn_severity_roc_curve.png`.

#### 🔹 `05_SHAP_Analysis_RF.R`
- SHAP-based interpretation using `iml` package.
- Produces class-wise and global SHAP plots (`Shap_plot_RF2.png`, `shap_global_feature_importance.png`).

#### 🔹 `06_Recovery_Assessment_Severity.R`
- Computes dNDVI and dKNDVI per severity class.
- Correlates burn severity (RBR/RdNBR) with vegetation recovery.
- Saves outputs as classified rasters and summary plots.

#### 🔹 `07_PercentageSeverityComparison.R`
- Plots burn severity percentages across RBR, RdNBR, dBAIS2, and dNBR.
- Output: `SeverityPercentPlots.png`.

---

## 📊 Key Output Files

| File | Description |
|------|-------------|
| `NBR_Burned_Areas.tif` | Burned areas from NBR classification |
| `FireNonFirepoints_fixed.shp` | Sampled fire/non-fire points for training |
| `final_rf_model.rds` | Trained RF model |
| `MonthlyBurntareas.png` | Monthly burned area (NBR) |
| `burn_severity_roc_curve.png` | ROC plots for each severity class |
| `Shap_plot_RF2.png` | SHAP class-wise feature contributions |
| `dNDVI.tif`, `dKNDVI.tif` | Vegetation change (pre-post) |
| `dNDVI_Recovery_byRBR.tif` | dNDVI classified by RBR severity |
| `KndviVsNdvi-RBR.png` | Correlation plot between severity and recovery |
| `SeverityPercentPlots.png` | Burn severity comparison across indices |

---

## 📐 Methodology Summary

- **Spectral Indices Used**:  
  `NBR`, `dNBR`, `BAIS2`, `dBAIS2`, `CSI`, `MIRBI`, `NDVI`, `dNDVI`, `KNDVI`, `dKNDVI`, `VARI`, `MSAVI`

- **Burn Severity Classification**:  
  `RBR`, `RdNBR`, `dBAIS2`, `dNBR`

- **Recovery Assessment**:  
  Using differenced vegetation indices (dNDVI, dKNDVI), stratified by burn severity.

- **Machine Learning Model**:  
  - **Algorithm**: Random Forest (`ranger` in `caret`)
  - **Tuning**: 10-fold cross-validation
  - **Interpretation**: SHAP values via `iml`

---

## 💾 Data Format

- Raster: `.tif` (GeoTIFF)
- Vector: `.shp` (Shapefile)
- Tabular: `.csv`
- Figures: `.png` (400 DPI)

---

## 🔄 Reproducibility

- All data pre-processing, training, evaluation, and visualization steps are script-driven.
- Scripts can be run independently with paths adjusted to your local environment.
- GEE script reproducible via Earth Engine Code Editor.

---

## 📘 Citation

If this repository or any part of the workflow supports your work, please cite the associated paper and acknowledge the authors.

---

*Maintained by [Kaleem Mehmood] [kaleemmehmood73@gmail.com]*  
_Last updated: March 2025_
