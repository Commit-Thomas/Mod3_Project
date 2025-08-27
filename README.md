# 🎢 Mod3 Project: Theme Park Guest Analytics  
**Owner**: *Your Name Here*

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
| `spend_per_person` | Spend ÷ party size                    | Helps identify high-value parties  |


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
40.7% of guests increased spend on their next visit
55.6% decreased
3.7% spent the same
```
## 📊 Visuals (Python)

### 1. Spending by Day of the Week
![Daily Spend by Ticket Type](figures/daily_spend_by_ticket_type.png)
Guests spend most on Sundays and Mondays, suggesting higher demand during those days.

### 2. Top Guests by State
![Top Guests](figures/top_guests_by_state.png)
High-value guests are concentrated in California and Florida, making them ideal for targeted marketing.

### 3. Ticket Type Switching
![Ticket Type Switching](figures/ticket_type_switching.png)
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
Missing Data: Some satisfaction and wait times are null — especially low-volume days.
Data Cleaning: Removed ~10 exact duplicates in ride events; spend converted from cents to dollars.
Time Range: Only 8 days of data — trends are short-term and should be re-validated over time.
Profit Not Modeled: Only revenue data available; costs and margins not included.

---

## 📁 Repo Navigation
```
/sql        → SQL scripts: EDA, Features, CTEs & Windows  
/notebooks  → Python notebooks for data viz  
/figures    → Saved chart images for embedding  
/data       → Source SQLite database  
README.md   → This file
```
