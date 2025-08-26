# Beyond the Park: Exploring Guest Behavior and Driving Revenue Growth

## Table of Contents
- [Business Problem](#business-problem)
- [Stakeholders](#stakeholders)
- [Overview of Database & Schema](#overview-of-database--schema)
- [EDA (SQL)](#eda-sql)
- [Feature Engineering (SQL)](#feature-engineering-sql)
- [CTEs & Window Functions (SQL)](#ctes--window-functions-sql)
- [Visuals (Python)](#visuals-python)
- [Insights & Recommendations](#insights--recommendations)
- [Ethics & Bias Considerations](#ethics--bias-considerations)
- [Repo Navigation](#repo-navigation)

---

## Business Problem

The theme park is facing inconsistencies in revenue and guest satisfaction. Management wants to understand:
- Which guests are most valuable?
- What factors affect satisfaction (e.g., wait times, ride experiences)?
- Are certain ticket types or days associated with higher spending?
- Can we reduce crowding while increasing spending?

Our goal is to uncover key patterns using SQL and Python to recommend actions that improve profitability **and** guest experience.

---

## Stakeholders

**Primary Stakeholder:**
- **General Manager**: Focused on total revenue, average guest value, and long-term satisfaction.

**Supporting Stakeholders:**
- **Marketing Director**: Wants to segment guests by value and behavior for smarter promotions.
- **Operations Lead**: Needs to understand traffic patterns and satisfaction drivers to allocate resources better.

---

## Overview of Database & Schema

The schema follows a **star design** with the following tables:

### Dimension Tables:
- `dim_guest`: guest demographics, state, opt-in status
- `dim_ticket`: ticket type info
- `dim_attraction`: ride details
- `dim_date`: calendar info (day name, weekend, season)

### Fact Tables:
- `fact_visits`: park entry/exit data, spend, ticket
- `fact_ride_events`: ride usage, wait times, satisfaction
- `fact_purchases`: food, merchandise, photo purchases

This design supports flexible analysis and performant joins. edit

---

## EDA (SQL)

### Q1: Visit Volume by Ticket Type
```sql
SELECT 
    dt.ticket_type_name, 
    COUNT(fv.visit_id) AS num_visits
FROM fact_visits fv
LEFT JOIN dim_ticket dt ON fv.ticket_type_id = dt.ticket_type_id
GROUP BY dt.ticket_type_name
ORDER BY num_visits DESC;
