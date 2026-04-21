# 🎢 Mod3 Project: Theme Park Analysis  
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
➡️ [sql/01_eda.sql](https://github.com/Commit-Thomas/Mod3_Project/blob/main/sql/01_EDA.sql)

- **Visit Trends**: Monday had the highest average number of visits and party size.  
- **Wait Times & Satisfaction**: Surprisingly longer waits didn't have a strong correlation with lower satisfaction.  
- **Data Quality**: Found 8 duplicate ride events.
- **Ticket Switching**: All customers switched at least once.

> *Snippet: Checking duplicate ride logs*
```sql
SELECT
    attraction_id,
    visit_id,
    ride_time,
    wait_minutes,
    satisfaction_rating,
    photo_purchase,
    COUNT(*) AS dup_count
FROM fact_ride_events
GROUP BY
    attraction_id,
    visit_id,
    ride_time,
    wait_minutes,
    satisfaction_rating,
    photo_purchase
HAVING COUNT(*) > 1;
``` 


| Feature            | Description                           | Purpose                            |
| ------------------ | ------------------------------------- | ---------------------------------- |
| `stay_hours`       | Visit duration in hours               | Helps Ops monitor guest engagement |
| `wait_bucket`      | Wait time category (0-30, 30-60, 60+) | Useful for satisfaction analysis   |
| `spend_dollars`    | Cleaned spend in dollars              | Enables monetary comparisons       |


## 🪜 CTEs & Window Functions (SQL)
➡️ [sql/04_ctes_windows.sql](https://github.com/Commit-Thomas/Mod3_Project/blob/main/sql/04_CTEs_Windows.sql)


Guest Lifetime Value by State
Ranked top spenders per home state using window function:
```
RANK() OVER (
  PARTITION BY home_state
  ORDER BY total_spent DESC
) AS rank_in_state

```
## Spend Behavior Changes Over Time
Used LAG() to compare visit-to-visit spend:
```
LAG(fv.spend_dollars) OVER (
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

- Day passes are the most consistent, with revenue staying within $300–$500.
- VIP tickets have a wider range of daily spend.

### 2. Average Wait Time by Day of Week
<img width="687" height="468" alt="57e35b14-2342-4d7e-94cd-521d555cceba" src="https://github.com/user-attachments/assets/42b6035a-4f30-4225-a5bc-68ab244cf0f0" />

- Thursday has the highest average wait time, with nearly 60 minutes.
- Other days with above-average wait times show low variance, all around 48–50 minutes.

### 3. CLV Distribution by Home State
<img width="1005" height="555" alt="2203df19-5338-459c-874a-d260c204f6bd" src="https://github.com/user-attachments/assets/e87ce0f0-41c8-4ec8-99ac-ae4a4024700f" />

- Customers from California have the highest average CLV, at roughly $800, but with high variance.
- Texas has the lowest CLV, at $300.

---
## 💡 Insights & Recommendations

- 🎯 For the General Manager:
Increase staffing on Mondays, which are busiest for both visits and party sizes.
Extend hours or offer incentives to increase average stay duration and spend.
- ⚙️ For Operations:
Monitor days with longer wait times — rides may be breaking down.
Add fast pass or digital queueing for high-demand rides.
- 📈 For Marketing:
Geo-targeted loyalty campaigns for top spenders by state.
More clear communication on what each ticket offers, customers seem to have confusion.
Track guests who increased spend — target for upsells or memberships.

---

## ⚖️ Ethics & Bias
- Small Dataset: Only 10 guest_ids
- Missing Data: 10 total_spend_cents and 72 wait times are null.
- Imputation: cents/dollars imputed with $0.
- Time Range: Only 8 days of data trends are short-term and should be re-validated over time.
- Only revenue data available; costs and margins not included.

---
## 📊 Project Expansion: Data Cleaning, Analysis & Insights

- **Data Cleaning & Validation**
  - Replaced zero spend values with `NULL` to improve aggregation accuracy  
  - Built cross-table validation between `fact_visits` and `fact_purchases`  
  - Flagged and quantified spend discrepancies at the guest level  

- **Exploratory Data Analysis (EDA)**
  - Analyzed **wait times vs. guest volume** to assess congestion impact  
  - Measured **average rides per visit** to evaluate guest engagement  
  - Identified **day-of-week ride patterns** and **top attractions by usage**  

- **Advanced Analytics (CTEs & Window Functions)**
  - Ranked **top revenue-generating items** using window functions  
  - Calculated **average ride frequency per attraction (normalized by day)**  
  - Analyzed **non-ticket spend by ticket type** to uncover behavioral differences  

- **KPI Development**
  - Built core metrics:
    - Average spend per visit  
    - Average wait time  
    - Average rides per visit  
  - Designed as a foundation for dashboards and forecasting  

- **Key Takeaways**
  - Higher guest volume does **not consistently drive longer wait times**  
  - Guest behavior (rides + spend) varies meaningfully across segments  
  - Results highlight opportunities for **operational optimization and targeted marketing**
  
## 📁 Repo Navigation
```
/data       → Source SQLite database
/figures    → Saved chart images for embedding  
/notebooks  → Python notebooks for data viz   
/sql        → SQL scripts: EDA, Features, CTEs & Windows
README.md   → This file
```
