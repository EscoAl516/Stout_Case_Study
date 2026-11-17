-- =============================================================
-- 00_load_raw.sql
-- Loads casestudy.csv into raw.casestudy, exactly as provided.
--
-- Why every column is text:
--   Nothing is converted on the way in, so no value is rounded,
--   trimmed or rejected before it has been inspected. A GUI import
--   guessed types (net_revenue as real, which rounds money), so the
--   table is created by hand instead. Casting happens later, in SQL.
-- =============================================================


-- 1. Create the raw table (drop first so the script can be re-run).
DROP TABLE IF EXISTS raw.casestudy;

CREATE TABLE raw.casestudy (
	idx            text,   -- blank header in the CSV (row index)
	customer_email text,   -- hashed customer ID
	net_revenue    text,
	year           text
);


-- 2. Load the file. CSV mode keeps leading/trailing spaces as-is;
--    HEADER true skips the first line.
COPY raw.casestudy
FROM 'C:\Users\Public\casestudy.csv'
WITH (FORMAT csv, HEADER true);


-- 3. Load check: rows in table vs rows in file.
SELECT COUNT(*) AS total_rows
FROM raw.casestudy;
-- Result: 685,927 (matches the file)
