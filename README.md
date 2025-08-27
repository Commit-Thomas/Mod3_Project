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
