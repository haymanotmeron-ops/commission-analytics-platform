-- Run after 00_generate_synthetic_data.sql. Replace YOUR_PROJECT_ID.
-- Fictional rules: 5% of non-cancelled revenue; cancelled transactions earn zero.
-- No bonuses, taxes, or cross-month clawbacks modeled.
CREATE OR REPLACE VIEW `YOUR_PROJECT_ID.commission_analytics.commission_exceptions` AS
SELECT *, recorded_commission-expected_commission AS payout_variance
FROM `YOUR_PROJECT_ID.commission_analytics.raw_sales`
WHERE recorded_commission != expected_commission;

CREATE OR REPLACE VIEW `YOUR_PROJECT_ID.commission_analytics.rep_monthly_performance` AS
WITH monthly AS (
 SELECT rep_id, DATE_TRUNC(sale_date,MONTH) AS month_start,
 COUNT(*) AS transactions, COUNTIF(is_cancelled) AS cancellations,
 SUM(revenue) AS gross_revenue,
 SUM(IF(is_cancelled,0,revenue)) AS net_revenue,
 SUM(expected_commission) AS expected_commission,
 SUM(recorded_commission) AS recorded_commission,
 COUNTIF(recorded_commission!=expected_commission) AS payout_exceptions
 FROM `YOUR_PROJECT_ID.commission_analytics.raw_sales`
 GROUP BY rep_id, month_start
)
SELECT t.rep_id, r.rep_name, r.store_id, s.store_name, s.region,
 t.month_start, t.revenue_target,
 COALESCE(m.transactions,0) AS transactions,
 COALESCE(m.cancellations,0) AS cancellations,
 COALESCE(m.gross_revenue,0) AS gross_revenue,
 COALESCE(m.net_revenue,0) AS net_revenue,
 SAFE_DIVIDE(COALESCE(m.net_revenue,0),t.revenue_target) AS target_attainment,
 COALESCE(m.expected_commission,0) AS expected_commission,
 COALESCE(m.recorded_commission,0) AS recorded_commission,
 COALESCE(m.recorded_commission-m.expected_commission,0) AS payout_variance,
 COALESCE(m.payout_exceptions,0) AS payout_exceptions
FROM `YOUR_PROJECT_ID.commission_analytics.monthly_targets` t
JOIN `YOUR_PROJECT_ID.commission_analytics.raw_reps` r USING(rep_id)
JOIN `YOUR_PROJECT_ID.commission_analytics.raw_stores` s ON r.store_id=s.store_id
LEFT JOIN monthly m ON t.rep_id=m.rep_id AND t.month_start=m.month_start;

-- Monthly dashboard summary. Calculate aggregate attainment as ratio of sums.
SELECT month_start, SUM(net_revenue) AS net_revenue,
 SUM(expected_commission) AS expected_commission,
 SUM(recorded_commission) AS recorded_commission,
 SUM(payout_variance) AS payout_variance,
 SAFE_DIVIDE(SUM(net_revenue),SUM(revenue_target)) AS target_attainment,
 SAFE_DIVIDE(SUM(cancellations),SUM(transactions)) AS cancellation_rate
FROM `YOUR_PROJECT_ID.commission_analytics.rep_monthly_performance`
GROUP BY month_start ORDER BY month_start;

-- Expected from injection logic: 123 exceptions and $1230 excess recorded payout.
SELECT COUNT(*) AS exception_count, SUM(payout_variance) AS total_variance
FROM `YOUR_PROJECT_ID.commission_analytics.commission_exceptions`;
