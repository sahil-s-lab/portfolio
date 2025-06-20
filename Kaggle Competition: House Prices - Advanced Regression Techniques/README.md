# House Prices – Advanced Regression Modeling

This project was developed as part of a graduate data science course and submitted to Kaggle's House Prices: Advanced Regression Techniques competition. The objective was to predict housing prices using a combination of numeric and categorical features. My final model placed in the top 16th percentile among 4,779 teams.

---

## 📊 Objective

Build a predictive regression model to estimate home prices in Ames, Iowa using 79 real estate features. Emphasis was placed on data cleaning, feature engineering, and stacked model performance optimization.

---

## 🛠️ Tools & Technologies

| Tool             | Purpose                                        |
|------------------|------------------------------------------------|
| Python           | Programming language                           |
| scikit-learn     | Model building, preprocessing, and evaluation  |
| XGBoost          | Gradient boosting model                        |
| Pandas, NumPy    | Data manipulation and exploration              |
| Matplotlib, Seaborn | Visualization tools                        |
| Kaggle           | Competition platform and dataset source        |
| VS Code          | Integrated development environment (IDE)       |

---

## 🧾 Modeling Workflow Overview

- **EDA**: Explored skewness, outliers, and feature correlations
- **Data Cleaning**:
  - Dropped columns with >47% missing values
  - Filled NaNs using column-wise mode or mean
  - Applied domain-specific logic for missing basement/garage data
- **Feature Engineering**:
  - Created features like `TotalSF`, `BuildingAge`, and `TotalQual`
  - Applied an overfit reduction function for low-variance columns
- **Modeling**:
  - Built a stacked model using `LinearRegression` (required) and `XGBRegressor`
  - Encoded categorical features and scaled numeric ones via `ColumnTransformer`
  - Applied log transformation to stabilize target variable distribution
- **Validation**:
  - Cross-validated model performance
  - Tuned hyperparameters for XGBoost with grid search
- **Reproducibility**:
  - All preprocessing steps are handled via pipeline objects
  - File paths are platform-independent
  - Repo includes train, test, and prediction CSVs for replication

📂 View the full notebook here: [`House_Prices_Advanced_Regression_Techniques_Stacked_16th_percentile.ipynb`](./House_Prices_Advanced_Regression_Techniques_Stacked_16th_percentile.ipynb)

---

## 📈 Sample Output

<p align="center">
  <img src="https://i.imgur.com/mWbSq7k.png" alt="EDA Correlation Matrix" width="700"/>
</p>

<p align="center">
  <img src="https://i.imgur.com/UG6OvWE.png" alt="Modeling Pipeline" width="700"/>
</p>

---

## 🧠 Key Insights

- Most predictive features included `GrLivArea`, `TotalSF`, and `OverallQual`
- Log-transforming the target variable improved accuracy and reduced skew
- Pipeline structure ensured consistent preprocessing and reproducible results

---

## 🏅 Competition Performance

| Metric         | Value                  |
|----------------|------------------------|
| Kaggle Score   | 0.12803 RMSE           |
| Rank           | 771 out of 4,779       |
| Percentile     | Top 16%                |

---

## 🔒 Disclaimer

This project is for academic and portfolio purposes only. All data used is public and anonymized, sourced from Kaggle’s open dataset.
