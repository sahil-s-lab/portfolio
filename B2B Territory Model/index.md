# B2B Territory Model
This project developed a comprehensive territory-based sales coverage plan for B2B telecommunications services, combining market segmentation analysis with automated lead distribution to optimize sales team performance and market penetration.

---

## 📊 Objective

To maximize B2B market penetration in the Ontario region by:
- Analyzing territorial coverage and market opportunity sizing
- Implementing data-driven sales territory segmentation 
- Automating lead distribution based on territory assignments and rep capacity
- Supporting go-to-market strategy for new product launches through predictive modeling

The system contributed to measurable growth in B2B penetration rates over a 12-month period.

---

## 🛠️ Tools & Technologies

| Tool          | Purpose                                 |
|---------------|------------------------------------------|
| PostgreSQL    | Territory analysis and lead distribution logic |
| AWS           | Hosted PostgreSQL database               |
| Power Query   | Geographic segmentation and territory creation |
| Power BI      | Geographic visualization and territory mapping |
| Kettle Pentaho| ETL pipeline for martech integration     |
| Salesforce    | CRM data source and lead management      |

---

## 🏗️ Data Pipeline Architecture

```
Footprint Data (External Team) 
    ↓
Power Query (Territory Segmentation)
    ↓
Power BI (Territory Visualization)
    ↓  
PostgreSQL (Lead Distribution Logic)
    ↓
Kettle Pentaho (ETL Processing)
    ↓
Martech Tools (Campaign Execution)
```

---

## 🧾 SQL Logic Overview

*Auto Top-Up System*
- Recursive CTEs to identify target campaigns and available capacity
- Dynamic lead allocation based on rep performance metrics (activity ratios, pipeline health)
- Territory matching using postal code assignments
- Capacity constraints preventing overallocation (max 250 total, 40 new, 55% in-progress ratio)

📂 View the full script here: <a href="./auto_top_up_v3.sql" download>auto_top_up_v3.sql</a> 

---

## 📈 Core Territory Visualization

### Geographic Coverage & Market Opportunity
<p align="center">
  <img src="https://i.imgur.com/H9iEFB5.png" alt="Territory Analytics Dashboard" width="1000"/>
  <br><em>Territory performance dashboard displaying market opportunity sizing and sales team allocation</em>
</p>

<p align="center">
  <img src="https://i.imgur.com/KK6XZb9.jpeg" alt="Territory Coverage Map" width="1000"/>
  <br><em>Power BI visualization showing territorial coverage with manager assignments and market penetration analysis</em>
</p>

---

## 🔄 Automated Lead Distribution System

This system automates lead delivery by aligning incoming prospects to the correct sales rep based on pre-defined territory boundaries and rep capacity rules.

- Territory matching: Each lead is assigned using postal code logic tied to territory definitions
- Rep capacity checks: Allocation respects thresholds to avoid overloading (max lead count, new lead limits, pipeline balance)
- Performance-based allocation: Leads are prioritized to reps with higher contact success and balanced pipelines
- SQL logic-driven: Entire process powered by recursive CTEs and dynamic queries in PostgreSQL (`auto_top_up_v3.sql`)

This ensures fair, efficient, and strategic lead distribution, enhancing conversion potential across all sales regions.

---

## 📊 Strategic Business Applications

The territory model enabled data-driven strategic planning across multiple initiatives:

### New Product Launch Analysis
<p align="center">
  <img src="https://i.imgur.com/UIQSDux.png" alt="Cable Ramp Analysis" width="1000"/>
  <br><em>Territory-informed cable product ramp analysis supporting go-to-market strategy development</em>
</p>

### Resource Allocation Planning
<p align="center">
  <img src="https://i.imgur.com/XF9Zdkf.png" alt="Headcount Impact Analysis" width="1000"/>
  <br><em>Headcount impact analysis using territory performance data to optimize sales team expansion</em>
</p>

---

## 🧠 Key Insights & Business Impact

- Geographic segmentation identified under-served markets and optimized sales coverage  
- Automated lead distribution improved conversion by aligning leads with rep capacity and performance  
- Insights from the model supported new product launches and strategic headcount planning  
- The initiative contributed to measurable gains in B2B penetration over 12 months  

---

## 🔒 Disclaimer

Data shown here is anonymized and synthetic for demonstration purposes. No confidential business information is shared.
