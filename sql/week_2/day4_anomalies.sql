--- DAY 4
--- BLOCK 1:

-- 1. Build the daily ride-count time series from the concepts file, grouping `trips` by `DATE_TRUNC('day', start_time)`.
-- 2. Order it chronologically and scroll through at least a full year of it. Note anything that visually jumps out — a sharp drop, a sudden spike, an unusually flat stretch.

SELECT
  DATE_TRUNC('day', start_time)     AS ride_date,
  COUNT(*) AS total_rides
FROM trips
GROUP BY DATE_TRUNC('day', start_time)
ORDER BY ride_date;

SELECT
  strftime(start_time, '%d/%m/%Y')   AS ride_date,
  COUNT(*)                           AS total_rides
FROM trips
GROUP BY strftime(start_time, '%d/%m/%Y')
ORDER BY MIN(start_time);

-- Result of bouth queries 2738 rows 2 colums. Second one I think looks much prettier.

-- 3. Build the same time series at a weekly grain instead of daily, using your database's week-truncation function. Compare how much noisier the daily version looks next to the smoother weekly one.

SELECT
  DATE_TRUNC('week', start_time)     AS ride_week,
  COUNT(*) AS total_rides
FROM trips
GROUP BY DATE_TRUNC('week', start_time)
ORDER BY ride_week;

-- Result 392 rows 2 colums.

SELECT
  strftime(start_time, '%Y-%W')   AS ride_week,
  COUNT(*)                           AS total_rides
FROM trips
GROUP BY strftime(start_time, '%Y-%W')
ORDER BY MIN(start_time);

-- Result 398 rows 2 colums. Second one I think looks much prettier but need more time to find difference between bouth.

-- 4. Compute the overall minimum, maximum, and average daily ride count across all seven years.

SELECT
    MIN(ride_date)             AS min_daily_rides,
    MAX(ride_date)             AS max_daily_rides,
    ROUND(AVG(daily_rides), 1) AS avg_daily_rides

FROM (
    SELECT
        strftime(start_time, '%d/%m/%Y') AS ride_date,
        COUNT(bike_id)                   AS daily_rides
    FROM trips
    GROUP BY ride_date
);

-- 5. Filter the daily series to just 2020 and scan it specifically — this year is worth a closer look later in this task, given what was happening globally that year.

SELECT
  strftime(start_time, '%d/%m/%Y')   AS ride_date,
  COUNT(*)                           AS total_rides
FROM trips
WHERE strftime(start_time,'%Y') = '2020'
GROUP BY strftime(start_time, '%d/%m/%Y')
ORDER BY MIN(start_time);

--- First 2020 (and 2024 too) have 366 days in the year. Second is in 2020 in the end of March we went from trips_legacy to the trips_modern.

-- 6. Write one or two sentences on what you noticed just from looking, before running any statistical flagging — first impressions are worth recording before they get replaced by the formal analysis.

--- BLOCK 2:

-- 1. Build the full calendar-date range for your dataset using `generate_series` (or your engine's equivalent), from the earliest to the latest date in `trips`.

SELECT 
    generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    interval '1 day'
  ) AS calendar_date;

-- result more like item box. and when we start use them we have
--- Conversion Error: Unimplemented type for cast (DATE -> TIMESTAMP[]) when casting from source column ride_date
--- LINE 15: LEFT JOIN daily_rides d ON dr.calendar_date = d.ride_date
--- So I've creaate other variant with UNNEST function for extract this daterange as a column and strftime(..., '%d/%m/%Y') to show on the proper format.

WITH date_range AS (
  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date
)
SELECT strftime(dr.calendar_date, '%d/%m/%Y') AS calendar_date
FROM date_range AS dr
ORDER BY dr.calendar_date;

-- Result 2738 rows 1 column

-- 2. `LEFT JOIN` your daily ride-count series onto that full calendar, and use `COALESCE` to turn genuinely missing days into a visible `0`.

WITH date_range AS (
  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date
),
daily_rides AS (
  SELECT DATE_TRUNC('day', start_time)    AS ride_date, 
  COUNT(bike_id)                          AS total_rides
  FROM trips
  GROUP BY DATE_TRUNC('day', start_time)
)
SELECT 
  strftime(dr.calendar_date, '%d/%m/%Y')  AS calendar_date, 
  COALESCE(d.total_rides, 0)              AS total_rides
FROM date_range                           AS dr
LEFT JOIN daily_rides                     AS d 
        ON dr.calendar_date = d.ride_date
ORDER BY dr.calendar_date;

-- Result 2738 rows 2 columns. 2,738 days this is equal to 7 years and 6 months.

-- 3. Filter down to just the days where the original (pre-`COALESCE`) ride count was `NULL` — these are true data gaps, not real zero-ride days.

