-- Prompt 1: Daily Attendance and Spend Performance with Running Totals

WITH daily AS (
  -- Aggregate daily visits and total spending
  SELECT
    d.date_iso,
    d.day_name,
    d.is_weekend,
    COUNT(DISTINCT v.visit_id) AS daily_visits,
    SUM(v.spend_cents_clean) AS daily_spend
  FROM fact_visits v
  INNER JOIN dim_date d ON v.date_id = d.date_id
  WHERE v.spend_cents_clean IS NOT NULL
  GROUP BY d.date_iso, d.day_name, d.is_weekend
),

daily_with_running AS (
  -- Add running totals and visit rank
  SELECT *,
    SUM(daily_visits) OVER (ORDER BY date_iso) AS running_total_visits,
    SUM(daily_spend) OVER (ORDER BY date_iso) AS running_total_spend,
    RANK() OVER (ORDER BY daily_visits DESC) AS visit_rank
  FROM daily
)

-- Select top 3 days by visit count
SELECT *
FROM daily_with_running
WHERE visit_rank <= 3;



-- Prompt 2: RFM & CLV Analysis

WITH guest_summary AS (
  -- Summarize total spend, most recent visit, and total visits per guest
  SELECT
    dg.guest_id,
    dg.first_name || ' ' || dg.last_name AS full_name,
    dg.home_state,
    ROUND(SUM(fv.spend_dollars), 2) AS total_spent,
    MAX(dd.date_id) AS most_recent_visit,
    COUNT(fv.visit_id) AS total_visits
  FROM dim_guest dg
  INNER JOIN fact_visits fv ON dg.guest_id = fv.guest_id
  INNER JOIN dim_date dd ON fv.date_id = dd.date_id
  WHERE fv.spend_dollars IS NOT NULL
  GROUP BY dg.guest_id, dg.first_name, dg.last_name, dg.home_state
),

ranked_guests AS (
  -- Rank guests by spend within each home state
  SELECT 
    *,
    RANK() OVER (
      PARTITION BY home_state
      ORDER BY total_spent DESC
    ) AS rank_in_state
  FROM guest_summary
)

-- Final RFM output, ordered by state and rank
SELECT *
FROM ranked_guests
ORDER BY home_state, rank_in_state;



-- Prompt 3: Spending Behavior Change Using LAG()

WITH spend_comparison AS (
  -- Capture each guest's current and previous visit spend
  SELECT
    fv.visit_id,
    dg.guest_id,
    dd.day_name AS visit_day,
    fv.spend_dollars,
    LAG(fv.spend_dollars) OVER (
      PARTITION BY dg.guest_id
      ORDER BY dd.day_name
    ) AS previous_spend
  FROM fact_visits fv
  INNER JOIN dim_guest dg ON fv.guest_id = dg.guest_id
  INNER JOIN dim_date dd ON fv.date_id = dd.date_id
  WHERE fv.spend_dollars IS NOT NULL
),

spend_changes AS (
  -- Compute difference in spend from prior visit
  SELECT
    guest_id,
    visit_id,
    visit_day,
    spend_dollars,
    previous_spend,
    (spend_dollars - previous_spend) AS spend_diff
  FROM spend_comparison
  WHERE previous_spend IS NOT NULL
)

