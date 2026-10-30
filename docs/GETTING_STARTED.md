# Synthetic commission analysis
Independent personal portfolio project inspired by telecom retail reporting. Not affiliated with or endorsed by T-Mobile. All stores, representatives, transactions, targets, and commission rules are fictional.

## Run in BigQuery
1. Open your Google Cloud project's BigQuery SQL editor.
2. Copy sql/00_generate_synthetic_data.sql from this repository.
3. Replace ALL occurrences of YOUR_PROJECT_ID with your actual project ID (not project display name).
4. Run the entire script using GoogleSQL. It creates the commission_analytics dataset in your project's default location. Use that same location for subsequent queries.
5. Check the final counts: 10 stores, 50 representatives, 600 monthly targets, 12,000 sales.
6. Copy sql/01_commission_analysis.sql, replace YOUR_PROJECT_ID again, and run.
7. Inspect rep_monthly_performance and commission_exceptions in the dataset.

Rerunning the generator replaces the four named demo tables. Existing unrelated tables are untouched. No billing setup or cloud execution was performed by the repository author; review your own project's query estimate before running.

## Fictional rules and definitions
- Calendar year 2025; five representatives per store.
- Revenue is a synthetic transaction value in USD, not telecom recurring revenue.
- Expected commission: 5% of transaction revenue, rounded per transaction.
- Cancelled transactions earn zero commission and contribute zero net revenue.
- Net revenue excludes cancelled transactions. Cancellation is a final transaction status; no cancellation dates or later-period clawbacks are modeled.
- Each representative has a monthly net revenue target of $4,500. There are no bonus tiers.
- Recorded payout intentionally exceeds expected payout by $10 on every 97th transaction. Expect 123 exceptions and $1,230 total excess payout. These are injected test cases, not discovered company losses.
- Hash-based generation is deterministic; categories and dates use independent salts. This is a simplified demonstration, not an empirically calibrated sales distribution.

## Dashboard plan
Use rep_monthly_performance for monthly revenue, commission, target attainment, store and representative comparisons. Use commission_exceptions for an audit detail table. Aggregate target attainment as SUM(net_revenue)/SUM(revenue_target), not a sum of percentages. Label every dashboard "Synthetic data / fictional commission rules."

## Validation status
The SQL contains executable assertions for row counts, transaction uniqueness, cancellation handling, and injected exception counts. It has not yet been executed against your BigQuery account. Run it and review assertions before claiming measured project results.
