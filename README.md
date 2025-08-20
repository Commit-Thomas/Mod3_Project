# Mod3_Project
# Supernova Theme Park Analysis | by [Your Name]

## 📌 Business Problem
[Short summary]

## 👥 Stakeholders
[List]

## 🗃️ Overview of Database & Schema
- [Short schema explanation]
- [List of tables and their purpose]

## 🔍 EDA (SQL)
- [3 main findings from 01_eda.sql]

## 🛠️ Feature Engineering (SQL)
- [List of 4 features and why they matter]

## 📊 CTEs & Window Functions (SQL)
- [Summarize daily trends, CLV, behavior, ticket switching]

## 📈 Visuals (Python)
- ![daily_attendance](figures/daily_attendance.png)
  *Line chart showing park peak traffic days.*
- ![wait_satisfaction](figures/wait_vs_satisfaction.png)
  *Bar chart of wait vs. satisfaction by ride category.*
- ![clv_distribution](figures/clv_distribution.png)
  *Boxplot of CLV by ticket type.*

## 💡 Insights & Recommendations
- GM: Focus high-CLV guests with loyalty offers
- Ops: Add staff on peak weekends, manage high-wait rides
- Marketing: Optimize promos that boost spend, not just attendance

## ⚖️ Ethics & Bias
- Data quality issues: spend formatting, some nulls
- Margin not modeled (revenue only)
- Time window limited (8 days)
- Photo_purchase may be underreported

## 🗺️ Repo Navigation
- `/sql`: all SQL scripts
- `/notebooks`: Python analysis
- `/figures`: plots for README
- `/data`: raw DB
