-- If you haven't added these yet, run them ONCE (comment out if they already exist)
ALTER TABLE fact_visits ADD COLUMN spend_cents_clean INTEGER;
ALTER TABLE fact_purchases ADD COLUMN amount_cents_clean INTEGER;
-- Visits: compute cleaned once, join by rowid, update when cleaned is non-empty
WITH c AS (
SELECT
rowid AS rid,
REPLACE(REPLACE(REPLACE(REPLACE(UPPER(COALESCE(total_spend_cents,'')),
'USD',''), '$',''), ',', ''), ' ', '') AS cleaned
FROM fact_visits
)
UPDATE fact_visits
SET spend_cents_clean = CAST((SELECT cleaned FROM c WHERE c.rid = fact_visits.rowid)
AS INTEGER)
WHERE LENGTH((SELECT cleaned FROM c WHERE c.rid = fact_visits.rowid)) > 0;
-- Purchases: same pattern (WRITE THE SAME CODE ABOVE for the fact_purchases table)
-- Remember facts_visits and facts_purchases has the `amount` column in units of cents so you may need to do another SELECT statement to convert these columns to dollars

-------------

-- Checking for Exact Duplicates in fact_ride_events
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


-- Checking for Duplicate purchase_id in fact_purchases
SELECT 
    purchase_id, 
    COUNT(*) AS dup_count
FROM fact_purchases
GROUP BY purchase_id
HAVING COUNT(*) > 1;


-- Validating Foreign Keys

-- 1. Guest ID in fact_visits should exist in dim_guest
SELECT 
    v.visit_id, 
    v.guest_id
FROM fact_visits v
LEFT JOIN dim_guest g ON g.guest_id = v.guest_id
WHERE g.guest_id IS NULL;

-- 2. Ticket Type ID in fact_visits should exist in dim_ticket
SELECT 
    v.visit_id, 
    v.ticket_type_id
FROM fact_visits v
LEFT JOIN dim_ticket dt ON dt.ticket_type_id = v.ticket_type_id
WHERE dt.ticket_type_id IS NULL;

-- 3. visit_id in fact_purchases should exist in fact_visits
SELECT 
    p.purchase_id, 
    p.visit_id
FROM fact_purchases p
LEFT JOIN fact_visits v ON v.visit_id = p.visit_id
WHERE v.visit_id IS NULL;

-- 4. attraction_id in fact_ride_events should exist in dim_attraction
SELECT 
    fre.ride_event_id, 
    fre.attraction_id
FROM fact_ride_events fre
LEFT JOIN dim_attraction a ON a.attraction_id = fre.attraction_id
WHERE a.attraction_id IS NULL;

-- 5. visit_id in fact_ride_events should exist in fact_visits
SELECT 
    fre.ride_event_id, 
    fre.visit_id
FROM fact_ride_events fre
LEFT JOIN fact_visits v ON v.visit_id = fre.visit_id
WHERE v.visit_id IS NULL;

-- Notes:
-- If LEFT JOIN returns NULLs in the right table, that indicates "orphans":
-- records that refer to a non-existent parent (invalid foreign key).


-- Data Cleaning Section

-- Clean amount_cents in fact_purchases by removing extra characters
WITH cleaned_amounts AS (
  SELECT
    rowid AS rid,
    REPLACE(
      REPLACE(
        REPLACE(
          REPLACE(UPPER(COALESCE(amount_cents, '')), 'USD', ''), 
        '$', ''), 
      ',', ''), 
    ' ', '') AS cleaned
  FROM fact_purchases
)
UPDATE fact_purchases
SET amount_cents_clean = CAST((
    SELECT cleaned FROM cleaned_amounts WHERE cleaned_amounts.rid = fact_purchases.rowid
) AS INTEGER)
WHERE LENGTH((
    SELECT cleaned FROM cleaned_amounts WHERE cleaned_amounts.rid = fact_purchases.rowid
)) > 0;


-- Clean promotion_code in fact_visits: remove dashes, trim, and uppercase
UPDATE fact_visits
SET promotion_code = REPLACE(UPPER(TRIM(promotion_code)), '-', '')
WHERE promotion_code IS NOT NULL;
-- 40 rows affected


-- Preview distinct cleaned promotion codes
SELECT DISTINCT REPLACE(UPPER(TRIM(promotion_code)), '-', '')
FROM fact_visits;


-- Clean marketing_opt_in values: fix misspelled 'NOO'
UPDATE dim_guest
SET marketing_opt_in = REPLACE(TRIM(UPPER(marketing_opt_in)), 'NOO', 'NO');
-- 10 rows affected


-- Normalize payment_method values in fact_purchases
UPDATE fact_purchases
SET payment_method = UPPER(TRIM(payment_method));
-- 63 rows affected


-- Clean and normalize home_state in dim_guest
UPDATE dim_guest
SET home_state = UPPER(TRIM(home_state));
-- 10 rows affected

-- Replace full state names with abbreviations
UPDATE dim_guest
SET home_state = REPLACE(home_state, 'NEW YORK', 'NY');
UPDATE dim_guest
SET home_state = REPLACE(home_state, 'CALIFORNIA', 'CA');
UPDATE dim_guest
SET home_state = REPLACE(home_state, 'TEXAS', 'TX');
UPDATE dim_guest
SET home_state = REPLACE(home_state, 'FLORIDA', 'FL');
-- 10 rows affected

-- Preview cleaned home_state values
SELECT DISTINCT home_state
FROM dim_guest;


--Validation: Do guest spend values match between fact_visits and fact_purchases?

SELECT 
    v.guest_id, 
    SUM(v.spend_cents_clean) AS total_spend_visits,
    SUM(p.amount_cents_clean) AS total_spend_purchases
FROM fact_visits v
INNER JOIN fact_purchases p ON p.visit_id = v.visit_id
GROUP BY v.guest_id;