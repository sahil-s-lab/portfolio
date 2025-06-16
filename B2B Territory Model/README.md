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
| Power BI      | Geographic visualization and territory mapping |
| Kettle Pentaho| ETL pipeline for martech integration     |
| Salesforce    | CRM data source and lead management      |

---

## 🏗️ Data Pipeline Architecture

```
Footprint Data (External Team) 
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
- Capacity constraints preventing overallocation (max 250 total, 30 new, 55% in-progress ratio)

*Campaign Reporting System*
- Multi-channel attribution tracking leads through opportunity lifecycle
- Performance metrics including RPC (Right Party Contact) analysis
- Revenue attribution across wireless/wireline product categories
- Stage duration tracking for opportunity pipeline health

📂 View the full scripts: [`auto_top_up_v3.sql`](./auto_top_up_v3.sql) | [`campaign_reporting.sql`](./campaign_reporting.sql)

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

**SQL-Based Smart Allocation** (`auto_top_up_v3.sql`):
- **Recursive CTEs** to identify target campaigns and available rep capacity
- **Dynamic lead allocation** based on performance metrics and territory assignments
- **Capacity constraints** preventing overallocation across territories

**Campaign Performance Tracking** (`campaign_reporting.sql`):
- **Multi-channel attribution** tracking leads through opportunity lifecycle
- **Territory-based performance metrics** including contact rates and conversion
- **Revenue attribution** across product categories by geographic region

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

**Territory Optimization:**
- Geographic segmentation revealed coverage gaps and over-concentration areas
- Power BI visualizations enabled strategic territory boundary adjustments
- Market opportunity sizing supported resource allocation decisions

**Operational Efficiency:**
- Automated lead distribution prevented rep overload and improved conversion rates
- Smart capacity management based on individual and territory performance metrics
- Streamlined campaign execution through integrated martech pipeline

**Strategic Planning:**
- Territory model directly informed go-to-market strategy for new cable products
- Headcount impact analysis supported data-driven expansion decisions  
- Cross-product opportunity tracking enabled better bundling strategies across territories

**Measurable Results:**
- Contributed to B2B penetration rate growth over 12-month period
- Improved lead-to-opportunity conversion through optimized territory assignments
- Enhanced strategic decision-making through predictive modeling capabilities

---

## 🔒 Disclaimer

Data shown here is anonymized and synthetic for demonstration purposes. No confidential business information is shared.
