-- BigQuery GoogleSQL. Replace every YOUR_PROJECT_ID before running.
-- Independent portfolio project. All data and rules are fictional.
-- Not affiliated with or endorsed by T-Mobile. No real company/customer data.
-- Rerunning replaces only the demo tables named below.
CREATE SCHEMA IF NOT EXISTS `YOUR_PROJECT_ID.commission_analytics`;

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.commission_analytics.raw_stores` AS
SELECT store_id, FORMAT('Demo Store %02d', store_id) AS store_name,
 ['West','Southwest','Midwest','Northeast','Southeast'][OFFSET(MOD(store_id-1,5))] AS region
FROM UNNEST(GENERATE_ARRAY(1,10)) store_id;

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.commission_analytics.raw_reps` AS
SELECT rep_id, FORMAT('Demo Rep %03d',rep_id) AS rep_name,
 DIV(rep_id-1,5)+1 AS store_id,
 CAST(0.05 AS NUMERIC) AS commission_rate
FROM UNNEST(GENERATE_ARRAY(1,50)) rep_id;

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.commission_analytics.monthly_targets` AS
SELECT rep_id, month_start, CAST(4500 AS NUMERIC) AS revenue_target
FROM `YOUR_PROJECT_ID.commission_analytics.raw_reps`
CROSS JOIN UNNEST(GENERATE_DATE_ARRAY(DATE '2025-01-01', DATE '2025-12-01', INTERVAL 1 MONTH)) month_start;

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.commission_analytics.raw_sales` AS
WITH ids AS (
 SELECT sale_id,
 -- Separate salted hashes avoid linking a rep to only one product or date.
 MOD(MOD(FARM_FINGERPRINT(CONCAT('rep:',CAST(sale_id AS STRING))),50)+50,50)+1 AS rep_id,
 MOD(MOD(FARM_FINGERPRINT(CONCAT('date:',CAST(sale_id AS STRING))),365)+365,365) AS day_offset,
 MOD(MOD(FARM_FINGERPRINT(CONCAT('product:',CAST(sale_id AS STRING))),3)+3,3) AS product_index,
 MOD(MOD(FARM_FINGERPRINT(CONCAT('price:',CAST(sale_id AS STRING))),90001)+90001,90001) AS price_cents,
 MOD(MOD(FARM_FINGERPRINT(CONCAT('cancel:',CAST(sale_id AS STRING))),100)+100,100)<8 AS is_cancelled
 FROM UNNEST(GENERATE_ARRAY(1,12000)) sale_id
), priced AS (
 SELECT sale_id, rep_id, DATE_ADD(DATE '2025-01-01', INTERVAL day_offset DAY) AS sale_date,
 ['Activation','Upgrade','Accessory'][OFFSET(product_index)] AS transaction_type,
 CAST(10000+price_cents AS NUMERIC)/100 AS revenue, is_cancelled
 FROM ids
), calculated AS (
 SELECT p.*, r.store_id, r.commission_rate,
 ROUND(IF(is_cancelled,0,revenue*commission_rate),2) AS expected_commission
 FROM priced p JOIN `YOUR_PROJECT_ID.commission_analytics.raw_reps` r USING(rep_id)
)
SELECT *,
 -- Deliberate +$10 errors every 97th transaction: exactly 123 exceptions.
 expected_commission + IF(MOD(sale_id,97)=0,10,0) AS recorded_commission
FROM calculated;

-- Assertions fail the script if key dataset invariants are broken.
ASSERT (SELECT COUNT(*) FROM `YOUR_PROJECT_ID.commission_analytics.raw_sales`)=12000 AS 'Expected 12000 sales';
ASSERT (SELECT COUNT(DISTINCT sale_id) FROM `YOUR_PROJECT_ID.commission_analytics.raw_sales`)=12000 AS 'Unique sale IDs';
ASSERT (SELECT COUNT(*) FROM `YOUR_PROJECT_ID.commission_analytics.monthly_targets`)=600 AS 'Expected 600 rep-month targets';
ASSERT (SELECT COUNT(*) FROM `YOUR_PROJECT_ID.commission_analytics.raw_sales` WHERE recorded_commission != expected_commission)=123 AS 'Expected 123 injected exceptions';
ASSERT (SELECT COUNT(*) FROM `YOUR_PROJECT_ID.commission_analytics.raw_sales` WHERE is_cancelled AND expected_commission!=0)=0 AS 'Cancelled sales earn zero';
SELECT 'stores' AS table_name, COUNT(*) AS row_count FROM `YOUR_PROJECT_ID.commission_analytics.raw_stores`
UNION ALL SELECT 'reps', COUNT(*) FROM `YOUR_PROJECT_ID.commission_analytics.raw_reps`
UNION ALL SELECT 'targets', COUNT(*) FROM `YOUR_PROJECT_ID.commission_analytics.monthly_targets`
UNION ALL SELECT 'sales', COUNT(*) FROM `YOUR_PROJECT_ID.commission_analytics.raw_sales`;