WITH date_range AS (
  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date
),
daily_rides AS (
  SELECT DATE_TRUNC('day', start_time)    AS ride_date, 
  COUNT(bike_id)                          AS total_rides
  FROM trips
  GROUP BY DATE_TRUNC('day', start_time)
)
SELECT 
  strftime(dr.calendar_date, '%d/%m/%Y')  AS calendar_date, 
  COALESCE(d.total_rides, 0)              AS total_rides
FROM date_range                           AS dr
LEFT JOIN daily_rides                     AS d 
        ON dr.calendar_date = d.ride_date
    WHERE d.total_rides IS NULL
--  where total_rides=0
ORDER BY dr.calendar_date;

-- Result 0 rows 0 columns. Woohoo we do not have days without rides:)

-- 4. Cross-reference those gap dates against your Week 1, Day 1 notes on schema eras and file boundaries. Do any gaps line up with where one year's file structure changed to another's?
--    0 days 0 gaps
-- 5. Cross-reference the gap dates against your Day 3 notes on the unmatched-station issue — is there any relationship, or are these separate problems?
--    0 days 0 problems
-- 6. Count how many total gap days you found, and what percentage of the full date range that represents.
--    0 days 0 % 
-- 7. Decide, and write a sentence justifying it: should gap days be excluded from later analysis entirely, or included as `0`s? Note that this decision will directly affect Block 4's anomaly flagging if left as `0`.
--    0 days 0 %
-- The weekly grain visibly smooths out daily data and makes longer seasonal patterns easier to read, which will be more reliable as a baseline for anomaly detection than the noisier daily series.

--- BLOCK 3:

-- 1. Build the self-join from the concepts file, comparing each day's ride count to the previous day's.

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
  today.calendar_date,
  today.total_rides,
  COALESCE(yesterday.total_rides,0)             AS previous_day_rides,
  today.total_rides - yesterday.total_rides     AS day_over_day_change
FROM daily_series                               AS today
LEFT JOIN daily_series                               AS yesterday
  ON today.calendar_date_raw = yesterday.calendar_date_raw + INTERVAL '1 day'
ORDER BY today.calendar_date_raw;

-- Result 2738 rows 4 columns. start comparison to 1st January 2019 do not have 31 dec data so we have NULLS.

-- 2. Find the single largest day-over-day increase and the single largest day-over-day decrease across the full dataset.

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
curent_to_yesterday_comparison AS (
  SELECT
    today.calendar_date,
    today.total_rides,
    COALESCE(yesterday.total_rides,0)             AS previous_day_rides,
    today.total_rides - yesterday.total_rides     AS day_over_day_change
  FROM daily_series                               AS today
  LEFT JOIN daily_series                               AS yesterday
    ON today.calendar_date_raw = yesterday.calendar_date_raw + INTERVAL '1 day'
  ORDER BY today.calendar_date_raw
)  
 SELECT
  cty.*

  FROM curent_to_yesterday_comparison AS cty
  WHERE cty.day_over_day_change = (SELECT MIN(day_over_day_change) FROM curent_to_yesterday_comparison)
     OR cty.day_over_day_change = (SELECT MAX(day_over_day_change) FROM curent_to_yesterday_comparison)
;

-- Result 2 rows 4 columns. 29/05/2025 the Largest day_over_day_change 05/04/2026 the Lowes day_over_day_change.

-- 3. Investigate both of those extreme days directly — what day of week were they, what time of year, and does anything in your gap list from Block 2 explain either one?
-- 4. Extend the self-join to compare each day to the same day one week earlier, instead of one day earlier — this controls for the weekly cycle noted in Block 1.
-- 5. Build the correlated-subquery trailing 7-day average from the concepts file, and compare a handful of individual days against their trailing average rather than the single previous day.

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
    today.calendar_date_raw,
    ROUND(AVG(prev.total_rides), 0)            AS trailing_7d_avg
  FROM daily_series                            AS today
  LEFT JOIN daily_series                       AS prev
         ON prev.calendar_date_raw BETWEEN today.calendar_date_raw  - INTERVAL '7 days'
                                        AND today.calendar_date_raw - INTERVAL '1 day'
  GROUP BY today.calendar_date_raw
),
curent_to_previous_comparison AS (
  SELECT
    today.calendar_date,
    today.total_rides,
    COALESCE(yesterday.total_rides,0)             AS previous_day_rides,
    today.total_rides - yesterday.total_rides     AS day_over_day_change,
    t.trailing_7d_avg                             AS trailing_7d_avg,
    today.total_rides - t.trailing_7d_avg         AS diff_from_7d_avg
  FROM daily_series                               AS today
  LEFT JOIN daily_series                          AS yesterday
    ON today.calendar_date_raw = yesterday.calendar_date_raw + INTERVAL '1 day'
  LEFT JOIN trailing_avg                          AS t
         ON today.calendar_date_raw = t.calendar_date_raw
  ORDER BY today.calendar_date_raw
)

 SELECT
  cty.*

  FROM curent_to_previous_comparison AS cty
