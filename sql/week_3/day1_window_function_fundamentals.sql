-- DAY 1
-- BLOCK 1:

-- 1. Write a query attaching the overall average station capacity to every row using `AVG(capacity) OVER ()`, and compare it to your Week 1 scalar-subquery version of the same thing.

SELECT
  short_name,
  name,
  capacity,
  AVG(capacity) OVER () AS overall_avg_capacity
FROM station;

-- 2. Add `ROW_NUMBER() OVER (ORDER BY capacity DESC)` to the same query, numbering every station from highest to lowest capacity.

SELECT
  short_name,
  name,
  capacity,
  AVG(capacity) OVER ()                AS overall_avg_capacity,
  RANK() OVER (ORDER BY capacity DESC) AS capacity_rank
FROM station;

-- 3. Confirm that removing the `ORDER BY` inside `OVER()` still runs without erroring, but produces row numbers in a database-determined, unreliable order. Note what you observe.

SELECT
  short_name,
  name,
  capacity,
  AVG(capacity) OVER ()                AS overall_avg_capacity,
  RANK() OVER ()                       AS capacity_rank
FROM station;

--We have all Rank's equal 1

-- 4. Use `ROW_NUMBER()` to number stations by capacity ascending instead of descending, and confirm the numbers reverse as expected.

SELECT
  short_name,
  name,
  capacity,
  AVG(capacity) OVER ()                AS overall_avg_capacity,
  RANK() OVER (ORDER BY capacity ASC)  AS capacity_rank
FROM station;

-- 5. Combine two window functions in one query: `ROW_NUMBER()` for rank and `AVG(capacity) OVER ()` for the overall average, both alongside the raw station data.

SELECT
  short_name,
  name,
  capacity,
  AVG(capacity) OVER ()                      AS overall_avg_capacity,
  ROW_NUMBER() OVER (ORDER BY capacity DESC) AS row_num
FROM station;

-- BLOCK 2:
-- 1. Find (or construct, if none exist naturally) a set of stations that tie on capacity, and run `ROW_NUMBER()`, `RANK()`, and `DENSE_RANK()` side by side over the same `ORDER BY`.

SELECT
  short_name,
  name,
  capacity,
  ROW_NUMBER() OVER (ORDER BY capacity DESC) AS row_num,
  RANK() OVER (ORDER BY capacity DESC)       AS rank_num,
  DENSE_RANK() OVER (ORDER BY capacity DESC) AS dense_rank_num
FROM station
ORDER BY capacity DESC;


-- 2. Confirm directly, from the output, that `ROW_NUMBER()` breaks the tie arbitrarily while `RANK()` and `DENSE_RANK()` both assign the same value to tied rows.
-- 3. Confirm directly that `RANK()` skips a number after a tie while `DENSE_RANK()` doesn't — find the specific row where the two diverge and explain why in a sentence.
---- After the tie at rank 3 (two stations with capacity 47), RANK() counts those two tied rows toward the running total and jumps to 5 for the next distinct value, while DENSE_RANK() ignores the tie's row-count and simply increments to the next integer 4. 
---- So RANK() leaves a "gap" (skips rank 4 entirely) and DENSE_RANK() never does.

-- 4. Apply `RANK()` to `stations_summary`, ranking stations by `total_rides` descending, and pull just the top 5 ranks.

SELECT
    ID_station,
    station_name,
    total_rides,
    RANK() OVER (ORDER BY total_rides DESC) AS rank_num
  FROM stations_summary
LIMIT 5;

-- 5. Decide which of the three functions is actually correct for a "top 5 busiest stations" report if there's a tie for 5th place — would you want 5 rows, 6, or something else — and pick the function that produces that behavior.
--- `DENSE_RANK()` is more accure for this in case when we have stations with equal total_rides we miss minimum one row in result with `RANK()`

-- 6. Try using `RANK()` or `DENSE_RANK()` results directly in a `WHERE` clause (for example, `WHERE rank_num <= 5`) and confirm you get an error — window functions can't be filtered directly in the same query level they're computed in.

--- Binder Error: WHERE clause cannot contain window functions!
---  LINE 5:     RANK() OVER (ORDER BY total_rides DESC) AS rank_num

-- 7. Fix the Task 6 error by wrapping the window function query in a subquery or CTE and filtering in the outer query instead. Note that this is the same pattern Day 1, Week 3's concepts file used for "top N per group."

