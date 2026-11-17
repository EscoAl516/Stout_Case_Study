-- =============================================================
-- 02_clean.sql
-- Builds clean.customer_revenue from raw.casestudy.
-- Every fix is based on a check in 01_data_checks.sql:
--   - customer_email: TRIM (270,214 rows had leading/trailing spaces)
--   - net_revenue:    numeric(10,2), exact cents (all values castable)
--   - year:           integer, so the prior year is simply year - 1
--   - idx dropped:    CSV row number, not used by any metric
-- =============================================================


-- 1. Schema for cleaned tables (re-runnable).
CREATE SCHEMA IF NOT EXISTS clean;

DROP TABLE IF EXISTS clean.customer_revenue;


-- 2. Clean table.
CREATE TABLE clean.customer_revenue AS
SELECT
	TRIM(customer_email)             AS customer_email,
	TRIM(net_revenue)::numeric(10,2) AS net_revenue,
	TRIM(year)::integer              AS year
FROM
	raw.casestudy;


-- 3. Check: rows and revenue per year must match check 6 in 01.
SELECT
	year,
	COUNT(*)         AS row_count,
	SUM(net_revenue) AS total_revenue
FROM
	clean.customer_revenue
GROUP BY
	year
ORDER BY
	year ASC;
-- Results: 2015 = 231,294 rows / 29,036,749.19
--           2016 = 204,646 rows / 25,730,943.59
--           2017 = 249,987 rows / 31,417,495.03
