-- =============================================================
-- 04_summary.sql
-- One row per year with all 10 metrics side by side, built from the
-- views in 03_metrics.sql. This is the table Tableau connects to.
-- 2015 has values only for metrics 1 and 7 (no prior year); the
-- other columns are NULL for 2015 by design, not missing data.
-- =============================================================

CREATE OR REPLACE VIEW metrics.yearly_summary AS
SELECT
	m01.year,
	m01.total_revenue,                      -- 01
	m02.new_customer_revenue,               -- 02
	m03.existing_customer_growth,           -- 03
	m04.revenue_lost_attrition,             -- 04
	m05.existing_customer_revenue_current,  -- 05
	m06.existing_customer_revenue_prior,    -- 06
	m07.total_customers_current,            -- 07
	m08.total_customers_prior,              -- 08
	m09.new_customers,                      -- 09
	m10.lost_customers                      -- 10
FROM
	metrics.m01_total_revenue m01
	-- LEFT JOIN keeps every year from metric 1, including 2015
	LEFT JOIN metrics.m02_new_customer_revenue     m02 ON m02.year = m01.year
	LEFT JOIN metrics.m03_existing_customer_growth m03 ON m03.year = m01.year
	LEFT JOIN metrics.m04_revenue_lost_attrition   m04 ON m04.year = m01.year
	LEFT JOIN metrics.m05_existing_revenue_current m05 ON m05.year = m01.year
	LEFT JOIN metrics.m06_existing_revenue_prior   m06 ON m06.year = m01.year
	LEFT JOIN metrics.m07_total_customers_current  m07 ON m07.year = m01.year
	LEFT JOIN metrics.m08_total_customers_prior    m08 ON m08.year = m01.year
	LEFT JOIN metrics.m09_new_customers            m09 ON m09.year = m01.year
	LEFT JOIN metrics.m10_lost_customers           m10 ON m10.year = m01.year;


-- Check: 3 rows (2015, 2016, 2017).
SELECT *
FROM metrics.yearly_summary
ORDER BY year;