WITH ranked AS (
SELECT
    ID_station,
    station_name,
    total_rides,
    RANK() OVER (ORDER BY total_rides DESC) AS rank_num
  FROM stations_summary
)
SELECT *
FROM ranked
WHERE rank_num <= 5
ORDER BY rank_num ASC;

-- BLOCK 3:

-- 1. Rewrite the neighborhood-average-capacity query from the concepts file yourself, using `AVG(capacity) OVER (PARTITION BY neighborhood)`.

SELECT
  short_name,
  name,
  neighborhood,
  capacity,
  AVG(capacity) OVER (PARTITION BY neighborhood) AS neighborhood_avg_capacity
FROM station;

-- 2. Add a column computing the difference between each station's capacity and its neighborhood's average, using the `PARTITION BY` result directly in the same `SELECT`.

SELECT
  short_name,
  name,
  neighborhood,
  capacity,
  ROUND(AVG(capacity) OVER (PARTITION BY neighborhood),0)            AS neighborhood_avg_capacity,
  ROUND(capacity - neighborhood_avg_capacity,0)                      AS Difference_to_neighborhood
FROM station;

-- 3. Rebuild Week 1, Day 4, Block 4's "stations above their neighborhood average" — this time using `PARTITION BY` and a `WHERE` clause on a wrapped subquery, instead of the correlated subquery version from that day.

WITH avg_capacity AS (
SELECT
  short_name,
  name,
  neighborhood,
  capacity,
  ROUND(AVG(capacity) OVER (PARTITION BY neighborhood),0)            AS neighborhood_avg_capacity,
  ROUND(capacity - neighborhood_avg_capacity,0)                      AS Difference_to_neighborhood
FROM station)
  SELECT * FROM avg_capacity AS a
WHERE a.Difference_to_neighborhood > 0;

-- 4. Rebuild Week 2, Day 2, Block 4's mini-project ("busiest station per neighborhood") using `ROW_NUMBER() OVER (PARTITION BY neighborhood ORDER BY total_rides DESC)` and a filter for `rn = 1`.

WITH station_totals AS (
    SELECT 
        COALESCE(s.neighborhood, 'unknown')  AS neighborhood,
        t.start_station_id                   AS station_id,
        t.start_station                      AS station_name,
        s.capacity                           AS station_capacity,
        COUNT(t.bike_id)                     AS total_rides,
        ROW_NUMBER() 
          OVER (PARTITION BY neighborhood
                 ORDER BY total_rides DESC) AS rank
    FROM trips              AS t
  
    -- Connecting to the neighborhood data ----
    LEFT JOIN station       AS s
           ON t.start_station_id = s.short_name
    -------------------------------------------
    WHERE t.start_station_id IS NOT NULL -- Filter out data without Start station info
      AND t.end_time > t.start_time      -- Filter out data witho negative duration
      AND (date_part('epoch', t.end_time - t.start_time) / 60) BETWEEN 1 AND 1440 -- Filter out duration more 24 hours and false unlocks (less 1 minute)
    GROUP BY s.neighborhood, t.start_station_id, t.start_station, s.capacity
)

SELECT * 
  FROM station_totals
    WHERE rank=1
ORDER BY total_rides DESC;

-- 5. Compare your window-function version of Task 4 against the three-stage chained-CTE version you built in Week 2. Which one would you rather maintain?
--  I would you rather maintain window-function version it's much easier.

-- 6. Try partitioning by two columns at once (for example, `PARTITION BY neighborhood, rider_type` if that combination makes sense against your joined data), and confirm each unique combination gets its own window.

WITH station_totals AS (
    SELECT 
        COALESCE(s.neighborhood, 'unknown')  AS neighborhood,
        t.start_station_id                   AS station_id,
        t.start_station                      AS station_name,
        t.rider_type                         AS rider_type,
        s.capacity                           AS station_capacity,
        COUNT(t.bike_id)                     AS total_rides,
        ROW_NUMBER() 
          OVER (PARTITION BY neighborhood, rider_type
                 ORDER BY total_rides DESC) AS rank
    FROM trips              AS t
  
    -- Connecting to the neighborhood data ----
    LEFT JOIN station       AS s
           ON t.start_station_id = s.short_name
    -------------------------------------------
    WHERE t.start_station_id IS NOT NULL -- Filter out data without Start station info
      AND t.end_time > t.start_time      -- Filter out data witho negative duration
      AND (date_part('epoch', t.end_time - t.start_time) / 60) BETWEEN 1 AND 1440 -- Filter out duration more 24 hours and false unlocks (less 1 minute)
    GROUP BY s.neighborhood, t.start_station_id, t.start_station, t.rider_type, s.capacity
)