-- Summarize percentage of guests who spent more, less, or the same
SELECT
  ROUND(100.0 * SUM(CASE WHEN spend_diff > 0 THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS percentage_increased,
  ROUND(100.0 * SUM(CASE WHEN spend_diff < 0 THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS percentage_decreased,
  ROUND(100.0 * SUM(CASE WHEN spend_diff = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS percentage_unchanged
FROM spend_changes;



-- Prompt 4: Detecting Ticket Type Switching Behavior

WITH guest_tickets AS (
  -- For each visit, get the current and first ticket type per guest
  SELECT
    v.guest_id,
    v.visit_date,
    t.ticket_type_name AS current_ticket_type,
    FIRST_VALUE(t.ticket_type_name) OVER (
      PARTITION BY v.guest_id
      ORDER BY v.visit_date
    ) AS first_ticket_type
  FROM fact_visits v
  INNER JOIN dim_ticket t ON v.ticket_type_id = t.ticket_type_id
),

ticket_switch_flag AS (
  -- Flag whether the ticket type has changed from the first one
  SELECT *,
    CASE 
      WHEN current_ticket_type != first_ticket_type THEN 1 
      ELSE 0 
    END AS switched
  FROM guest_tickets
)

-- Show only guests who switched ticket types
SELECT
  guest_id,
  first_ticket_type,
  current_ticket_type,
  switched
FROM ticket_switch_flag
WHERE switched = 1;

-- Capstone CTE/Windows

-- Ranking best-selling items and converting cents to dollars for readability 
SELECT 
    item_name,
    COUNT(*) AS total_units,
    SUM(amount_cents_clean) / 100.0 AS total_revenue_dollars,
    RANK() OVER (ORDER BY SUM(amount_cents_clean) DESC) AS revenue_rank
FROM fact_purchases
WHERE amount_cents_clean IS NOT NULL
GROUP BY item_name
ORDER BY revenue_rank;

-- Frequency of ridership for each ride

WITH daily_ride_counts AS (
    SELECT
        dd.date_iso,
        da.attraction_name,
        da.category,
        COUNT(fre.ride_event_id) AS rides_that_day
    FROM fact_ride_events fre
    JOIN dim_attraction da
        ON fre.attraction_id = da.attraction_id
    JOIN fact_visits fv
        ON fre.visit_id = fv.visit_id
    JOIN dim_date dd
        ON fv.date_id = dd.date_id
    GROUP BY dd.date_iso, da.attraction_name, da.category
)

SELECT
    attraction_name,
    category,
    ROUND(AVG(rides_that_day), 2) AS avg_rides_per_day
FROM daily_ride_counts
GROUP BY attraction_name, category
ORDER BY avg_rides_per_day DESC;

-- Finding the percent of non-ticket spending for each ticket type to find which groups spend more

WITH purchase_spend AS (
    SELECT 
        visit_id,
        SUM(amount_cents_clean) AS purchase_cents
    FROM fact_purchases
    WHERE amount_cents_clean IS NOT NULL
    GROUP BY visit_id
),

visit_spend AS (
    SELECT 
        visit_id,
        ticket_type_id,
        spend_cents_clean AS total_cents
    FROM fact_visits
    WHERE spend_cents_clean IS NOT NULL
),

combined AS (
    SELECT 
        v.ticket_type_id,
        v.total_cents,
        COALESCE(p.purchase_cents, 0) AS purchase_cents
    FROM visit_spend v
    LEFT JOIN purchase_spend p
        ON v.visit_id = p.visit_id
)

SELECT 
    t.ticket_type_name,
    ROUND(100.0 * SUM(purchase_cents) / SUM(total_cents), 2) AS non_ticket_spend_pct
FROM combined c
JOIN dim_ticket t
    ON c.ticket_type_id = t.ticket_type_id
GROUP BY t.ticket_type_name
ORDER BY non_ticket_spend_pct DESC;

-- KPIs to track average revenue, wait time, and rides per visit
WITH visit_metrics AS (
    SELECT
        ROUND(AVG(spend_dollars), 2) AS avg_spend_per_visit,
        ROUND(AVG(stay_hours), 2) AS avg_stay_hours
    FROM fact_visits
),

wait_metrics AS (
    SELECT
        ROUND(AVG(wait_minutes), 2) AS avg_wait_time
    FROM fact_ride_events
    WHERE wait_minutes IS NOT NULL
),

ride_metrics AS (
    SELECT
        ROUND(
            CAST(COUNT(fre.ride_event_id) AS REAL) /
            COUNT(DISTINCT fv.visit_id),
            2
        ) AS avg_rides_per_visit
    FROM fact_visits fv
    LEFT JOIN fact_ride_events fre
        ON fv.visit_id = fre.visit_id
)

SELECT
    vm.avg_spend_per_visit,
    wm.avg_wait_time,
    rm.avg_rides_per_visit
FROM visit_metrics vm
CROSS JOIN wait_metrics wm
CROSS JOIN ride_metrics rm;