-- =============================================================
-- 03_metrics.sql
-- The 10 required metrics, one query each, from clean.customer_revenue.
-- Each query is saved as a view in the metrics schema, so every metric
-- is defined once and reused by 04_summary.sql (Tableau) and
-- 05_checks.sql. Every view returns one row per year: (year, metric).
--
-- Definitions (2015 and attrition confirmed with Lexi, 11/17):
--   New       = in year Y, not in Y-1
--   Lost      = in Y-1, not in Y (counted under Y)
--   Existing  = in both Y-1 and Y (a matched group per year)
--   2015 has no prior year, so only metrics 1 and 7 are reported for it.
--   Years are compared to the year right before only.
-- =============================================================

CREATE SCHEMA IF NOT EXISTS metrics;


-- 01 Total Revenue (Current Year)
CREATE OR REPLACE VIEW metrics.m01_total_revenue AS
SELECT
	year,
	SUM(net_revenue) AS total_revenue
FROM
	clean.customer_revenue
GROUP BY
	year
ORDER BY
	year;
-- Result: 2015 = 29,036,749.19 | 2016 = 25,730,943.59 | 2017 = 31,417,495.03


-- 02 New Customer Revenue
-- First year excluded: no prior year to compare against.
CREATE OR REPLACE VIEW metrics.m02_new_customer_revenue AS
SELECT
	curr.year,
	SUM(curr.net_revenue) AS new_customer_revenue
FROM
	clean.customer_revenue curr
WHERE
	curr.year > (SELECT MIN(year) FROM clean.customer_revenue)
	AND NOT EXISTS (
		SELECT 1
		FROM clean.customer_revenue prev
		WHERE prev.customer_email = curr.customer_email
		  AND prev.year = curr.year - 1
	)
GROUP BY
	curr.year
ORDER BY
	curr.year;
-- Result: 2016 = 17,206,366.90 | 2017 = 21,769,213.01


-- 03 Existing Customer Growth
-- Inner join keeps only customers in both years; the first year
-- drops out on its own (no prior year to match).
CREATE OR REPLACE VIEW metrics.m03_existing_customer_growth AS
SELECT
	curr.year,
	SUM(curr.net_revenue) - SUM(prev.net_revenue) AS existing_customer_growth
FROM
	clean.customer_revenue curr
JOIN
	clean.customer_revenue prev
	ON  prev.customer_email = curr.customer_email
	AND prev.year = curr.year - 1
GROUP BY
	curr.year
ORDER BY
	curr.year;
-- Result: 2016 = 39,043.65 | 2017 = 63,857.06


-- 04 Revenue Lost from Attrition
-- Starts from last year's customers; keeps those missing the next year;
-- sums their last-year revenue and reports it under the next year.
-- Last year excluded: no following year to check.
CREATE OR REPLACE VIEW metrics.m04_revenue_lost_attrition AS
SELECT
	prev.year + 1         AS year,
	SUM(prev.net_revenue) AS revenue_lost_attrition
FROM
	clean.customer_revenue prev
WHERE
	prev.year < (SELECT MAX(year) FROM clean.customer_revenue)
	AND NOT EXISTS (
		SELECT 1
		FROM clean.customer_revenue nxt
		WHERE nxt.customer_email = prev.customer_email
		  AND nxt.year = prev.year + 1
	)
GROUP BY
	prev.year
ORDER BY
	prev.year;
-- Result: 2016 = 20,551,216.15 | 2017 = 16,146,518.63


-- 05 Existing Customer Revenue (Current Year)
CREATE OR REPLACE VIEW metrics.m05_existing_revenue_current AS
SELECT
	curr.year,
	SUM(curr.net_revenue) AS existing_customer_revenue_current
FROM
	clean.customer_revenue curr
JOIN
	clean.customer_revenue prev
	ON  prev.customer_email = curr.customer_email
	AND prev.year = curr.year - 1
GROUP BY
	curr.year
ORDER BY
	curr.year;
-- Result: 2016 = 8,524,576.69 | 2017 = 9,648,282.02


-- 06 Existing Customer Revenue (Prior Year)
-- Same matched group as 05, summing their previous-year revenue.
CREATE OR REPLACE VIEW metrics.m06_existing_revenue_prior AS
SELECT
	curr.year,
	SUM(prev.net_revenue) AS existing_customer_revenue_prior
FROM
	clean.customer_revenue curr
JOIN
	clean.customer_revenue prev
	ON  prev.customer_email = curr.customer_email
	AND prev.year = curr.year - 1
GROUP BY
	curr.year
ORDER BY
	curr.year;
-- Result: 2016 = 8,485,533.04 | 2017 = 9,584,424.96


-- 07 Total Customers (Current Year)
CREATE OR REPLACE VIEW metrics.m07_total_customers_current AS
SELECT
	year,
	COUNT(DISTINCT customer_email) AS total_customers_current
FROM
	clean.customer_revenue
GROUP BY
	year
ORDER BY
	year;
-- Result: 2015 = 231,294 | 2016 = 204,646 | 2017 = 249,987


-- 08 Total Customers (Previous Year)
-- LAG pulls the prior year's count; the filter runs outside the CTE
-- because WHERE is applied before window functions.
CREATE OR REPLACE VIEW metrics.m08_total_customers_prior AS
WITH yearly AS (
	SELECT
		year,
		LAG(COUNT(DISTINCT customer_email)) OVER (ORDER BY year) AS total_customers_prior
	FROM
		clean.customer_revenue
	GROUP BY
		year
)
SELECT
	year,
	total_customers_prior
FROM
	yearly
WHERE
	year > (SELECT MIN(year) FROM clean.customer_revenue)
ORDER BY
	year;
-- Result: 2016 = 231,294 | 2017 = 204,646


-- 09 New Customers
CREATE OR REPLACE VIEW metrics.m09_new_customers AS
SELECT
	curr.year,
	COUNT(DISTINCT curr.customer_email) AS new_customers
FROM
	clean.customer_revenue curr
WHERE
	curr.year > (SELECT MIN(year) FROM clean.customer_revenue)
	AND NOT EXISTS (
		SELECT 1
		FROM clean.customer_revenue prev
		WHERE prev.customer_email = curr.customer_email
		  AND prev.year = curr.year - 1
	)
GROUP BY
	curr.year
ORDER BY
	curr.year;
-- Result: 2016 = 136,891 | 2017 = 173,449


-- 10 Lost Customers
CREATE OR REPLACE VIEW metrics.m10_lost_customers AS
SELECT
	prev.year + 1                       AS year,
	COUNT(DISTINCT prev.customer_email) AS lost_customers
FROM
	clean.customer_revenue prev
WHERE
	prev.year < (SELECT MAX(year) FROM clean.customer_revenue)
	AND NOT EXISTS (
		SELECT 1
		FROM clean.customer_revenue nxt
		WHERE nxt.customer_email = prev.customer_email
		  AND nxt.year = prev.year + 1
	)
GROUP BY
	prev.year
ORDER BY
	prev.year;
-- Result: 2016 = 163,539 | 2017 = 128,108
