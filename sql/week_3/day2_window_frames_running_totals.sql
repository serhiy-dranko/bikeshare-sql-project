-- BLOCK 1:

-- Ranking by distance to weather stations
WITH weather_stations AS (
    SELECT DISTINCT
        STATION       AS weather_station_id,
        Station_name  AS weather_station,
        LATITUDE      AS w_lat,
        LONGITUDE     AS w_lon
    FROM hourly_weather
    WHERE LATITUDE IS NOT NULL AND LONGITUDE IS NOT NULL
),

distances AS (
    SELECT
        s.short_name                        AS station_id,
        s.name                              AS station_name,
        s.lat                               AS b_lat,
        s.lon                               AS b_lon,
        w.weather_station_id,
        w.weather_station,
        w.w_lat,
        w.w_lon,
        -- Haversine distance in kilometers
        2 * 6371 * ASIN(SQRT(
            POWER(SIN(RADIANS(w.w_lat - s.lat) / 2), 2) +
            COS(RADIANS(s.lat)) * COS(RADIANS(w.w_lat)) *
            POWER(SIN(RADIANS(w.w_lon - s.lon) / 2), 2)
        )) AS distance_km
    FROM station AS s
    CROSS JOIN weather_stations AS w
),

ranked AS (
    SELECT *,
        RANK() OVER (
            PARTITION BY station_id
            ORDER BY distance_km ASC
        ) AS rn
    FROM distances
)
SELECT * FROM ranked
Where rn=1

-- 1. Build a running total of daily rides using `SUM(total_rides) OVER (ORDER BY calendar_date)` with no explicit frame, and confirm the last row's value equals the total ride count across the whole dataset.

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
  SUM(total_rides) OVER (ORDER BY calendar_date_raw) AS running_total
FROM daily_series
ORDER BY calendar_date_raw;


