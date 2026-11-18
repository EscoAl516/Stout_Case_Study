# Architecture

How data moves from the CSV to the dashboard, where each calculation lives, and why.

## Pipeline
```
casestudy.csv (685,927 rows)
   │  COPY, every column as text                       sql/00_load_raw.sql
   ▼
raw.casestudy ──── data quality checks                 sql/01_data_checks.sql
   │  TRIM, cast to numeric(10,2) / integer            sql/02_clean.sql
   ▼
clean.customer_revenue (one row per customer per year)
   │  one view per metric                              sql/03_metrics.sql
   ▼
metrics.m01_total_revenue … metrics.m10_lost_customers
   │  joined into one row per year                     sql/04_summary.sql
   ▼
metrics.yearly_summary ──── consistency checks         sql/05_checks.sql
metrics.revenue_bridge  (waterfall rows)               sql/06_revenue_bridge.sql
   │  Tableau extract (.hyper)
   ▼
Tableau workbook ──► Tableau Public
```

Three schemas keep the layers separate: `raw` is the file exactly as delivered, `clean` is the
corrected data, `metrics` holds results. Nothing downstream reads `raw`.

## Requirements
**Functional**
- Calculate the 10 required metrics for each year, one SQL query per metric.
- Only metrics 1 and 7 for 2015 (first year, no prior year to compare).
- Lost revenue = lost customers' revenue in the prior year.
- A dashboard on Tableau Public where the viewer can choose the year.
- SQL and the Tableau workbook in a public GitHub repository.

**Non-functional**
- **Exact money:** `numeric(10,2)`, never floating point.
- **Reproducible:** numbered scripts that rebuild everything from the CSV.
- **Verifiable:** the metrics must reconcile with each other (`05_checks.sql`, all differences 0).
- **Tableau Public constraint:** it cannot connect to a local PostgreSQL database, so the
  workbook ships with extracts of `yearly_summary` and `revenue_bridge`.

## Calculations in SQL (current design)
All business logic, meaning anything that decides who counts as new, existing or lost, lives in SQL.

| Object | Logic |
|---|---|
| `clean.customer_revenue` | `TRIM` on all columns; `net_revenue::numeric(10,2)`; `year::integer` |
| m01 Total Revenue | `SUM(net_revenue)` by year |
| m02 New Customer Revenue | Revenue of customers with `NOT EXISTS` in the prior year; first year excluded |
| m03 Existing Customer Growth | Self-join on customer, prior year; current minus prior revenue |
| m04 Revenue Lost from Attrition | Prior-year revenue of customers with `NOT EXISTS` in the following year; last year excluded |
| m05 / m06 Existing Revenue, current / prior | Same self-join as m03, each side summed separately |
| m07 Total Customers | `COUNT(DISTINCT customer_email)` by year |
| m08 Total Customers, Previous Year | `LAG` over m07's counts |
| m09 New Customers | Count of the m02 customer set |
| m10 Lost Customers | Count of the m04 customer set |
| `yearly_summary` | `LEFT JOIN` of all 10 views on year (2015 gets NULLs where a metric doesn't apply) |
| `revenue_bridge` | Five rows per year (prior total, +new, +growth, −lost, current total) with `bar_start` / `bar_end` precomputed |

## Calculations in Tableau
Tableau only does presentation: selecting a year, ratios of SQL results, and labels.
No customer-level logic is recalculated.

| Group | Fields | Purpose |
|---|---|---|
| Interactivity | Parameter `Reporting Year`; `Is Reporting Year`; `Is Reporting Year (bridge)` | Filter both data sources to the selected year |
| Ratios | `Retention Rate`, `Churn Rate`, `Revenue Growth %`, `New/Existing Revenue Share` | Divisions of SQL columns (e.g. retention = (prior customers − lost) ÷ prior customers) |
| Prior-year comparison | `Revenue Growth % (prev)`, `Retention Rate (prev)`, `Prior Year Label` | `LOOKUP(…, −1)` to compare with the year before; prior years are hidden, not filtered out, so `LOOKUP` can still see them |
| Labels | `Sub …` string fields, `Bar Label` | KPI subtitles and waterfall labels ("N/A (first year)" for 2015) |
| Chart mechanics | `Lost Customers (chart)` (negated for the diverging bar), `Bar Length` (waterfall Gantt size), `MIN(0)` ×2 (donut dual axis) | Make the chart types possible; no business meaning |

## Option evaluated: moving business logic into the dashboard
The alternative design connects Tableau directly to `clean.customer_revenue` (685,927 rows,
customer × year) and calculates the metrics there:

- Presence flags per customer with FIXED LOD expressions, e.g.
  `{FIXED [Customer Email] : MAX(IF [Year] = [Reporting Year] - 1 THEN 1 END)}`
- New / existing / lost status from those flags
- Metrics as `SUM([Net Revenue])` and `COUNTD([Customer Email])` filtered by status

| | Logic in SQL (current) | Logic in Tableau |
|---|---|---|
| Extract size | 3 + 10 rows | 685,927 rows |
| Load speed on Tableau Public | Fast | Slower (LOD expressions over every customer on each change of year) |
| Testing | Each metric is a query; reconciled by `05_checks.sql` | Harder to test; checks would have to be rebuilt as sheets |
| Single source of truth | Yes: SQL defines every number | Definitions split between SQL and Tableau |
| Flexibility | New breakdowns need new SQL | New breakdowns (e.g. by segment, if added) without SQL changes |

**Decision:** keep the business logic in SQL. The metrics are fixed, the data has no other
attributes to slice by, and the requirement is that each metric is a SQL query. Moving the logic
into Tableau would be worth it if the data gained customer attributes and viewers needed to
explore them. This option was evaluated and is not implemented.
