-- =============================================================
-- 01_data_checks.sql
-- Data quality checks on raw.casestudy (loaded from casestudy.csv
-- via DBeaver import, all columns as text, whitespace trim OFF).
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
-- Result: 270,214 rows


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
