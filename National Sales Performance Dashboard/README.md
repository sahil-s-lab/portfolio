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

| Tool          | Purpose                                 |
|---------------|------------------------------------------|
| PostgreSQL    | Data aggregation and transformation      |
| AWS           | Hosted PostgreSQL database               |
| Salesforce    | CRM data source (tasks, leads, opps)     |
| Excel         | KPI dashboard for business stakeholders  |

---

## 🧾 SQL Logic Overview

- Built cascading CTEs to filter active campaigns and join members to task/opportunity data
- Tracked first RPC timing and call attempts by matching task creation to member assignment dates
- Pivoted lead dispositions and opportunity stages with MRR breakdowns by product line

📂 View the full SQL script here: [`campaign_reporting.sql`](./campaign_reporting.sql)

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
