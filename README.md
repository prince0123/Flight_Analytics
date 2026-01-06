# Flight_Analytics

# Crew Manpower Planning & Optimization Dashboard

## 📌 Project Overview
This project analyzes airline crew manpower utilization, roster efficiency, and standby activation to identify opportunities to reduce crew shortages without increasing headcount.

The dashboard focuses on understanding whether operational shortages are driven by insufficient manpower or inefficient crew utilization.

---

## 🎯 Business Objective
Airline operations often face crew shortages, low on-time performance (OTP), and fatigue risks despite having standby crew available.

**Key question addressed:**
> Are crew shortages caused by lack of manpower, or by inefficient rostering and standby utilization?

---

## 🗂️ Data Sources
Synthetic but realistic airline operations dataset (~50,000+ rows):

- `flight_roster_plan` – Crew duty assignments
- `flight_standby_utilization` – Standby crew usage
- `flight_flight_operations` – Planned vs actual operations
- `flight_demand_forecast` – Flight demand
- `flight_crew_master` – Crew attributes
- `flight_dim_date` – Date dimension

---

## 🧩 Data Model
- Star schema with `flight_dim_date` as the central dimension
- One-to-many relationships with fact tables
- Active date relationships for accurate time-based analysis

---

## 📊 Key KPIs

### Executive KPIs
- Crew Utilization %
- On-Time Performance (OTP %)
- Flights per Crew
- Crew Gap
- Crew Status (Shortage / Balanced / Surplus)

### Operational KPIs
- Standby Utilization %
- Average Unused Standby Crew
- Flying Duty %
- High-Risk Days

---

## 🔍 Key Insights
- Standby utilization averages ~54%, indicating under-activation.
- An average of 9 standby crew remain unused per day.
- Crew shortages persist despite available standby capacity.
- 366 high-risk days identified, increasing fatigue and compliance risk.

---

## 💡 Business Recommendations
- Improve real-time standby activation.
- Rebalance flying vs non-flying duties during peak demand.
- Use high-risk day indicators for proactive staffing adjustments.
- Optimize utilization before increasing manpower.

---

## 🛠️ Tools & Technologies
- SQL (data modeling, KPI logic)
- Power BI (data modeling, DAX, dashboards)
- DAX (time intelligence, advanced measures)

---

## ✅ Outcome
The project demonstrates how operational analytics can reduce crew shortages by improving utilization efficiency rather than increasing headcount.

---

## 📷 Dashboard Preview
<img width="1381" height="788" alt="image" src="https://github.com/user-attachments/assets/f112f2dc-f3c5-4783-8f99-774bbbf2330f" />


