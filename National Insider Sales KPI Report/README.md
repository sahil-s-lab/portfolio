# National Inside Sales KPI Dashboard

This project delivers a daily call activity snapshot for the B2B National Inside Sales (NIS) team. Using Salesforce task and opportunity data processed in PostgreSQL and visualized in Excel, this dashboard provided sales managers with timely visibility into individual and team-level performance.

---

## 📊 Objective

To keep the inside sales team accountable by tracking:
- Daily number of calls made
- Breakdown of call types (base, prospecting, follow-ups, proposals)
- Volume of new opportunities created

The report was generated automatically each morning and distributed to regional sales managers.

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

- Aggregated call-type metrics (base, RPC, prospecting, follow-up)
- Separated new opportunity creation by region and rep
- Used `UNION ALL` to blend task and opportunity data for one unified dataset
- Filtered by relevant sales channels only (Lake Shore, Small - NIS, Field Sales)

📂 View the full script here: [`Direct Channels KPI Report .sql`](./Direct%20Channels%20KPI%20Report%20.sql)

---

## 📈 Sample Output

<p align="center">
  <img src="https://i.imgur.com/vQZu8pM.png" alt="NIS KPI Dashboard" width="1000"/>
</p>

---

## 🧠 Key Insights

- Base and prospecting calls made up the majority of logged activities
- Proposal and follow-up calls were common among top performers
- Managers used this dashboard to conduct daily huddles and monitor real-time activity volumes
- Opportunity creation trends varied significantly across regions, offering insight into pipeline health

---

## 🔒 Disclaimer

Data shown here is **anonymized** and **synthetic** for demonstration purposes. No confidential business information is shared.