SELECT * 
  FROM station_totals
    WHERE rank=1
ORDER BY neighborhood ASC, total_rides DESC;


-- 7. Write a query with two different `PARTITION BY` window functions in the same `SELECT` — one partitioned by neighborhood, one partitioned by rider type — and confirm both work independently in the same result set.

WITH station_totals AS (
    SELECT 
        COALESCE(s.neighborhood, 'unknown')  AS neighborhood,
        t.start_station_id                   AS station_id,
        t.start_station                      AS station_name,
        t.rider_type                         AS rider_type,
        s.capacity                           AS station_capacity,
        COUNT(t.bike_id)                     AS total_rides,
        ROW_NUMBER() 
          OVER (PARTITION BY neighborhood
                 ORDER BY total_rides DESC) AS rank_neighborhood,
        ROW_NUMBER() 
          OVER (PARTITION BY rider_type
                 ORDER BY total_rides DESC) AS rank_rider_type
    FROM trips              AS t
  
    -- Connecting to the neighborhood data ----
    LEFT JOIN station       AS s
           ON t.start_station_id = s.short_name
    -------------------------------------------
    WHERE t.start_station_id IS NOT NULL -- Filter out data without Start station info
      AND t.end_time > t.start_time      -- Filter out data withot negative duration
      AND (date_part('epoch', t.end_time - t.start_time) / 60) BETWEEN 1 AND 1440 -- Filter out duration more 24 hours and false unlocks (less 1 minute)
    GROUP BY s.neighborhood, t.start_station_id, t.start_station, t.rider_type, s.capacity
)

SELECT * 
  FROM station_totals
ORDER BY neighborhood ASC, station_id DESC;

-- BLOCK 4:

-- 1. Rebuild the daily time series from Week 2, Day 4, and add `LAG(total_rides) OVER (ORDER BY calendar_date)` to pull each day's previous value.
WITH date_range AS (
  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date
),
daily_rides AS (
  SELECT DATE_TRUNC('day', start_time)::DATE   AS ride_date,
         COUNT(bike_id)                        AS total_rides
  FROM trips
  GROUP BY DATE_TRUNC('day', start_time)::DATE
),
daily_series AS (
  SELECT 
    strftime(dr.calendar_date, '%d/%m/%Y')     AS calendar_date,
    dr.calendar_date                           AS calendar_date_raw,
    COALESCE(d.total_rides, 0)                 AS total_rides
  FROM date_range                              AS dr
  LEFT JOIN daily_rides                        AS d
         ON dr.calendar_date = d.ride_date
)
SELECT
  calendar_date,
  total_rides,
  LAG(total_rides) OVER (ORDER BY calendar_date_raw)          AS previous_day_rides
FROM daily_series
ORDER BY calendar_date_raw;




-- 2. Compute the day-over-day change as `total_rides - LAG(total_rides) OVER (ORDER BY calendar_date)`, and compare the result directly against your Week 2, Day 4 self-join version.

WITH date_range AS (
  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date
),
daily_rides AS (
  SELECT DATE_TRUNC('day', start_time)::DATE   AS ride_date,
         COUNT(bike_id)                        AS total_rides
  FROM trips
  GROUP BY DATE_TRUNC('day', start_time)::DATE
),
daily_series AS (
  SELECT 
    strftime(dr.calendar_date, '%d/%m/%Y')     AS calendar_date,
    dr.calendar_date                           AS calendar_date_raw,
    COALESCE(d.total_rides, 0)                 AS total_rides
  FROM date_range                              AS dr
  LEFT JOIN daily_rides                        AS d
         ON dr.calendar_date = d.ride_date
)
SELECT
  calendar_date,
  total_rides,
  LAG(total_rides) OVER (ORDER BY calendar_date_raw)          AS previous_day_rides,
  total_rides - LAG(total_rides) OVER (ORDER BY calendar_date_raw) AS day_over_day_change
FROM daily_series
ORDER BY calendar_date_raw;

-- 3. Use `LEAD()` instead of `LAG()` to compute the *next* day's ride count alongside each row, and confirm the values shift in the opposite direction from `LAG()`.