-- 2. Rewrite Task 1 with an explicit `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` frame, and confirm the results are identical to the default-frame version.

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
  SUM(total_rides) OVER (ORDER BY calendar_date_raw ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM daily_series
ORDER BY calendar_date_raw;


-- 3. Try `AVG(total_rides) OVER (ORDER BY calendar_date)` with no explicit frame, and confirm — by comparing the first and last rows — that you got a *running* average, not an overall one. This is the default-frame trap from the concepts file, now demonstrated directly.

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
  AVG(total_rides) OVER (ORDER BY calendar_date_raw) AS running_average
FROM daily_series
ORDER BY calendar_date_raw;

-- 4. Fix Task 3 by adding an explicit `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` frame, and confirm every row now shows the same, correct overall average.

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
  AVG(total_rides) OVER (ORDER BY calendar_date_raw ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS average_during_whole_data
FROM daily_series
ORDER BY calendar_date_raw;

-- 5. Build a running total of rides per station using `PARTITION BY station_name` alongside `ORDER BY calendar_date`, confirming the total resets at each new station.
WITH date_range AS (
  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date
),
daily_rides AS (
  SELECT DATE_TRUNC('day', start_time)::DATE   AS ride_date,
         start_station                         AS start_station,
         start_station_id                      AS start_station_id,
         COUNT(bike_id)                        AS total_rides
  FROM trips
  GROUP BY DATE_TRUNC('day', start_time)::DATE, start_station, start_station_id
),
daily_series AS (
  SELECT 
    strftime(dr.calendar_date, '%d/%m/%Y')     AS calendar_date,
    dr.calendar_date                           AS calendar_date_raw,
    d.start_station_id                         AS station_id,
    d.start_station                            AS station,
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
  SUM(total_rides) OVER (ORDER BY calendar_date_raw) AS cumulative_rides
FROM daily_series
ORDER BY calendar_date_raw;

-- 6. Pick a specific date partway through the dataset and manually verify its running total by summing the raw daily values up through that date some other way (a simple filtered `SUM`), confirming your window function's result is correct.

WITH date_range AS (
  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date
),
daily_rides AS (
  SELECT DATE_TRUNC('day', start_time)::DATE   AS ride_date,
         start_station                         AS start_station,
         start_station_id                      AS start_station_id,
         COUNT(bike_id)                        AS total_rides
  FROM trips
  GROUP BY DATE_TRUNC('day', start_time)::DATE, start_station, start_station_id
),
daily_series AS (
  SELECT 
    strftime(dr.calendar_date, '%d/%m/%Y')     AS calendar_date,
    dr.calendar_date                           AS calendar_date_raw,
    d.start_station_id                         AS station_id,
    d.start_station                            AS station,
    COALESCE(d.total_rides, 0)                 AS total_rides
  FROM date_range                              AS dr
  LEFT JOIN daily_rides                        AS d
         ON dr.calendar_date = d.ride_date
)
SELECT
  SUM(total_rides) AS manual_running_total
FROM daily_series
WHERE calendar_date_raw <= '2019-01-03'

--- Result 18711 equal to cumulative_rides in previous query during 03/01/20119
-- BLOCK 2:

-- 1. Build a trailing 7-day moving average using `AVG(total_rides) OVER (ORDER BY calendar_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)`.
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
  AVG(total_rides) OVER (
    ORDER BY calendar_date_raw
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS trailing_7day_avg
FROM daily_series
ORDER BY calendar_date_raw;

-- 2. Compare this row-by-row against your Week 2, Day 4 correlated-subquery trailing average. Confirm they match exactly.
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
-- Query 1 logic: self-join, excludes today
trailing_avg_excl_today AS (
  SELECT
    today.calendar_date_raw,
    ROUND(AVG(prev.total_rides), 0) AS trailing_7d_avg_excl_today
  FROM daily_series AS today
  LEFT JOIN daily_series AS prev
    ON prev.calendar_date_raw BETWEEN today.calendar_date_raw - INTERVAL '7 days'
                                   AND today.calendar_date_raw - INTERVAL '1 day'
  GROUP BY today.calendar_date_raw
),
-- Query 2 logic: window frame, includes today
trailing_avg_incl_today AS (
  SELECT
    calendar_date_raw,
    ROUND(AVG(total_rides) OVER (
      ORDER BY calendar_date_raw
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 0) AS trailing_7d_avg_incl_today
  FROM daily_series
)
SELECT
  a.calendar_date_raw,
  a.trailing_7d_avg_excl_today,
  b.trailing_7d_avg_incl_today,
  a.trailing_7d_avg_excl_today - b.trailing_7d_avg_incl_today AS diff
FROM trailing_avg_excl_today AS a
JOIN trailing_avg_incl_today AS b
  ON a.calendar_date_raw = b.calendar_date_raw
ORDER BY a.calendar_date_raw;

-- Difference in period to see exact the same result as Week 2, Day 4 correlated-subquery trailing average we need to change ROWS BETWEEN 6 PRECEDING AND CURRENT ROW to ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING. Than we get the same result.

-- 3. Build a trailing 30-day moving average using the same pattern with a different `PRECEDING` value, and compare its smoothness against the 7-day version by scanning both visually.

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
  
  ROUND(AVG(total_rides) OVER (
    ORDER BY calendar_date_raw
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ),0) AS trailing_7day_avg,
  
  ROUND(AVG(total_rides) OVER (
    ORDER BY calendar_date_raw
    ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
  ),0) AS trailing_30day_avg
FROM daily_series
ORDER BY calendar_date_raw;


-- 4. Check what happens at the very start of the dataset, where fewer than 7 (or 30) prior rows exist. Confirm the frame quietly uses however many rows are actually available rather than erroring or returning `NULL`.
--- At the firts week we can see that 'trailing_30day_avg' equal to 'trailing_7day_avg' because we do not have data for 30 days only for 7 days. So it start work correctly after 30 rows when it has full dataset.

-- 5. Try building the same trailing average with `PARTITION BY station_name` added, producing a per-station trailing average instead of a dataset-wide one.

WITH date_range AS (
  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date
),
daily_rides AS (
  SELECT DATE_TRUNC('day', start_time)::DATE   AS ride_date,
         start_station                         AS start_station,
         start_station_id                      AS start_station_id,
         COUNT(bike_id)                        AS total_rides
  FROM trips
  GROUP BY DATE_TRUNC('day', start_time)::DATE, start_station, start_station_id
),
daily_series AS (
  SELECT 
    strftime(dr.calendar_date, '%d/%m/%Y')     AS calendar_date,
    dr.calendar_date                           AS calendar_date_raw,
    d.start_station_id                         AS station_id,
    d.start_station                            AS station,
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
  ROUND(
    AVG(total_rides) OVER (
      PARTITION BY station
      ORDER BY calendar_date_raw
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 0
  ) AS trailing_7day_avg_per_station
FROM daily_series
  WHERE station_id = '31623'
ORDER BY station, calendar_date_raw;

-- 6. Note, specifically, any difference in how long this window-function version takes to run compared to the Week 2 correlated-subquery version, if your tool exposes timing.

---  360 ms vs 356 ms now

-- BLOCK 3:

-- 1. Build a centered 7-day average using `ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING`, and compare its shape against the trailing 7-day version from Block 2 — the centered version should look smoother and less "delayed" relative to real spikes.

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
  AVG(total_rides) OVER (
    ORDER BY calendar_date_raw
    ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING
  ) AS trailing_7day_avg
FROM daily_series
ORDER BY calendar_date_raw;



-- 2. Confirm that the very first and last few rows of the centered average have a smaller effective window, since there aren't 3 full rows available on one side.
--- Yes they have smaller effective window use only 4 rows for calculation trailing average.

-- 3. Build a query with a column that genuinely has duplicate values at the row level — for example, trips truncated to the hour, where multiple trips can share the same hour value — and rank them using `ROWS BETWEEN` vs an equivalent `RANGE BETWEEN` frame.

WITH date_range AS (
  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date
),
daily_rides AS (
  SELECT DATE_TRUNC('day', start_time)::DATE   AS ride_date,
         rider_type                            AS rider_type,
         COUNT(bike_id)                        AS total_rides
  FROM trips
  GROUP BY DATE_TRUNC('day', start_time)::DATE, rider_type
),
daily_series AS (
  SELECT 
    strftime(dr.calendar_date, '%d/%m/%Y')     AS calendar_date,
    dr.calendar_date                           AS calendar_date_raw,
    d.rider_type                               AS rider_type,
    COALESCE(d.total_rides, 0)                 AS total_rides
  FROM date_range                              AS dr
  LEFT JOIN daily_rides                        AS d
         ON dr.calendar_date = d.ride_date
)
SELECT
  calendar_date,
  rider_type,
  total_rides,
  AVG(total_rides) OVER (
    ORDER BY calendar_date_raw
    RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW
  ) AS trailing_7day_avg
FROM daily_series
ORDER BY calendar_date_raw;

-- 4. Confirm directly, from the output, where `ROWS` and `RANGE` diverge on that tied data — pick one specific row and explain the different result each produces.
---  `RANGE` groups by value, not row count. All rows sharing the same ORDER BY value are treated as one logical group and included or excluded from the frame together so a tie doesn't get split partway through.
---  `ROWS` counts a fixed number of physical rows, regardless of what value they hold. If two rows tie on the ORDER BY column, ROWS still treats them as two separate rows and counts them separately toward the frame boundary.

-- 5. Decide, for the trip-duration or ride-count reporting you've built this week, whether `ROWS` or `RANGE` is the correct default going forward, and write a sentence justifying it.
--- ROWS is the correct default for our reporting, since we order by unique calendar dates, where ROWS and RANGE give identical results anyway. 
--- But ROWS avoids surprises if ties ever show up. RANGE should only be used when ordering by a column with meaningful duplicates (like total_rides) that should be grouped into the same window together.
-- BLOCK 4:

-- 1. Build the day-over-day percent change query from the concepts file, using `LAG()` and `NULLIF` to guard against division by zero.

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
  LAG(total_rides,1,0) OVER (ORDER BY calendar_date_raw) AS yesterday,
  ROUND(
    (total_rides - LAG(total_rides,1,0) OVER (ORDER BY calendar_date_raw)) * 100.0
    / NULLIF(LAG(total_rides,1,0) OVER (ORDER BY calendar_date_raw), 0),
    2
  ) AS pct_change_day_over_day
FROM daily_series
ORDER BY calendar_date_raw;

-- 2. Find the single largest positive and negative percent change in the dataset, and check whether either lines up with a flagged anomaly from Week 2, Day 4.

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
pct_change AS (
SELECT
  calendar_date,
  total_rides,
  LAG(total_rides,1,0) OVER (ORDER BY calendar_date_raw) AS yesterday,
  ROUND(
    (total_rides - LAG(total_rides) OVER (ORDER BY calendar_date_raw)) * 100.0
    / NULLIF(LAG(total_rides) OVER (ORDER BY calendar_date_raw), 0),
    2
  ) AS pct_change_day_over_day
FROM daily_series
ORDER BY calendar_date_raw
  )
  
SELECT *
FROM pct_change
WHERE pct_change_day_over_day = (SELECT MAX(pct_change_day_over_day) FROM pct_change)
   OR pct_change_day_over_day = (SELECT MIN(pct_change_day_over_day) FROM pct_change)
;

-- 3. Build a week-over-week percent change instead, using `LAG(total_rides, 7)` as the comparison point.

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
  LAG(total_rides,7,0) OVER (ORDER BY calendar_date_raw) AS yesterday,
  ROUND(
    (total_rides - LAG(total_rides,7,0) OVER (ORDER BY calendar_date_raw)) * 100.0
    / NULLIF(LAG(total_rides,7,0) OVER (ORDER BY calendar_date_raw), 0),
    2
  ) AS pct_change_day_over_week
FROM daily_series
ORDER BY calendar_date_raw;

-- 4. Build a month-over-month percent change using a monthly-aggregated version of your time series (grouping by `DATE_TRUNC('month', ...)` first) rather than the daily series.

WITH monthly_rides AS (
  SELECT DATE_TRUNC('month', start_time)::DATE   AS ride_year,
         DATE_TRUNC('month', start_time)::DATE   AS ride_month,
         COUNT(bike_id)                          AS total_rides
  FROM trips
  GROUP BY DATE_TRUNC('year', start_time)::DATE,
           DATE_TRUNC('month', start_time)::DATE
)
SELECT
  strftime(ride_year, '%Y') AS ride_year,
  strftime(ride_month,'%m') AS ride_month,
  total_rides               AS current_month,
  LAG(total_rides,1,0) OVER (ORDER BY ride_year, ride_month) AS last_month,
  ROUND(
    (total_rides - LAG(total_rides,1,0) OVER (ORDER BY ride_year, ride_month)) * 100.0
    / NULLIF(LAG(total_rides,1,0) OVER (ORDER BY ride_year, ride_month), 0),
    2
  ) AS pct_change_month_over_month
FROM monthly_rides
ORDER BY ride_year ASC, ride_month ASC ;


-- 5. Confirm your `NULLIF` guard actually works by checking whether any day in your dataset has a previous value of exactly zero, and confirming that row shows `NULL` for percent change instead of erroring.
--- In the Jan 2019 we will se that `NULLIF` give us NULL because we do not have data before. So yes it works.

-- 6. Round your percent-change values to one decimal place using `ROUND()`, and confirm the output is genuinely more readable than the raw unrounded version.
--- Done from beginning.

-- BLOCK 5:

-- 1. Build the three-table join from the concepts file — station_daily_series, stations, and daily_weather — matching each station's daily rides to its nearest_weather_station_id's observations for the same date. Confirm each row now carries both ride counts and weather values for the correct location.
WITH 
daily_series AS (
  SELECT 
    strftime(start_time, '%d/%m/%Y')     AS calendar_date,
    DATE_TRUNC('day', start_time)::DATE  AS calendar_date_raw,
    start_station_id                     AS station_id,
    start_station                        AS station,
    COUNT(bike_id)                       AS total_rides
  FROM trips                             
  GROUP BY calendar_date, calendar_date_raw, station_id,station
),

-- nearest-weather-station lookup, one row per bike station
weather_stations AS (
    SELECT DISTINCT
        STATION       AS weather_station_id,
        Station_name  AS weather_station,
        LATITUDE      AS w_lat,
        LONGITUDE     AS w_lon
    FROM hourly_weather
    WHERE LATITUDE IS NOT NULL AND LONGITUDE IS NOT NULL
),

distances AS (
    SELECT
        s.short_name AS station_id,
        w.weather_station_id,
        2 * 6371 * ASIN(SQRT(
            POWER(SIN(RADIANS(w.w_lat - s.lat) / 2), 2) +
            COS(RADIANS(s.lat)) * COS(RADIANS(w.w_lat)) *
            POWER(SIN(RADIANS(w.w_lon - s.lon) / 2), 2)
        )) AS distance_km
    FROM station AS s
    CROSS JOIN weather_stations AS w
),

nearest_station AS (
    SELECT station_id, weather_station_id
    FROM (
        SELECT *,
            RANK() OVER (          
                PARTITION BY station_id
                ORDER BY distance_km ASC
            ) AS rn
        FROM distances
    )
    WHERE rn = 1
),

-- weather aggregated per weather station per day
daily_weather AS (
    SELECT 
        STATION                          AS weather_station_id,
        Date,
        ROUND(AVG(temperature),0)        AS avg_temperature,
        ROUND(AVG(precipitation),2)      AS avg_precipitation
    FROM hourly_weather 
    GROUP BY STATION, Date
)

SELECT 
  d.calendar_date,
  d.station_id,
  d.station,
  d.total_rides,
  s.capacity,
  s.lat,
  s.lon,
  ns.weather_station_id,
  w.avg_temperature,
  w.avg_precipitation
FROM daily_series AS d
  
LEFT JOIN station AS s
       ON d.station_id = s.short_name
  
LEFT JOIN nearest_station AS ns
       ON d.station_id = ns.station_id
  
LEFT JOIN daily_weather AS w
       ON w.weather_station_id = ns.weather_station_id
      AND w.Date = d.calendar_date_raw
  
ORDER BY d.calendar_date_raw, d.station_id
  LIMIT 2000;

-- 2. Add `STDDEV(temp_high) OVER (PARTITION BY station_name ORDER BY calendar_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)` to compute a trailing 7-day temperature volatility per station.
-- 3. Add a matching `STDDEV(daily_rides) OVER (...)` using the same partition and frame, so each row shows both trailing weather volatility and trailing ridership volatility side by side.
WITH 
daily_series AS (
  SELECT 
    strftime(start_time, '%d/%m/%Y')     AS calendar_date,
    DATE_TRUNC('day', start_time)::DATE  AS calendar_date_raw,
    start_station_id                     AS station_id,
    start_station                        AS station,
    COUNT(bike_id)                       AS total_rides
  FROM trips                             
  GROUP BY calendar_date, calendar_date_raw, station_id,station
),

-- nearest-weather-station lookup, one row per bike station
weather_stations AS (
    SELECT DISTINCT
        STATION       AS weather_station_id,
        Station_name  AS weather_station,
        LATITUDE      AS w_lat,
        LONGITUDE     AS w_lon
    FROM hourly_weather
    WHERE LATITUDE IS NOT NULL AND LONGITUDE IS NOT NULL
),

distances AS (
    SELECT
        s.short_name AS station_id,
        w.weather_station_id,
        2 * 6371 * ASIN(SQRT(
            POWER(SIN(RADIANS(w.w_lat - s.lat) / 2), 2) +
            COS(RADIANS(s.lat)) * COS(RADIANS(w.w_lat)) *
            POWER(SIN(RADIANS(w.w_lon - s.lon) / 2), 2)
        )) AS distance_km
    FROM station AS s
    CROSS JOIN weather_stations AS w
),

nearest_station AS (
    SELECT station_id, weather_station_id
    FROM (
        SELECT *,
            RANK() OVER (          
                PARTITION BY station_id
                ORDER BY distance_km ASC
            ) AS rn
        FROM distances
    )
    WHERE rn = 1
),

-- weather aggregated per weather station per day
daily_weather AS (
    SELECT 
        STATION                          AS weather_station_id,
        Date,
        ROUND(AVG(temperature),0)        AS avg_temperature,
        ROUND(AVG(precipitation),2)      AS avg_precipitation
    FROM hourly_weather 
    GROUP BY STATION, Date
)

SELECT 
  d.calendar_date,
  d.station_id,
  d.station,
  d.total_rides,
  s.capacity,
  ns.weather_station_id,
  w.avg_temperature,
  w.avg_precipitation,
  STDDEV(w.avg_temperature) 
  OVER (PARTITION BY d.station_id
            ORDER BY d.calendar_date_raw
              ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS trail_7_day_temp,
  STDDEV(d.total_rides) 
  OVER (PARTITION BY d.station_id
            ORDER BY d.calendar_date_raw
              ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS trail_7_day_rides
  
FROM daily_series AS d
  
LEFT JOIN station AS s
       ON d.station_id = s.short_name
  
LEFT JOIN nearest_station AS ns
       ON d.station_id = ns.station_id
  
LEFT JOIN daily_weather AS w
       ON w.weather_station_id = ns.weather_station_id
      AND w.Date = d.calendar_date_raw
  
ORDER BY d.calendar_date_raw, d.station_id;


-- 4. Pick one station and scan for a week where temperature volatility was unusually high. Check whether ridership volatility was also elevated that same week, or whether the two moved independently.

WITH 
daily_series AS (
  SELECT 
    strftime(start_time, '%d/%m/%Y')     AS calendar_date,
    DATE_TRUNC('day', start_time)::DATE  AS calendar_date_raw,
    start_station_id                     AS station_id,
    start_station                        AS station,
    COUNT(bike_id)                       AS total_rides
  FROM trips                             
  GROUP BY calendar_date, calendar_date_raw, station_id,station
),

-- nearest-weather-station lookup, one row per bike station
weather_stations AS (
    SELECT DISTINCT
        STATION       AS weather_station_id,
        Station_name  AS weather_station,
        LATITUDE      AS w_lat,
        LONGITUDE     AS w_lon
    FROM hourly_weather
    WHERE LATITUDE IS NOT NULL AND LONGITUDE IS NOT NULL
),

distances AS (
    SELECT
        s.short_name AS station_id,
        w.weather_station_id,
        2 * 6371 * ASIN(SQRT(
            POWER(SIN(RADIANS(w.w_lat - s.lat) / 2), 2) +
            COS(RADIANS(s.lat)) * COS(RADIANS(w.w_lat)) *
            POWER(SIN(RADIANS(w.w_lon - s.lon) / 2), 2)
        )) AS distance_km
    FROM station AS s
    CROSS JOIN weather_stations AS w
),

nearest_station AS (
    SELECT station_id, weather_station_id
    FROM (
        SELECT *,
            RANK() OVER (          
                PARTITION BY station_id
                ORDER BY distance_km ASC
            ) AS rn
        FROM distances
    )
    WHERE rn = 1
),

-- weather aggregated per weather station per day
daily_weather AS (
    SELECT 
        STATION                          AS weather_station_id,
        Date,
        ROUND(AVG(temperature),0)        AS avg_temperature,
        ROUND(AVG(precipitation),2)      AS avg_precipitation
    FROM hourly_weather 
    GROUP BY STATION, Date
)

SELECT 
  d.calendar_date,
  d.station_id,
  d.station,
  d.total_rides,
  s.capacity,
  ns.weather_station_id,
  w.avg_temperature,
  w.avg_precipitation,
  STDDEV(w.avg_temperature) 
  OVER (PARTITION BY d.station_id
            ORDER BY d.calendar_date_raw
              ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS trail_7_day_temp,
  STDDEV(d.total_rides) 
  OVER (PARTITION BY d.station_id
            ORDER BY d.calendar_date_raw
              ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS trail_7_day_rides
  
FROM daily_series AS d
  
LEFT JOIN station AS s
       ON d.station_id = s.short_name
  
LEFT JOIN nearest_station AS ns
       ON d.station_id = ns.station_id
  
LEFT JOIN daily_weather AS w
       ON w.weather_station_id = ns.weather_station_id
      AND w.Date = d.calendar_date_raw
WHERE d.station_id ='31623' 
 AND d.calendar_date_raw BETWEEN '2024-01-21' AND '2024-01-31'
  
ORDER BY d.calendar_date_raw ASC;

---- On January 26, 2024 Stdev = 8.46, Washington, D.C. experienced historic and record-shattering warmth, reaching an astonishing high of 80°F (26.6°C) at Reagan National Airport. 
---- This marked an all-time record high for the month of January and the earliest 80-degree day ever recorded in the capital's history. 

-- 5. Recompute one of your Block 5 `STDDEV()` columns using `STDDEV_POP()` instead of the default `STDDEV_SAMP()`, and confirm the two values are close but not identical — note by how much they diverge on a window with only a handful of rows versus a full 30-day window.

WITH 
daily_series AS (
  SELECT 
    strftime(start_time, '%d/%m/%Y')     AS calendar_date,
    DATE_TRUNC('day', start_time)::DATE  AS calendar_date_raw,
    start_station_id                     AS station_id,
    start_station                        AS station,
    COUNT(bike_id)                       AS total_rides
  FROM trips                             
  GROUP BY calendar_date, calendar_date_raw, station_id,station
),

-- nearest-weather-station lookup, one row per bike station
weather_stations AS (
    SELECT DISTINCT
        STATION       AS weather_station_id,
        Station_name  AS weather_station,
        LATITUDE      AS w_lat,
        LONGITUDE     AS w_lon
    FROM hourly_weather
    WHERE LATITUDE IS NOT NULL AND LONGITUDE IS NOT NULL
),

distances AS (
    SELECT
        s.short_name AS station_id,
        w.weather_station_id,
        2 * 6371 * ASIN(SQRT(
            POWER(SIN(RADIANS(w.w_lat - s.lat) / 2), 2) +
            COS(RADIANS(s.lat)) * COS(RADIANS(w.w_lat)) *
            POWER(SIN(RADIANS(w.w_lon - s.lon) / 2), 2)
        )) AS distance_km
    FROM station AS s
    CROSS JOIN weather_stations AS w
),

nearest_station AS (
    SELECT station_id, weather_station_id
    FROM (
        SELECT *,
            RANK() OVER (          
                PARTITION BY station_id
                ORDER BY distance_km ASC
            ) AS rn
        FROM distances
    )
    WHERE rn = 1
),

-- weather aggregated per weather station per day
daily_weather AS (
    SELECT 
        STATION                          AS weather_station_id,
        Date,
        ROUND(AVG(temperature),0)        AS avg_temperature,
        ROUND(AVG(precipitation),2)      AS avg_precipitation
    FROM hourly_weather 
    GROUP BY STATION, Date
)

SELECT 
  d.calendar_date,
  d.station_id,
  d.station,
  d.total_rides,
  s.capacity,
  ns.weather_station_id,
  w.avg_temperature,
  w.avg_precipitation,
  STDDEV_POP(w.avg_temperature) 
  OVER (PARTITION BY d.station_id
            ORDER BY d.calendar_date_raw
              ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS pop_7_day_temp,
  
  STDDEV(w.avg_temperature) 
  OVER (PARTITION BY d.station_id
            ORDER BY d.calendar_date_raw
              ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS trail_7_day_temp,

  STDDEV_POP(d.total_rides) 
  OVER (PARTITION BY d.station_id
            ORDER BY d.calendar_date_raw
              ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS pop_7_day_rides,
  STDDEV(d.total_rides) 
  OVER (PARTITION BY d.station_id
            ORDER BY d.calendar_date_raw
              ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS trail_7_day_rides
  
FROM daily_series AS d
  
LEFT JOIN station AS s
       ON d.station_id = s.short_name
  
LEFT JOIN nearest_station AS ns
       ON d.station_id = ns.station_id
  
LEFT JOIN daily_weather AS w
       ON w.weather_station_id = ns.weather_station_id
      AND w.Date = d.calendar_date_raw
WHERE d.station_id ='31623' 
 AND d.calendar_date_raw BETWEEN '2024-01-21' AND '2024-01-31'
  
ORDER BY d.calendar_date_raw ASC;

-- 6. Try `AVG(temp_high) OVER (...)` with no explicit frame in the same query as a `STDDEV()` window function that does have an explicit frame, and confirm the default-frame trap from Block 1 applies here too if you're not careful.
WITH 
daily_series AS (
  SELECT 
    strftime(start_time, '%d/%m/%Y')     AS calendar_date,
    DATE_TRUNC('day', start_time)::DATE  AS calendar_date_raw,
    start_station_id                     AS station_id,
    start_station                        AS station,
    COUNT(bike_id)                       AS total_rides
  FROM trips                             
  GROUP BY calendar_date, calendar_date_raw, station_id,station
),

-- nearest-weather-station lookup, one row per bike station
weather_stations AS (
    SELECT DISTINCT
        STATION       AS weather_station_id,
        Station_name  AS weather_station,
        LATITUDE      AS w_lat,
        LONGITUDE     AS w_lon
    FROM hourly_weather
    WHERE LATITUDE IS NOT NULL AND LONGITUDE IS NOT NULL
),

distances AS (
    SELECT
        s.short_name AS station_id,
        w.weather_station_id,
        2 * 6371 * ASIN(SQRT(
            POWER(SIN(RADIANS(w.w_lat - s.lat) / 2), 2) +
            COS(RADIANS(s.lat)) * COS(RADIANS(w.w_lat)) *
            POWER(SIN(RADIANS(w.w_lon - s.lon) / 2), 2)
        )) AS distance_km
    FROM station AS s
    CROSS JOIN weather_stations AS w
),

nearest_station AS (
    SELECT station_id, weather_station_id
    FROM (
        SELECT *,
            RANK() OVER (          
                PARTITION BY station_id
                ORDER BY distance_km ASC
            ) AS rn
        FROM distances
    )
    WHERE rn = 1
),

-- weather aggregated per weather station per day
daily_weather AS (
    SELECT 
        STATION                          AS weather_station_id,
        Date,
        ROUND(AVG(temperature),0)        AS avg_temperature,
        ROUND(AVG(precipitation),2)      AS avg_precipitation
    FROM hourly_weather 
    GROUP BY STATION, Date
)

SELECT 
  d.calendar_date,
  d.station_id,
  d.station,
  d.total_rides,
  s.capacity,
  ns.weather_station_id,
  w.avg_temperature,
  w.avg_precipitation,
  AVG(w.avg_temperature)
        OVER (PARTITION BY d.station_id
            ORDER BY d.calendar_date_raw
              ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS trail_avg_temp,
  STDDEV(w.avg_temperature) 
  OVER (PARTITION BY d.station_id
            ORDER BY d.calendar_date_raw
              ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS trail_7_day_temp,

  STDDEV(d.total_rides) 
  OVER (PARTITION BY d.station_id
            ORDER BY d.calendar_date_raw
              ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS trail_7_day_rides
  
FROM daily_series AS d
  
LEFT JOIN station AS s
       ON d.station_id = s.short_name
  
LEFT JOIN nearest_station AS ns
       ON d.station_id = ns.station_id
  
LEFT JOIN daily_weather AS w
       ON w.weather_station_id = ns.weather_station_id
      AND w.Date = d.calendar_date_raw
WHERE d.station_id ='31623' 
 AND d.calendar_date_raw BETWEEN '2024-01-21' AND '2024-01-31'
  
ORDER BY d.calendar_date_raw ASC;

-- BLOCK 6:

-- 1. Open your Week 2, Day 4 anomaly-detection SQL file and identify every self-join and correlated subquery still in it.
-- 2. Replace the day-over-day self-join with `LAG()` (from Day 1) if you haven't already.
-- 3. Replace the trailing 7-day correlated subquery with the `AVG() OVER (... ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)` version from Block 2.
-- 4. Re-run the full pipeline end to end and confirm your flagged-anomaly list from Week 2, Day 4 is unchanged — the results should be identical, only the method should differ.

WITH date_range AS (

  SELECT UNNEST(generate_series(
    (SELECT MIN(DATE_TRUNC('day', start_time)) FROM trips),
    (SELECT MAX(DATE_TRUNC('day', start_time)) FROM trips),
    INTERVAL '1 day'
  ))::DATE AS calendar_date

),

daily_rides AS (

  SELECT 
    DATE_TRUNC('day', start_time)::DATE AS ride_date,
    COUNT(bike_id) AS total_rides

  FROM trips

  GROUP BY DATE_TRUNC('day', start_time)::DATE

),

daily_series AS (

  SELECT 

    strftime(dr.calendar_date, '%d/%m/%Y') AS calendar_date,
    dr.calendar_date AS calendar_date_raw,
    strftime(dr.calendar_date, '%m') AS month,
    COALESCE(d.total_rides,0) AS total_rides

  FROM date_range dr

  LEFT JOIN daily_rides d
         ON dr.calendar_date = d.ride_date

),

global_stats AS (

  SELECT

    AVG(total_rides) AS global_mean,
    STDDEV(total_rides) AS global_stddev

  FROM daily_series

),

monthly_stats AS (

  SELECT

    month,
    AVG(total_rides) AS month_mean,
    STDDEV(total_rides) AS month_stddev

  FROM daily_series

  GROUP BY month

),

analysis AS (

SELECT

    ds.calendar_date,
    ds.calendar_date_raw,
    ds.month,
    ds.total_rides,

    -- Day over day comparison using LAG()

    LAG(ds.total_rides,1,0) OVER (
        ORDER BY ds.calendar_date_raw
    ) AS previous_day_rides,

    ds.total_rides 
    - LAG(ds.total_rides,1,0) OVER (
        ORDER BY ds.calendar_date_raw
    ) AS daily_change,

    -- Trailing 7 day average using window function

    AVG(ds.total_rides) OVER (

        ORDER BY ds.calendar_date_raw

        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW

    ) AS trailing_7_day_avg,


    ROUND(g.global_mean,1) AS global_mean,

    ROUND(g.global_stddev,1) AS global_stddev,


    ROUND(
        (ds.total_rides - g.global_mean)
        / NULLIF(g.global_stddev,0),
    2) AS z_score_global,


    ROUND(m.month_mean,1) AS month_mean,

    ROUND(m.month_stddev,1) AS month_stddev,

    ROUND(
        (ds.total_rides - m.month_mean)
        / NULLIF(m.month_stddev,0),
    2) AS z_score_monthly


FROM daily_series ds

CROSS JOIN global_stats g

JOIN monthly_stats m
     ON ds.month = m.month

)


SELECT

    calendar_date,
    month,
    total_rides,
    previous_day_rides,
    daily_change,
    ROUND(trailing_7_day_avg,1) AS trailing_7_day_avg,
    global_mean,
    global_stddev,
    z_score_global,
    month_mean,
    month_stddev,
    z_score_monthly,

    CASE

        WHEN ABS(z_score_monthly) > 3 
            THEN 'Extreme'
        WHEN ABS(z_score_monthly) > 2
            THEN 'Notable'
        ELSE 'Normal'
    END AS anomaly_flag


FROM analysis

WHERE calendar_date_raw BETWEEN DATE '2025-03-22'
                            AND DATE '2025-04-05'

ORDER BY calendar_date_raw;

-- Reporter : Serhiy Dranko
-- Date : 2026-08-04
