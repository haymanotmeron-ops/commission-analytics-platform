-- Commission Analytics Platform
-- Synthetic source data generator for BigQuery.
-- Run this script in your BigQuery Sandbox project.
-- Replace `YOUR_PROJECT_ID` with your Google Cloud project ID.

CREATE SCHEMA IF NOT EXISTS `YOUR_PROJECT_ID.commission_analytics`;

-- Stores
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.commission_analytics.raw_stores` AS
SELECT
  store_id,
  CONCAT('Store ', CAST(store_id AS STRING)) AS store_name,
  ['West','Southwest','Midwest','Northeast','Southeast'][OFFSET(MOD(store_id - 1, 5))] AS region
FROM UNNEST(GENERATE_ARRAY(1, 50)) AS store_id;

-- Sales representatives
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.commission_analytics.raw_reps` AS
SELECT
  rep_id,
  CONCAT('Rep ', CAST(rep_id AS STRING)) AS rep_name,
  DATE_ADD(DATE '2019-01-01', INTERVAL MOD(rep_id * 17, 1800) DAY) AS hire_date,
  CAST([0.04,0.05,0.06,0.07,0.08][OFFSET(MOD(rep_id - 1, 5))] AS NUMERIC) AS commission_rate
FROM UNNEST(GENERATE_ARRAY(1, 200)) AS rep_id;

-- Customers
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.commission_analytics.raw_customers` AS
SELECT
  customer_id,
  ['Consumer','Small Business','Enterprise'][OFFSET(MOD(customer_id - 1, 3))] AS segment
FROM UNNEST(GENERATE_ARRAY(1, 5000)) AS customer_id;

-- Sales transactions
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.commission_analytics.raw_sales` AS
WITH sales AS (
  SELECT
    sale_id,
    DATE_ADD(DATE '2025-01-01', INTERVAL MOD(sale_id * 37, 730) DAY) AS sale_date,
    MOD(sale_id * 13, 50) + 1 AS store_id,
    MOD(sale_id * 17, 200) + 1 AS rep_id,
    MOD(sale_id * 29, 5000) + 1 AS customer_id,
    ROUND(
      40
      + RAND(sale_id) * 960
      + CASE MOD(sale_id, 10)
          WHEN 0 THEN 800
          WHEN 1 THEN 400
          ELSE 0
        END,
      2
    ) AS revenue
  FROM UNNEST(GENERATE_ARRAY(1, 50000)) AS sale_id
)
SELECT
  sale_id,
  sale_date,
  store_id,
  rep_id,
  customer_id,
  revenue,
  ROUND(revenue * r.commission_rate, 2) AS commission_amount
FROM sales
JOIN `YOUR_PROJECT_ID.commission_analytics.raw_reps` r
USING (rep_id);

-- Quick validation
SELECT 'stores' AS table_name, COUNT(*) AS row_count FROM `YOUR_PROJECT_ID.commission_analytics.raw_stores`
UNION ALL
SELECT 'reps', COUNT(*) FROM `YOUR_PROJECT_ID.commission_analytics.raw_reps`
UNION ALL
SELECT 'customers', COUNT(*) FROM `YOUR_PROJECT_ID.commission_analytics.raw_customers`
UNION ALL
SELECT 'sales', COUNT(*) FROM `YOUR_PROJECT_ID.commission_analytics.raw_sales`;