WITH date_range AS (
  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date
),
daily_rides AS (
  SELECT DATE_TRUNC('day', start_time)::DATE   AS ride_date,
         COUNT(bike_id)                        AS total_rides
  FROM trips
  GROUP BY DATE_TRUNC('day', start_time)::DATE
),
daily_series AS (
  SELECT 
    strftime(dr.calendar_date, '%d/%m/%Y')     AS calendar_date,
    dr.calendar_date                           AS calendar_date_raw,
    COALESCE(d.total_rides, 0)                 AS total_rides
  FROM date_range                              AS dr
  LEFT JOIN daily_rides                        AS d
         ON dr.calendar_date = d.ride_date
)
SELECT
  calendar_date,
  total_rides,
  LAG(total_rides) OVER (ORDER BY calendar_date_raw)          AS previous_day_rides,
  LEAD(total_rides) OVER (ORDER BY calendar_date_raw)         AS next_day_rides
FROM daily_series
ORDER BY calendar_date_raw;

-- 4. Use `LAG(total_rides, 7)` to compare each day to the same day one week earlier, replacing the modified self-join from Week 2, Day 4, Block 3, Task 4.
WITH date_range AS (
  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date
),
daily_rides AS (
  SELECT DATE_TRUNC('day', start_time)::DATE   AS ride_date,
         COUNT(bike_id)                        AS total_rides
  FROM trips
  GROUP BY DATE_TRUNC('day', start_time)::DATE
),
daily_series AS (
  SELECT 
    strftime(dr.calendar_date, '%d/%m/%Y')     AS calendar_date,
    dr.calendar_date                           AS calendar_date_raw,
    COALESCE(d.total_rides, 0)                 AS total_rides
  FROM date_range                              AS dr
  LEFT JOIN daily_rides                        AS d
         ON dr.calendar_date = d.ride_date
)
SELECT
  calendar_date,
  total_rides,
  LAG(total_rides,7) OVER (ORDER BY calendar_date_raw)          AS previous_week_rides
FROM daily_series
ORDER BY calendar_date_raw;

-- 5. Add a default value as the third argument to one of your `LAG()` calls (for example, `LAG(total_rides, 1, 0)`), and confirm the very first row now shows `0` instead of `NULL`.

WITH date_range AS (
  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date
),
daily_rides AS (
  SELECT DATE_TRUNC('day', start_time)::DATE   AS ride_date,
         COUNT(bike_id)                        AS total_rides
  FROM trips
  GROUP BY DATE_TRUNC('day', start_time)::DATE
),
daily_series AS (
  SELECT 
    strftime(dr.calendar_date, '%d/%m/%Y')     AS calendar_date,
    dr.calendar_date                           AS calendar_date_raw,
    COALESCE(d.total_rides, 0)                 AS total_rides
  FROM date_range                              AS dr
  LEFT JOIN daily_rides                        AS d
         ON dr.calendar_date = d.ride_date
)
SELECT
  calendar_date,
  total_rides,
  LAG(total_rides,7,0) OVER (ORDER BY calendar_date_raw)          AS previous_week_rides
FROM daily_series
ORDER BY calendar_date_raw;

-- 6. Use `LAG()` combined with `PARTITION BY` — for example, comparing each station's ride count to its own previous period, partitioned by station, if you build a per-station daily series. Confirm the partition boundary correctly resets what counts as "previous."

WITH date_range AS (
  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date
),
daily_rides AS (
  SELECT DATE_TRUNC('day', start_time)::DATE   AS ride_date,
         COALESCE(start_station_id, 'unknown') AS station_id,
         COALESCE(start_station, 'unknown')    AS station,
         COUNT(bike_id)                        AS total_rides
  FROM trips
  GROUP BY ride_date, station_id, station 
),
daily_series AS (
  SELECT 
    strftime(dr.calendar_date, '%d/%m/%Y')     AS calendar_date,
    dr.calendar_date                           AS calendar_date_raw,
    COALESCE(d.station_id, 'unknown')          AS station_id,
    COALESCE(d.station, 'unknown')             AS station,
    COALESCE(d.total_rides, 0)                 AS total_rides
  FROM date_range                              AS dr
  LEFT JOIN daily_rides                        AS d
         ON dr.calendar_date = d.ride_date
)
SELECT
  calendar_date,
  station_id,
  station,
  total_rides,
  LAG(total_rides,1,0) OVER (
    PARTITION BY station_id
    ORDER BY calendar_date_raw
  )                                              AS previous_day_rides,
  total_rides - LAG(total_rides,1,0) OVER (
    PARTITION BY station_id
    ORDER BY calendar_date_raw
  )                                              AS day_over_day_change
