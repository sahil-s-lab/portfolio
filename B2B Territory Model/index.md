# B2B Territory Model
This project developed a comprehensive territory-based sales coverage plan for B2B telecommunications services, combining market segmentation analysis with automated lead distribution to optimize sales team performance and market penetration.

---

## 📊 Objective

To maximize B2B market penetration in the Ontario region by:
- Analyzing territorial coverage and market opportunity sizing
- Implementing data-driven sales territory segmentation 
- Automating lead distribution based on territory assignments and rep capacity
- Supporting go-to-market strategy for new product launches through predictive modeling

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

## 🧾 Territory Design Methodology

The territory framework was built through a multi-layered segmentation approach that balanced geographic coverage with commercial opportunity:

**1️⃣ Data Structuring**  
Customer records were organized by postal code (FSA prefix grouping), revenue bands using quantile segmentation to ensure even distribution of high-value accounts, NAICS industry classification for vertical specialization, and lifecycle stage to support targeted outreach strategies

**2️⃣ Territory Assignment Logic**  
Territories were defined using geographic hierarchy starting at the regional level and drilling down to Forward Sortation Area boundaries. This approach matched how field reps naturally covered their regions while ensuring complete market coverage with zero overlap between channels

**3️⃣ Scenario Testing & Validation**  
Multiple segmentation scenarios were developed and evaluated across three dimensions: total account volume per rep to balance workload, total revenue potential per territory to prevent unfair weighting, and whitespace coverage analysis to eliminate gaps in serviceable markets

**4️⃣ ETL Pipeline & Automation**  
A Kettle Pentaho pipeline was engineered to apply territory transformations and load results into both PostgreSQL (for operational queries) and Salesforce

**5️⃣ Delivery & Maintenance**  
The final model was delivered as an interactive Power BI dashboard with geospatial mapping capabilities, supported by an automated refresh process that pulled from enterprise data sources at defined intervals to maintain data accuracy as customer records evolved

---

## 📈 Business Impact 

### Geographic Coverage & Territory Visualization
<p align="center">
  <img src="https://i.imgur.com/H9iEFB5.png" alt="Territory Analytics Dashboard" width="1000"/>
  <br><em>Territory performance dashboard displaying market opportunity sizing and sales team allocation</em>
</p>

<p align="center">
  <img src="https://i.imgur.com/KK6XZb9.jpeg" alt="Territory Coverage Map" width="1000"/>
  <br><em>Power BI visualization showing territorial coverage with manager assignments and market penetration analysis</em>
</p>

### Automated Lead Distribution System

This system automates lead delivery by aligning incoming prospects to the correct sales rep based on upstream defined territory boundaries and rep capacity rules. This ensures fair, efficient, and strategic lead distribution, enhancing conversion potential across all sales regions.

*SQL Logic Overview*
- Identified active campaigns with reserved members and calculated capacity per rep (40 minus current "New" status count)
- Applied eligibility filters: total workload under 250, new leads under 30, in-progress ratio below 55%
- Used recursive CTE to expand each rep's capacity into individual rows, then matched sequentially to reserved members for automated assignment

📂 View the full script here: <a href="./auto_top_up_v3.sql" download>auto_top_up_v3.sql</a> 

### Strategic Business Applications

The territory model enabled data-driven strategic planning across multiple initiatives:

**New Product Launch Analysis**
<p align="center">
  <img src="https://i.imgur.com/UIQSDux.png" alt="Cable Ramp Analysis" width="1000"/>
  <br><em>Territory-informed cable product ramp analysis supporting go-to-market strategy development</em>
</p>

**Resource Allocation Planning**
<p align="center">
  <img src="https://i.imgur.com/XF9Zdkf.png" alt="Headcount Impact Analysis" width="1000"/>
  <br><em>Headcount impact analysis using territory performance data to optimize sales team expansion</em>
</p>

---

## 🧠 Key Insights

- Geographic segmentation identified under-served markets and optimized sales coverage  
- Automated lead distribution improved conversion by aligning leads with rep capacity and performance  
- Insights from the model supported new product launches and strategic headcount planning  
- The initiative contributed to measurable gains in B2B penetration over 12 months  

---

## 🔒 Disclaimer

Data shown here is anonymized and synthetic for demonstration purposes. No confidential business information is shared.