;

-- Result 2738 rows 6 columns.

-- 6. Note, from direct experience now, one specific way the trailing-average correlated subquery felt more cumbersome than the self-join comparison — this is useful context for appreciating window functions in Week 3.
--- BLOCK 4:

-- 1. Compute the overall mean and standard deviation of daily ride counts, and build the z-score and `CASE WHEN` flag from the concepts file.

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
 
stats AS (
  SELECT 
    AVG(total_rides) AS mean_rides, 
    STDDEV(total_rides) AS stddev_rides
  FROM daily_series
)
SELECT
  ds.calendar_date,
  ds.total_rides,
  (ds.total_rides - stats.mean_rides) / NULLIF(stats.stddev_rides, 0) AS z_score,
  CASE
    WHEN ABS((ds.total_rides - stats.mean_rides) / NULLIF(stats.stddev_rides, 0)) > 3 THEN 'Extreme'
    WHEN ABS((ds.total_rides - stats.mean_rides) / NULLIF(stats.stddev_rides, 0)) > 2 THEN 'Notable'
    ELSE 'Normal'
  END AS anomaly_flag
FROM daily_series ds
CROSS JOIN stats
ORDER BY ds.calendar_date;

-- Result 2738 rows 4 columns.

-- 2. List every day flagged as `'Extreme'` (beyond 3 standard deviations), sorted by date.

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
 
stats AS (
  SELECT 
    AVG(total_rides) AS mean_rides, 
    STDDEV(total_rides) AS stddev_rides
  FROM daily_series
)
SELECT
  ds.calendar_date,
  ds.total_rides,
  (ds.total_rides - stats.mean_rides) / NULLIF(stats.stddev_rides, 0) AS z_score,
  CASE
    WHEN ABS((ds.total_rides - stats.mean_rides) / NULLIF(stats.stddev_rides, 0)) > 3 THEN 'Extreme'
    WHEN ABS((ds.total_rides - stats.mean_rides) / NULLIF(stats.stddev_rides, 0)) > 2 THEN 'Notable'
    ELSE 'Normal'
  END AS anomaly_flag
FROM daily_series ds
CROSS JOIN stats
WHERE anomaly_flag = 'Extreme'
ORDER BY ds.calendar_date;

-- Result 2 rows 4 columns. That is mean we have 2 days with Extreme z_score. Less 0.01% of Total

-- 3. List every day flagged as `'Notable'` (beyond 2 but within 3 standard deviations), and note roughly how many there are compared to `'Extreme'`.

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
 
stats AS (
  SELECT 
    AVG(total_rides) AS mean_rides, 
    STDDEV(total_rides) AS stddev_rides
  FROM daily_series
)
SELECT
  ds.calendar_date,
  ds.total_rides,
  (ds.total_rides - stats.mean_rides) / NULLIF(stats.stddev_rides, 0) AS z_score,
  CASE
    WHEN ABS((ds.total_rides - stats.mean_rides) / NULLIF(stats.stddev_rides, 0)) > 3 THEN 'Extreme'
    WHEN ABS((ds.total_rides - stats.mean_rides) / NULLIF(stats.stddev_rides, 0)) > 2 THEN 'Notable'
    ELSE 'Normal'
  END AS anomaly_flag
FROM daily_series ds
CROSS JOIN stats
WHERE anomaly_flag = 'Notable'
ORDER BY ds.calendar_date;

-- Result 98 rows 5 columns.That is mean we have 98 days with Notable z_score. That 3.57% of Total

-- 4. Revisit the concepts file's limitation about computing one global mean and standard deviation across all seasons and days of week. Rebuild the stats CTE to compute the mean and standard deviation *per month* instead, and reflag anomalies against their own month's statistics.

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
    strftime(dr.calendar_date, '%m')           AS month,
    COALESCE(d.total_rides, 0)                 AS total_rides
  FROM date_range                              AS dr
  LEFT JOIN daily_rides                        AS d
         ON dr.calendar_date = d.ride_date
),
stats AS (
  SELECT 
    month,
    AVG(total_rides)                           AS mean_rides,
    STDDEV(total_rides)                        AS stddev_rides
  FROM daily_series
  GROUP BY month
)
SELECT
  ds.calendar_date,
  ds.month,
  ds.total_rides,
  ROUND(s.mean_rides, 1)                       AS month_mean,
  ROUND(s.stddev_rides, 1)                     AS month_stddev,
  ROUND((ds.total_rides - s.mean_rides) / NULLIF(s.stddev_rides, 0), 2) AS z_score,
  CASE
    WHEN ABS((ds.total_rides - s.mean_rides) / NULLIF(s.stddev_rides, 0)) > 3 THEN 'Extreme'
    WHEN ABS((ds.total_rides - s.mean_rides) / NULLIF(s.stddev_rides, 0)) > 2 THEN 'Notable'
    ELSE 'Normal'
  END                                          AS anomaly_flag
