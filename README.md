# Customer Revenue Analysis: Stout Case Study
Alexander Escobar · November 2026

## Links
- **Dashboard (Tableau Public):** https://public.tableau.com/app/profile/alexander.escobar3374/viz/Stout_Case_Study_17949851978610/CoverPage
- **Architecture notes:** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## The question
How did revenue and the customer base change from 2015 to 2017? For each year, the analysis
calculates 10 metrics (one SQL query each) and splits revenue into new, returning and lost
customers to show what drove growth and what held it back.

## Key findings
1. **Revenue followed customer turnover.** In 2016, revenue lost from departing customers ($20.55M) outweighed revenue from new customers ($17.21M), and total revenue fell 11.4%. In 2017, new customers ($21.77M) outweighed lost ($16.15M), and revenue rose 22.1% to $31.42M.
2. **Returning customers barely changed their spending.** Customers present in both 2016 and 2017 spent $63.9K (+0.7%) more in 2017. Almost all of the revenue movement came from customers arriving and leaving.
3. **Most customers do not return.** Retention improved from 29.3% (2016) to 37.4% (2017), but 62.6% of 2016's customers (128,108) did not buy again in 2017.

## Results
| Metric | 2015 | 2016 | 2017 |
|---|---|---|---|
| 1. Total Revenue | $29,036,749.19 | $25,730,943.59 | $31,417,495.03 |
| 2. New Customer Revenue | N/A | $17,206,366.90 | $21,769,213.01 |
| 3. Existing Customer Growth | N/A | $39,043.65 | $63,857.06 |
| 4. Revenue Lost from Attrition | N/A | $20,551,216.15 | $16,146,518.63 |
| 5. Existing Customer Revenue, Current Year | N/A | $8,524,576.69 | $9,648,282.02 |
| 6. Existing Customer Revenue, Prior Year | N/A | $8,485,533.04 | $9,584,424.96 |
| 7. Total Customers, Current Year | 231,294 | 204,646 | 249,987 |
| 8. Total Customers, Previous Year | N/A | 231,294 | 204,646 |
| 9. New Customers | N/A | 136,891 | 173,449 |
| 10. Lost Customers | N/A | 163,539 | 128,108 |

2015 is the first year in the data, so only metrics 1 and 7 apply to it (confirmed with Stout).

## Definitions
| Term | Definition |
|---|---|
| New customer (year Y) | Present in Y, not present in Y-1 |
| Existing customer (year Y) | Present in both Y-1 and Y |
| Lost customer (year Y) | Present in Y-1, not present in Y |
| Revenue lost from attrition | Lost customers' revenue in Y-1 (confirmed with Stout) |
| Existing customer growth | Existing customers' revenue in Y minus their own revenue in Y-1 |

Years are compared only with the year directly before. A customer who bought in 2015, skipped
2016 and returned in 2017 counts as lost in 2016 and new in 2017.

**Ratios added for the dashboard** (not among the 10 required metrics):
- Retention rate = existing customers ÷ previous year's customers
- Attrition rate = lost customers ÷ previous year's customers
- Revenue growth % = (this year's revenue − last year's revenue) ÷ last year's revenue
- New revenue share = new customer revenue ÷ total revenue

## Assumptions and data notes
- **Load:** 685,927 rows loaded, matching the file. Every column was loaded as text, so nothing was rounded or trimmed before inspection. (A GUI import had guessed revenue as a floating-point type, which rounds money, so the table is created by hand in `00_load_raw.sql`.)
- **Whitespace in customer IDs:** 270,214 rows (39.4%) had a leading (228,643) or trailing (41,571) space in `customer_email`; none had both, and no other whitespace remained after `TRIM`. Assumption: `" abc"`, `"abc "` and `"abc"` are the same customer. Without this fix, a returning customer would be counted as both lost and new.
- **One row per customer per year:** after trimming, row count equals distinct customers in every year, so year-over-year joins cannot double-count.
- **Revenue values:** all between $1.00 and $250.00, no zero or negative values (no refunds or credits to handle), at most two decimals. Stored as `numeric(10,2)` for exact cents.
- **Matched groups:** existing customer revenue (prior year) for 2017 covers customers present in both 2016 and 2017, so it differs from 2016's existing revenue (current year), which covers customers present in both 2015 and 2016.

## How the numbers were checked
Each metric is its own query, so `sql/05_checks.sql` tests that they agree for 2016 and 2017.
All 10 checks return a difference of exactly 0:
1. Total revenue = new customer revenue + existing customer revenue (current year)
2. Existing customer growth = existing revenue (current) − existing revenue (prior)
3. Total customers (current) = new customers + existing customers
4. Total customers (prior) = lost customers + existing customers
5. Previous year's revenue = revenue lost from attrition + existing revenue (prior)

The revenue bridge on the dashboard closes exactly (previous-year revenue + new + growth − lost = current-year revenue) because of checks 1 and 5.