FROM daily_series
WHERE station_id = '31623'
ORDER BY calendar_date_raw;

-- 7. Find the largest single day-over-day increase and decrease using your `LAG()`-based query, and confirm the results match what you found in Week 2, Day 4 using the self-join.

WITH date_range AS (
  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date
),
daily_rides AS (
  SELECT DATE_TRUNC('day', start_time)::DATE   AS ride_date,
         COUNT(bike_id)                        AS total_rides
  FROM trips
  GROUP BY DATE_TRUNC('day', start_time)::DATE
),
daily_series AS (
  SELECT 
    strftime(dr.calendar_date, '%d/%m/%Y')     AS calendar_date,
    dr.calendar_date                           AS calendar_date_raw,
    COALESCE(d.total_rides, 0)                 AS total_rides
  FROM date_range                              AS dr
  LEFT JOIN daily_rides                        AS d
         ON dr.calendar_date = d.ride_date
),
day_over_day_change AS (
  SELECT
    calendar_date,
    calendar_date_raw,
    total_rides,
    LAG(total_rides, 1, 0) OVER (ORDER BY calendar_date_raw)              AS previous_day_rides,
    total_rides - LAG(total_rides, 1, 0) OVER (ORDER BY calendar_date_raw) AS day_over_day_change
  FROM daily_series
)
SELECT
  calendar_date,
  total_rides,
  previous_day_rides,
  day_over_day_change
FROM (
  SELECT
    *,
    MAX(day_over_day_change) OVER () AS max_change,
    MIN(day_over_day_change) OVER () AS min_change
  FROM day_over_day_change
) t
WHERE day_over_day_change = max_change
   OR day_over_day_change = min_change
ORDER BY calendar_date_raw;


-- 8. Write a sentence comparing how confident you feel in the `LAG()` version versus the self-join version — which one would you trust more if you found it in someone else's code six months from now, and why?

---- I'd trust the LAG() version more a self join on calendar_date_raw = calendar_date_raw + INTERVAL '1 day' makes me stop and manually verify the join direction and date arithmetic before I believe it's correct, 
---- while LAG(total_rides) OVER (ORDER BY calendar_date_raw) states its intent in the syntax itself ("previous row in this order"), leaving far less room for a subtle off by one or join explosion bug to hide.

-- BLOCK 5:

-- 1. Take your full Week 2, Day 4 anomaly-detection pipeline — daily series, gap detection, period comparison, and statistical flagging — and rebuild the period-comparison portion entirely with `LAG()`.

WITH date_range AS (
  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date
),
daily_rides AS (
  SELECT DATE_TRUNC('day', start_time)::DATE AS ride_date,
         COUNT(bike_id)                      AS total_rides
  FROM trips
  GROUP BY DATE_TRUNC('day', start_time)::DATE
),
daily_series AS (
  SELECT
    strftime(dr.calendar_date, '%d/%m/%Y')   AS calendar_date,
    dr.calendar_date                         AS calendar_date_raw,
    COALESCE(d.total_rides, 0)               AS total_rides
  FROM date_range AS dr
  LEFT JOIN daily_rides AS d
    ON dr.calendar_date = d.ride_date
)
SELECT
  calendar_date,
  total_rides,
  COALESCE(LAG(total_rides) OVER (ORDER BY calendar_date_raw), 0)           AS previous_day_rides,
  total_rides - COALESCE(LAG(total_rides) OVER (ORDER BY calendar_date_raw), 0) AS day_over_day_change
FROM daily_series
ORDER BY calendar_date_raw;

