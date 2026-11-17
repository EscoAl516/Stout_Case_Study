-- =============================================================
-- 05_checks.sql
-- Consistency checks: the 10 metrics must agree with each other.
-- Every row should show difference = 0 and passed = true.
-- The existing-customer count is not one of the 10 metrics, so it is
-- computed here independently (customers present in Y-1 and Y).
-- =============================================================

WITH existing AS (
	SELECT
		curr.year,
		COUNT(*) AS existing_customers
	FROM
		clean.customer_revenue curr
	JOIN
		clean.customer_revenue prev
		ON  prev.customer_email = curr.customer_email
		AND prev.year = curr.year - 1
	GROUP BY
		curr.year
),
s AS (
	SELECT
		ys.*,
		e.existing_customers,
		prior.total_revenue AS total_revenue_prior_year
	FROM
		metrics.yearly_summary ys
	JOIN existing e
		ON e.year = ys.year
	JOIN metrics.yearly_summary prior
		ON prior.year = ys.year - 1
),
checks AS (
	-- 1. This year's revenue = new customers + existing customers
	SELECT year, '1. Total Revenue = New Rev + Existing Rev (Current)' AS check_name,
	       total_revenue AS left_side,
	       new_customer_revenue + existing_customer_revenue_current AS right_side
	FROM s
	UNION ALL
	-- 2. Growth = existing revenue this year - same customers last year
	SELECT year, '2. Existing Growth = Existing Rev (Current) - (Prior)',
	       existing_customer_growth,
	       existing_customer_revenue_current - existing_customer_revenue_prior
	FROM s
	UNION ALL
	-- 3. This year's customers = new + existing
	SELECT year, '3. Total Customers (Current) = New + Existing',
	       total_customers_current,
	       new_customers + existing_customers
	FROM s
	UNION ALL
	-- 4. Last year's customers = lost + existing
	SELECT year, '4. Total Customers (Prior) = Lost + Existing',
	       total_customers_prior,
	       lost_customers + existing_customers
	FROM s
	UNION ALL
	-- 5. Last year's revenue = revenue lost + existing revenue (prior)
	SELECT year, '5. Prior-Year Revenue = Lost Rev + Existing Rev (Prior)',
	       total_revenue_prior_year,
	       revenue_lost_attrition + existing_customer_revenue_prior
	FROM s
)
SELECT
	year,
	check_name,
	left_side,
	right_side,
	left_side - right_side AS difference,
	left_side = right_side AS passed
FROM
	checks
ORDER BY
	check_name,
	year;
-- Result: all 10 rows passed = true, difference = 0