## The dashboard
| Page | What it shows |
|---|---|
| **Cover page** | The question, navigation to both dashboards, and how the analysis was built |
| **Revenue & Customer Overview** | All 10 metrics for the year chosen in the **Reporting Year** selector, a revenue bridge (waterfall) from the previous year, and where the year's revenue came from (new vs existing) |
| **Growth & Retention Trends** | Three-year trends: revenue, new vs existing revenue, customers gained vs lost, and retention vs attrition |

### Why each display
| Display | Chosen because |
|---|---|
| **KPI cards** | Single numbers are read fastest as large text. Each card adds one line of context (vs the previous year, share of revenue, or "N/A (first year)") so a number never appears without meaning. |
| **Revenue bridge (waterfall)** | Shows the full path from last year's revenue to this year's: what was added and what was lost. It is the standard way to explain a change in revenue, and it visualises the reconciliation checks. |
| **Donut (revenue composition)** | Two parts of one whole for one year, with the total in the centre. |
| **Line chart (revenue trend)** | Three points in time. The axis starts at $0 so the 2016 dip is not exaggerated. |
| **Stacked bars (new vs existing revenue)** | Shows each year's total and how it splits in one bar. |
| **Diverging bars (customer movement)** | Lost customers to the left of zero and new customers to the right make the net direction of each year visible at a glance. |
| **100% bars (retention vs attrition)** | Each bar is the previous year's customer base, so retained + lost always equals 100%. |

### Colours
| Colour | Hex | Used for |
|---|---|---|
| Navy | `#093B5D` | Headers, totals, existing/retained customers, main numbers |
| Blue | `#1D9AD6` | Revenue line, accents, links |
| Green | `#8DC63F` | New customers, retained share, growth |
| Red | `#D9272D` | Lost customers, attrition, revenue lost |
| Light grey | `#F4F6FA` | Dashboard background behind white cards |

The same category always has the same colour on every chart, and each chart carries its own colour key.

## Repository
| Path | Purpose |
|---|---|
| `sql/00_load_raw.sql` | Creates `raw.casestudy` (all text) and loads the CSV with `COPY` |
| `sql/01_data_checks.sql` | Data quality checks on the raw table |
| `sql/02_clean.sql` | `clean.customer_revenue`: trimmed IDs, numeric revenue, integer year |
| `sql/03_metrics.sql` | The 10 metrics, one query each, saved as views |
| `sql/04_summary.sql` | `metrics.yearly_summary`: one row per year with all 10 metrics |
| `sql/05_checks.sql` | Consistency checks across the metrics |
| `sql/06_revenue_bridge.sql` | `metrics.revenue_bridge`: one row per bar of the waterfall |
| `Tableau/Stout_Case_Study.twbx` | Packaged Tableau workbook (includes the data extracts and images) |
| `docs/ARCHITECTURE.md` | Where each calculation lives and why |

## How to reproduce
1. Install PostgreSQL. Create the database and schema:
   ```sql
   CREATE DATABASE stout_case;
   ```
2. Copy `casestudy.csv` to `C:\Users\Public\` (the PostgreSQL server process must be able to read it), or edit the path in `00_load_raw.sql`.
3. Run the files in `sql/` in numbered order (`00` to `06`). `01` and `05` print their checks; every check should match the results noted in the file.
4. Open `Tableau/Stout_Case_Study.twbx` in Tableau Desktop or Tableau Desktop Public Edition. It opens without a database, using the packaged extracts.
5. To rebuild from your own database instead: edit each data source's connection to point at your PostgreSQL server and refresh the extracts.
6. To publish: in Tableau Desktop Public Edition, **File → Save to Tableau Public As…** (Tableau Public uses the extracts; it cannot connect to a local database).

## Improvements with more time
- **Colour-blind-safe palette:** green vs red is the most common colour-blindness pair. Swapping green for a blue-family colour would make every chart readable without relying on hue.
- **Load time:** the published workbook takes several seconds to open. Smaller images and fewer worksheets on the Overview (the 10 KPI cards are 10 separate sheets) would speed it up.
- **Web-safe fonts everywhere:** Tableau Public replaces fonts it cannot serve, so a few titles render in a fallback font.
- **A dynamic key finding** that changes with the selected year, instead of a fixed sentence.
- **Automation:** a single script that runs the SQL files in order, exports the summary tables and fails loudly if any check is non-zero.
- **Customer-level detail:** with customer attributes (region, segment, first purchase date), the analysis could show *who* is being lost, not just how many.

## Tools
PostgreSQL 18 (DBeaver), Tableau Desktop, Tableau Desktop Public Edition, Git/GitHub.
AI assistance: I used Claude (Anthropic) as a reviewer throughout. I wrote the SQL and built the
dashboard myself; Claude reviewed and cleaned up my queries, independently recalculated every
metric from the raw CSV to confirm my results, suggested Tableau calculated field formulas and
chart techniques, and drafted the README and architecture notes, which I reviewed and edited.