-- 2. Rebuild the trailing 7-day moving average from Week 2, Day 4's correlated subquery using a window function instead: `AVG(total_rides) OVER (ORDER BY calendar_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)`. (This frame syntax is a preview of Day 2 — try it now and don't worry if it's not fully clear yet.)
WITH date_range AS (
  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date
),
daily_rides AS (
  SELECT DATE_TRUNC('day', start_time)::DATE   AS ride_date,
         COUNT(bike_id)                        AS total_rides
  FROM trips
  GROUP BY DATE_TRUNC('day', start_time)::DATE
),
daily_series AS (
  SELECT 
    strftime(dr.calendar_date, '%d/%m/%Y')     AS calendar_date,
    dr.calendar_date                           AS calendar_date_raw,
    COALESCE(d.total_rides, 0)                 AS total_rides
  FROM date_range                              AS dr
  LEFT JOIN daily_rides                        AS d
         ON dr.calendar_date = d.ride_date
),
trailing_avg AS (
  SELECT
    calendar_date_raw,
    ROUND(
      AVG(total_rides) OVER (
        ORDER BY calendar_date_raw
        ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
      ), 0
    ) AS trailing_7d_avg
  FROM daily_series
),
curent_to_previous_comparison AS (
  SELECT
    today.calendar_date,
    today.calendar_date_raw,
    today.total_rides,
    t.trailing_7d_avg,
    today.total_rides - t.trailing_7d_avg AS diff_from_7d_avg
  FROM daily_series AS today
  LEFT JOIN trailing_avg AS t
         ON today.calendar_date_raw = t.calendar_date_raw
)
SELECT
  calendar_date,
  total_rides,
  trailing_7d_avg,
  diff_from_7d_avg
  FROM curent_to_previous_comparison
ORDER BY calendar_date_raw;

-- 3. Compare the moving-average results from Task 2 against your original Week 2, Day 4 correlated-subquery version, row for row, to confirm they match.

WITH date_range AS (
  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date
),
daily_rides AS (
  SELECT DATE_TRUNC('day', start_time)::DATE AS ride_date,
         COUNT(bike_id)                      AS total_rides
  FROM trips
  GROUP BY DATE_TRUNC('day', start_time)::DATE
),
daily_series AS (
  SELECT
    strftime(dr.calendar_date, '%d/%m/%Y')   AS calendar_date,
    dr.calendar_date                         AS calendar_date_raw,
    COALESCE(d.total_rides, 0)               AS total_rides
  FROM date_range AS dr
  LEFT JOIN daily_rides AS d
    ON dr.calendar_date = d.ride_date
),
-- original correlated-subquery-style version (self-join, excludes today)
subquery_version AS (
  SELECT
    today.calendar_date_raw,
    today.calendar_date,  
    ROUND(AVG(prev.total_rides), 0) AS trailing_7d_avg_old
  FROM daily_series AS today
  LEFT JOIN daily_series AS prev
    ON prev.calendar_date_raw BETWEEN today.calendar_date_raw - INTERVAL '7 days'
                                   AND today.calendar_date_raw - INTERVAL '1 day'
  GROUP BY today.calendar_date_raw, today.calendar_date
),
-- window function version, matched to same "exclude today" definition
window_version AS (
  SELECT
    calendar_date_raw,
    calendar_date, 
    ROUND(
      AVG(total_rides) OVER (
        ORDER BY calendar_date_raw
        ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
      ), 0
    ) AS trailing_7d_avg_new
  FROM daily_series
)
SELECT
  w.calendar_date,
  s.trailing_7d_avg_old,
  w.trailing_7d_avg_new,
  s.trailing_7d_avg_old - w.trailing_7d_avg_new AS diff
FROM window_version AS w
JOIN subquery_version AS s
  ON w.calendar_date_raw = s.calendar_date_raw

ORDER BY w.calendar_date_raw;

-- 4. Note, specifically, whether the window-function version ran noticeably faster than the correlated-subquery version on the full seven-year dataset, if your tool shows query timing.
--- 286 ms vs 284 ms now 

-- 5. Leave the statistical z-score flagging from Week 2, Day 4 as-is for now — it doesn't need a window function, and Day 2 will revisit whether any part of it could still benefit from one.

--- Confirmed, no changes to Block 4's z-score/CASE WHEN logic. It's already a clean aggregate-and-join pattern (stats CTE CROSS JOIN'd back onto daily_series), 
--- and there's no natural "previous row" or "frame" concept it needs — the mean/stddev are single scalars over the whole set (or per month, in Block 4 Task 4), 
--- not a per-row lookback. Worth flagging for your own notes, though: AVG(...) OVER () and STDDEV(...) OVER () could replace the stats CTE + CROSS JOIN pattern with zero rows returned differently — same result, 
---  one less CTE — which is likely what Day 2 will point at. That's a syntactic simplification, not a behavior change, so it's fair to leave for later as noted.

-- Reporter : Serhiy Dranko
-- Date : 2026-08-03
