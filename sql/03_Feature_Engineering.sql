-- Add stay_hours column to fact_visits
ALTER TABLE fact_visits 
ADD COLUMN stay_hours INTEGER;

-- Calculate duration of stay in hours (rounded to 2 decimal places)
UPDATE fact_visits
SET stay_hours = CAST(FLOOR((JULIANDAY(exit_time) - JULIANDAY(entry_time)) * 24 * 100) AS REAL) / 100;
-- 47 rows updated


-- Add wait_bucket column to fact_ride_events
ALTER TABLE fact_ride_events 
ADD COLUMN wait_bucket TEXT;

-- Categorize wait times into predefined buckets
UPDATE fact_ride_events
SET wait_bucket = CASE
    WHEN wait_minutes IS NULL THEN 'Unknown'
    WHEN wait_minutes < 30 THEN '0-30 min'
    WHEN wait_minutes <= 60 THEN '30-60 min'
    ELSE '60+ min'
END;
--  142 rows updated


--  Add spend_dollars column to fact_visits
ALTER TABLE fact_visits 
ADD COLUMN spend_dollars REAL;

-- 💲 Convert spend from cents to dollars
UPDATE fact_visits
SET spend_dollars = spend_cents_clean / 100.0;
-- 47 rows updated
