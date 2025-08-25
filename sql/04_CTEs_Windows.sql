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