# 🎢 Mod3 Project: Theme Park Guest Analytics  
**By**: *Thomas Segal*

---

## 🧠 Business Problem

The Supernova Theme Park wants to better understand guest behavior to improve satisfaction and maximize revenue. Management suspects long wait times, unclear ticket value, and inconsistent spending patterns are impacting both the guest experience and profit. Data-driven insights are needed to guide staffing, ticketing, and marketing strategies.

---

## 👥 Stakeholders

- **General Manager** — needs staffing and scheduling insights to improve efficiency  
- **Operations Director** — focused on managing ride wait times and satisfaction  
- **Marketing Director** — interested in pricing, ticket switching behavior, and top spenders  

---

## 🗂️ Overview of Database & Schema

The database follows a **star schema** for optimized querying and scalability. Central fact tables log events (visits, rides, purchases), while dimension tables provide guest, ticket, attraction, and calendar context.

**Key Tables:**

- `dim_guest`, `dim_ticket`, `dim_attraction`, `dim_date`  
- `fact_visits`, `fact_ride_events`, `fact_purchases`

---

## 🔍 EDA (SQL)  
➡️ [`sql/01_eda.sql`](sql/01_eda.sql)

- **Visit Trends**: Monday had the highest number of visits; Sunday had the highest spend.  
- **Wait Times & Satisfaction**: Longer waits generally correlated with lower satisfaction.  
- **Data Quality**: Found and removed ~10 duplicate ride events; some nulls in satisfaction data.

> *Snippet: Checking duplicate ride logs*
```sql
SELECT attraction_id, ride_time, wait_minutes, satisfaction_rating, COUNT(*) 
FROM fact_ride_events
GROUP BY 1, 2, 3, 4
HAVING COUNT(*) > 1;
``` 


| Feature            | Description                           | Purpose                            |
| ------------------ | ------------------------------------- | ---------------------------------- |
| `stay_hours`       | Visit duration in hours               | Helps Ops monitor guest engagement |
| `wait_bucket`      | Wait time category (0-30, 30-60, 60+) | Useful for satisfaction analysis   |
| `spend_dollars`    | Cleaned spend in dollars              | Enables monetary comparisons       |


## 🪜 CTEs & Window Functions (SQL)
➡️ sql/04_ctes_windows.sql
Guest Lifetime Value by State
Ranked top spenders per home state using window function:
```RANK() OVER (
  PARTITION BY home_state
  ORDER BY total_spent DESC
) AS rank_in_state
```
## Spend Behavior Changes Over Time
Used LAG() to compare visit-to-visit spend:
```LAG(fv.spend_dollars) OVER (
  PARTITION BY guest_id
  ORDER BY dd.day_name
) AS previous_spend
```

40.7% of guests increased spend on their next visit
55.6% decreased
3.7% spent the same

## 📊 Visuals (Python)

### 1. Daily Spend by Ticket Type
<img width="1165" height="678" alt="25c4716e-e1d7-4a82-9f19-a9a30c7454bd" src="https://github.com/user-attachments/assets/4bbcb829-4f4f-44bb-817b-60bd6e8c0138" />

Guests spend most on Sundays and Mondays, suggesting higher demand during those days.

### 2. Average Wait Time by Day of Week
<img width="687" height="468" alt="57e35b14-2342-4d7e-94cd-521d555cceba" src="https://github.com/user-attachments/assets/42b6035a-4f30-4225-a5bc-68ab244cf0f0" />

High-value guests are concentrated in California and Florida, making them ideal for targeted marketing.

### 3. CLV Distribution by Home State
<img width="1005" height="555" alt="2203df19-5338-459c-874a-d260c204f6bd" src="https://github.com/user-attachments/assets/e87ce0f0-41c8-4ec8-99ac-ae4a4024700f" />

Most guests switched ticket types at least once, often to VIP or Family Pack options, suggesting opportunity for upselling.



---
## 💡 Insights & Recommendations

- 🎯 For the General Manager:
Increase staffing on Mondays, which are busiest for both visits and party sizes.
Extend hours or offer incentives to increase average stay duration and spend.
- ⚙️ For Operations:
Monitor long wait times (>60 min) — they lower satisfaction.
Add fast pass or digital queueing for high-demand rides.
- 📈 For Marketing:
Geo-targeted loyalty campaigns for top spenders by state.
Promote flexible ticket bundles, especially to guests switching tiers.
Track guests who increased spend — target for upsells or memberships.

---

## ⚖️ Ethics & Bias
- Small Dataset: Only 10 guest_ids
- Missing Data: Some satisfaction and wait times are null.
- Time Range: Only 8 days of data trends are short-term and should be re-validated over time.
- Only revenue data available; costs and margins not included.

---

## 📁 Repo Navigation
```
/sql        → SQL scripts: EDA, Features, CTEs & Windows  
/notebooks  → Python notebooks for data viz  
/figures    → Saved chart images for embedding  
/data       → Source SQLite database  
README.md   → This file
```
