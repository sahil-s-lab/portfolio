# National Sales Performance Dashboard

This project analyzes the sales funnel performance across all B2B teams, including Field Sales, National Inside Sales, and Channel Partners. It draws from Oracle-based sales data to monitor pipeline health and identify potential bottlenecks in opportunity conversion.

---

## 📊 Objective

To provide executive and regional sales leadership with a real-time view of:
- Total pipeline volume by stage
- Opportunity velocity and aging
- Conversion funnel trends across all teams

This dashboard enabled data-driven forecasting and territory optimization.

---

## 🛠️ Tools & Technologies

| Tool          | Purpose                                      |
|---------------|-----------------------------------------------|
| Oracle SQL    | Data extraction from ERP-backed sales systems |
| Excel         | Funnel dashboard for executive stakeholders   |

---

## 🧾 SQL Logic Overview

- Pulled opportunity and deal data directly from Oracle-based tables
- Filtered by team type (Field, NIS, Partner, etc.)
- Grouped by stage and sales region
- Included metrics for stage aging, drop-off rates, and conversion timing

📂 View the full SQL scripts here: [`SQL/`](./SQL/)

> 📌 *Note: Files were unzipped from `SQL.zip` and organized into this folder.*

---

## 📈 Sample Output

<p align="center">
  <img src="https://i.imgur.com/uFGQkFE.png" alt="Funnel Health Dashboard" width="1000"/>
</p>

---

## 🧠 Key Insights

- Some regions had significant pipeline aging in early stages (e.g., prospecting, discovery)
- Funnel drop-off was most common between proposal and negotiation stages
- Teams with consistent stage conversion velocity correlated with higher closed-won rates
- Executives used this dashboard to assess quarterly revenue pipeline health

---

## 🔒 Disclaimer

Data shown here is anonymized and synthetic for demonstration purposes. No confidential business information is shared.
