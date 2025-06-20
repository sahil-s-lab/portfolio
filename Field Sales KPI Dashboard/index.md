# Field Sales KPI Analysis

This project analyzes field sales activity performance using Salesforce task and opportunity data, PostgreSQL data manipulation, and Excel-based dashboarding.

---

## 📊 Objective

To evaluate the effectiveness and coverage of Field Sales Representatives by tracking their activities (door knocks, meetings, emails, etc.) against their assigned territories, and to highlight new opportunity generation across regions. The report was generated automatically each morning and distributed to regional sales managers.

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

- CTEs used to:
  - Match task postal codes to assigned territories
  - Filter and classify task types
  - Separate "In Territory", "Foreign Territory", and "Unassigned"
- Aggregations summarize by activity type and sales rep

📂 View the full script here: <a href="./Field_Activity_Query_v1.2.sql" download>Field_Activity_Query_v1.2.sql</a><br>

---

## 📈 Sample Output

<p align="center">
  <img src="https://i.imgur.com/SaJbWvn.png" alt="Excel Dashboard" width="1000"/>
</p>

---

## 🧠 Key Insights

- Field reps operating outside assigned territories were flagged
- "Door Knock" and "Face-to-Face" meetings were leading activity types among top performers
- Some regions consistently underperformed on opportunity creation, suggesting a mismatch in territory coverage

---

## 🔒 Disclaimer

Data shown here is anonymized and synthetic for demonstration purposes. No confidential business information is shared.


