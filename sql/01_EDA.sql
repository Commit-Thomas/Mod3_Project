-- 1) Create dim_date
CREATE TABLE IF NOT EXISTS dim_date (
date_id INTEGER PRIMARY KEY, -- e.g., 20250701
date_iso TEXT NOT NULL, -- 'YYYY-MM-DD'
day_name TEXT, -- 'Monday', ...
is_weekend INTEGER, -- 0/1
season TEXT -- e.g., 'Summer'
);
-- 2) Insert rows (these match the data in themepark.db)
INSERT OR IGNORE INTO dim_date (date_id, date_iso, day_name, is_weekend, season)
VALUES
(20250701, '2025-07-01', 'Tuesday', 0, 'Summer'),
(20250702, '2025-07-02', 'Wednesday', 0, 'Summer'),
(20250703, '2025-07-03', 'Thursday', 0, 'Summer'),
(20250704, '2025-07-04', 'Friday', 0, 'Summer'),
(20250705, '2025-07-05', 'Saturday', 1, 'Summer'),
(20250706, '2025-07-06', 'Sunday', 1, 'Summer'),
(20250707, '2025-07-07', 'Monday', 0, 'Summer'),
(20250708, '2025-07-08', 'Tuesday', 0, 'Summer');
-- 3) “Wire” fact_visits to dim_date:
-- Convert visit_date ('YYYY-MM-DD') -> date_id (YYYYMMDD as an integer) and store it.
UPDATE fact_visits
SET date_id = CAST(STRFTIME('%Y%m%d', visit_date) AS INTEGER);
-- 4) (Nice-to-have) Index the column you’ll use in joins for speed:
CREATE INDEX IF NOT EXISTS idx_fact_visits_date_id ON fact_visits(date_id);
-- 5) Quick check: Are there any visits that don’t match a dim_date row? Should be ZERO.
SELECT COUNT(*) AS visits_without_date
FROM fact_visits v
LEFT JOIN dim_date d ON d.date_id = v.date_id
WHERE d.date_id IS NULL;
-- 6) Sanity check join: Daily visit counts using the “wired” key
SELECT d.date_iso, d.day_name, d.is_weekend, COUNT(DISTINCT v.visit_id) AS
daily_visits
FROM dim_date d
LEFT JOIN fact_visits v ON v.date_id = d.date_id
GROUP BY d.date_iso, d.day_name, d.is_weekend
ORDER BY d.date_iso;

-- Q0: Row counts per table
SELECT 'dim_guest' AS table_name, COUNT(*) AS n FROM dim_guest
UNION ALL SELECT 'dim_ticket', COUNT(*) FROM dim_ticket
UNION ALL SELECT 'dim_attraction', COUNT(*) FROM dim_attraction
UNION ALL SELECT 'fact_visits', COUNT(*) FROM fact_visits
UNION ALL SELECT 'fact_ride_events', COUNT(*) FROM fact_ride_events
UNION ALL SELECT 'fact_purchases', COUNT(*) FROM fact_purchases;
--------------
-- Q1: Explore Visit Dates in fact_visits

-- Part 1: Get the earliest and latest visit_date (date range)
SELECT 
    MIN(visit_date) AS earliest_date,
    MAX(visit_date) AS latest_date
FROM fact_visits;

-- Part 2: Count the number of unique visit dates
SELECT 
    COUNT(DISTINCT visit_date) AS num_unique_dates
FROM fact_visits;

-- Part 3: Count of visits per date, ordered chronologically
SELECT 
    visit_date,
    COUNT(*) AS visits_per_day
FROM fact_visits
GROUP BY visit_date
ORDER BY visit_date ASC;


-- Q2: Number of Visits by Ticket Type
SELECT 
    dt.ticket_type_name, 
    COUNT(fv.visit_id) AS num_visits
FROM fact_visits fv
LEFT JOIN dim_ticket dt 
    ON dt.ticket_type_id = fv.ticket_type_id
GROUP BY dt.ticket_type_name
ORDER BY num_visits DESC;


-- Q3: Distribution of wait_minutes in fact_ride_events

-- Part 1: Bucket wait times into categories and count them
SELECT 
    CASE 
        WHEN wait_minutes BETWEEN 0 AND 30 THEN 'Short'
        WHEN wait_minutes BETWEEN 31 AND 60 THEN 'Medium'
        WHEN wait_minutes > 60 THEN 'Long'
        ELSE 'Unknown / NULL' -- Includes NULL values
    END AS wait_time_bucket,
    COUNT(*) AS num_events
FROM fact_ride_events
GROUP BY wait_time_bucket
ORDER BY wait_time_bucket;

-- Part 2: Count how many wait_minutes values are NULL
SELECT 
    COUNT(*) AS null_wait_minutes
FROM fact_ride_events
WHERE wait_minutes IS NULL;


-- Q4: Average Satisfaction Rating by Attraction and Category
SELECT 
    da.attraction_name, 
    da.category, 
    ROUND(AVG(fre.satisfaction_rating), 2) AS avg_satisfaction_rating
FROM fact_ride_events fre
LEFT JOIN dim_attraction da 
    ON da.attraction_id = fre.attraction_id
GROUP BY da.attraction_name, da.category
ORDER BY avg_satisfaction_rating DESC;


-- Q5: Duplicate Check — Identical Rows in fact_ride_events
SELECT
    visit_id,
    attraction_id,
    ride_time,
    wait_minutes,
    satisfaction_rating,
    photo_purchase,
    COUNT(*) AS duplicate_count
FROM fact_ride_events
GROUP BY
    visit_id,
    attraction_id,
    ride_time,
    wait_minutes,
    satisfaction_rating,
    photo_purchase
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- Q6: Null Audit — Check Missing Values in Key Columns
SELECT 
    COUNT(*) AS total_spend_cents_missing, 
    (
        SELECT COUNT(*) 
        FROM fact_purchases
        WHERE amount_cents IS NULL
    ) AS amount_cents_missing, 
    (
        SELECT COUNT(*) 
        FROM fact_ride_events
        WHERE wait_minutes IS NULL
    ) AS wait_time_unknown
FROM fact_visits
WHERE total_spend_cents IS NULL;


-- Q7: Average Party Size by Day of the Week
SELECT
    d.day_name,
    ROUND(AVG(v.party_size), 2) AS avg_party_size,
    COUNT(DISTINCT v.visit_id) AS num_visits
FROM fact_visits v
LEFT JOIN dim_date d 
    ON v.date_id = d.date_id
GROUP BY d.day_name
ORDER BY
    CASE d.day_name
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END;



