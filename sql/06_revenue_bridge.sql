-- =============================================================
-- 06_revenue_bridge.sql
-- Revenue bridge (waterfall) for the Tableau dashboard: how revenue
-- moved from the previous year to the reporting year.
--   previous-year revenue + new customer revenue + existing growth
--   - revenue lost from attrition = current-year revenue
-- This identity is check 1 + check 5 in 05_checks.sql.
-- One row per (year, step). bar_start/bar_end give each bar's
-- position, so Tableau can draw it as a Gantt bar.
-- The first year has no prior year, so it has no bridge.
-- =============================================================

CREATE OR REPLACE VIEW metrics.revenue_bridge AS
WITH s AS (
	SELECT
		year,
		revenue_lost_attrition + existing_customer_revenue_prior AS prior_revenue,
		new_customer_revenue,
		existing_customer_growth,
		revenue_lost_attrition,
		total_revenue
	FROM
		metrics.yearly_summary
	WHERE
		new_customer_revenue IS NOT NULL   -- skips the first year
)
SELECT year::text AS year, 1 AS step_order, 'Previous-year revenue' AS step, 'total' AS step_type,
       prior_revenue AS amount, 0 AS bar_start, prior_revenue AS bar_end
FROM s
UNION ALL
SELECT year::text, 2, 'New customers', 'increase',
       new_customer_revenue,
       prior_revenue,
       prior_revenue + new_customer_revenue
FROM s
UNION ALL
SELECT year::text, 3, 'Existing growth', 'increase',
       existing_customer_growth,
       prior_revenue + new_customer_revenue,
       prior_revenue + new_customer_revenue + existing_customer_growth
FROM s
UNION ALL
SELECT year::text, 4, 'Lost customers', 'decrease',
       -revenue_lost_attrition,
       prior_revenue + new_customer_revenue + existing_customer_growth,
       prior_revenue + new_customer_revenue + existing_customer_growth - revenue_lost_attrition
FROM s
UNION ALL
SELECT year::text, 5, 'Current-year revenue', 'total',
       total_revenue, 0, total_revenue
FROM s;


-- Check: the bar before "Current-year revenue" must end exactly at
-- current-year revenue (difference = 0 for every year).
SELECT
	b4.year,
	b4.bar_end   AS bridge_end,
	b5.bar_end   AS total_revenue,
	b4.bar_end - b5.bar_end AS difference
FROM metrics.revenue_bridge b4
JOIN metrics.revenue_bridge b5
	ON b5.year = b4.year AND b5.step_order = 5
WHERE b4.step_order = 4
ORDER BY b4.year;
-- Result: 2016 and 2017 both difference = 0.00
