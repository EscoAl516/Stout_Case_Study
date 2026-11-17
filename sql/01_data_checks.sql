-- =============================================================
-- 01_data_checks.sql
-- Data quality checks on raw.casestudy (loaded by 00_load_raw.sql,
-- all columns as text, values exactly as in casestudy.csv).
-- =============================================================


-- 1. Load check: rows in table vs rows in file (685,927),
--    and longest email to confirm nothing was cut off on import.
SELECT
	COUNT(*)                    AS total_rows,
	MAX(LENGTH(customer_email)) AS longest_email
FROM
	raw.casestudy;
-- Result: 685,927 rows (matches file); longest email = 21 chars


-- 2. Rows with extra whitespace in customer_email (either end).
SELECT
	COUNT(*) AS rows_with_extra_space
FROM
	raw.casestudy
WHERE
	customer_email <> TRIM(customer_email);
-- Result: 270,214 rows (39.4% of 685,927)


-- 3. Leading vs trailing whitespace.
SELECT
	COUNT(*) FILTER (WHERE customer_email LIKE ' %') AS leading_space,
	COUNT(*) FILTER (WHERE customer_email LIKE '% ') AS trailing_space
FROM
	raw.casestudy;
-- Result: leading = 228,643; trailing = 41,571
-- 228,643 + 41,571 = 270,214 -> no row has spaces at both ends


-- 4. Any whitespace left after TRIM (tabs, newlines, etc.)?
SELECT
	COUNT(*) AS other_whitespace_after_trim
FROM
	raw.casestudy
WHERE
	TRIM(customer_email) ~ '\s';
-- Result: 0 -> TRIM alone is enough to clean customer_email

-- 5. Can every value be cast safely?
-- Counts values that are NOT a plain number, a 4-digit year, and blank emails.
SELECT
	COUNT(*) FILTER (WHERE TRIM(net_revenue) !~ '^-?[0-9]+(\.[0-9]+)?$')         AS bad_revenue,
	COUNT(*) FILTER (WHERE TRIM(year) !~ '^[0-9]{4}$')                         AS bad_year,
	COUNT(*) FILTER (WHERE customer_email IS NULL OR TRIM(customer_email) = '') AS blank_email
FROM
	raw.casestudy;
-- Result: 0 / 0 / 0 -> every row is safe to cast

-- 6. Profile by year: duplicates per customer, revenue range, totals.
SELECT
	TRIM(year)                              AS year,
	COUNT(*)                                AS row_count,
	COUNT(DISTINCT TRIM(customer_email))    AS distinct_customers,
	MIN(TRIM(net_revenue)::numeric)         AS min_revenue,
	MAX(TRIM(net_revenue)::numeric)         AS max_revenue,
	SUM(TRIM(net_revenue)::numeric)         AS total_revenue
FROM
	raw.casestudy
GROUP BY
	TRIM(year)
ORDER BY
	year;
-- Result:
--   year | rows    | distinct customers | min  | max    | total revenue
--   2015 | 231,294 | 231,294            | 1.00 | 250.00 | 29,036,749.19
--   2016 | 204,646 | 204,646            | 1.00 | 250.00 | 25,730,943.59
--   2017 | 249,987 | 249,987            | 1.00 | 250.00 | 31,417,495.03
-- -> each customer appears at most once per year (after TRIM)
-- -> no zero or negative revenue
-- -> totals are the expected answer for metric 1 (Total Revenue)