FROM daily_series                              AS ds
JOIN stats                                     AS s
  ON ds.month = s.month
--WHERE anomaly_flag = 'Extreme'
ORDER BY ds.calendar_date_raw;

-- Result 2738 rows 7 columns.

-- 5. Compare your flagged-day list before and after Task 4's per-month adjustment. Did any days drop off the list, or get added, once seasonality was accounted for?
--    Extreme 2 VS 6 days. 29/03/2025 and 30/03/2025 still Extreme but if compeare to the monthly STDEV we have  4 days more.   Notable 98 VS 72 Have opositive effect if compeare to the monthly STDEV we have 26 days less.
-- 6. Cross-reference your final flagged-day list against the gap-day list from Block 2. Remove or separately label any flagged day that's actually a data gap rather than a real anomaly.
--    We do not have empty days so it's a real anomaly.
-- 7. Narrow your remaining flagged list down to two or three days or periods that seem like genuine, worth-investigating anomalies — these carry into Block 5.
       -- 29/03/2025 and 30/03/2025 I think it's a good example. Because bouth of them in one month.

--- BLOCK 5: Mini-Project

-- 1. For each of your two or three flagged periods from Block 4, check whether it lines up with a data gap or schema boundary you've already documented.

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
    strftime(dr.calendar_date, '%m')           AS month,
    COALESCE(d.total_rides, 0)                 AS total_rides
  FROM date_range                              AS dr
  LEFT JOIN daily_rides                        AS d
         ON dr.calendar_date = d.ride_date
),
global_stats AS (
  SELECT 
    AVG(total_rides)                           AS global_mean,
    STDDEV(total_rides)                        AS global_stddev
  FROM daily_series
),
monthly_stats AS (
  SELECT 
    month,
    AVG(total_rides)                           AS month_mean,
    STDDEV(total_rides)                        AS month_stddev
  FROM daily_series
  GROUP BY month
)
SELECT
  ds.calendar_date,
  ds.month,
  ds.total_rides,

  ROUND(g.global_mean, 1)                      AS global_mean,
  ROUND(g.global_stddev, 1)                    AS global_stddev,
  ROUND((ds.total_rides - g.global_mean) 
    / NULLIF(g.global_stddev, 0), 2)           AS z_score_global,

  ROUND(m.month_mean, 1)                       AS month_mean,
  ROUND(m.month_stddev, 1)                     AS month_stddev,
  ROUND((ds.total_rides - m.month_mean) 
    / NULLIF(m.month_stddev, 0), 2)            AS z_score_monthly,

  CASE
    WHEN ABS((ds.total_rides - m.month_mean)
      / NULLIF(m.month_stddev, 0)) > 3        THEN 'Extreme'
    WHEN ABS((ds.total_rides - m.month_mean)
      / NULLIF(m.month_stddev, 0)) > 2        THEN 'Notable'
    ELSE 'Normal'
  END                                          AS anomaly_flag

FROM daily_series                              AS ds
CROSS JOIN global_stats                        AS g
JOIN monthly_stats                             AS m

  ON ds.month = m.month
WHERE ds.calendar_date_raw BETWEEN '2025-03-22' AND '2025-04-05'
ORDER BY ds.calendar_date_raw;

-- 2. For each remaining period, check whether the change persisted over multiple days or weeks, or reverted immediately — pull the surrounding week of data to see.
-- Spike for 2 days, then immediate return looks like  a classic weekend event March 29 and 30, 2025, were Saturday and Sunday, not a structural shift.

-- 3. If your database includes the joined NOAA weather data mentioned in the course description, check whether any flagged period lines up with a significant weather event. If you don't have weather data loaded, note that as a limitation of this analysis rather than skipping the question.
---   That is a limitation of this analysis. we do not load NOAA weather data in SQL project.

-- 4. For any period that still looks like a genuine, real-world event rather than a data or weather artifact, research briefly what was happening in that specific window that could plausibly explain a shift in bikeshare ridership.
--    Maybe it caused by The 2025 National Cherry Blossom Festival in Washington, D.C. Peak Bloom: March 28 – March 31, 2025. To konfirm this theory we need to look deeper in stations data near buy location of the Festival.

--- Report Save as `notes/week2_trend_analysis.md`
--- BLOCK 6 answears saved in markdowns in notes
-- Reporter : Serhiy Dranko
-- Date : 2026-07-30
