-- Day 1:

--- BLOCK 1
-- Finds the station with the single highest total number of rides.

SELECT
    
    su.ID_station       AS station_id,
    su.station_name     AS station_name,
    su.total_rides      AS total_rides

  FROM stations_summary AS su
    WHERE total_rides = (SELECT MAX(total_rides) FROM stations_summary);

--- BLOCK 2
-- Lists stations with a capacity greater than 40, along with their total ride counts.

SELECT 
    
    su.ID_station       AS station_id,
    su.station_name     AS station_name,
    su.total_rides      AS total_rides,
    s.capacity          AS station_capacity
    
  FROM stations_summary AS su
    INNER JOIN station AS s
            ON s.short_name = su.ID_station
  GROUP BY ALL
  HAVING station_capacity > 40;

--- BLOCK 3
-- Finds the busiest station (by total rides) within each neighborhood.

SELECT
    st.Neighborhood                                                         AS Neighborhood,
    st.Station_id                                                           AS Station_id,
    st.Station_name                                                         AS Station_name,
    st.total_rides                                                          AS Total_rides
    
FROM (
        SELECT 
            COALESCE(n.neighborhood, 'Cluster history - Without geomarks')  AS Neighborhood,
            s.ID_Station                                                    AS Station_id,
            s.station_name                                                  AS Station_name,
            s.latitude                                                      AS Latitude,
            s.longitude                                                     AS Longitude,
            SUM(s.total_rides)                                              AS total_rides
        FROM stations_summary                                               AS s
        LEFT JOIN station                                                   AS n
               ON n.short_name = s.ID_Station
        GROUP BY n.neighborhood, s.ID_Station, s.station_name, s.latitude, s.longitude
        )                                                                   AS st

  WHERE st.total_rides = (
                            SELECT MAX(nt.total_rides)
                            FROM (
                                    SELECT 
                                        COALESCE(n2.neighborhood, 'Cluster history - Without geomarks') AS Neighborhood,
                                        s2.ID_Station                                                   AS Station_id,
                                        SUM(s2.total_rides)                                             AS total_rides
                                    FROM stations_summary                                               AS s2
                                    LEFT JOIN station                                                   AS n2
                                           ON n2.short_name = s2.ID_Station
                                    GROUP BY n2.neighborhood, s2.ID_Station
                                  ) AS nt
                            WHERE nt.Neighborhood = st.Neighborhood
                          )

ORDER BY st.total_rides DESC;

--- BLOCK 4 
-- Lists start stations (with valid duration between 0 and 1440 minutes) that have more than 5000 trips originating from them.

SELECT DISTINCT tr.start_station
FROM trips AS tr
WHERE tr.start_station IS NOT NULL
  AND tr.end_time > tr.start_time
  AND (date_part('epoch', tr.end_time - tr.start_time) / 60) < 1440
  AND (
        SELECT COUNT(*)
        FROM trips AS tr2
        WHERE tr2.start_station = tr.start_station
          AND tr2.start_station IS NOT NULL
          AND tr2.end_time > tr2.start_time
          AND (date_part('epoch', tr2.end_time - tr2.start_time) / 60) < 1440
      ) > 5000
ORDER BY tr.start_station;


-- Day 2:

--- BLOCK 1
-- Compares total rides per year/rider type against the current year's ride count for that rider type.

WITH rides AS (
  SELECT 
    date_part('year', t.start_time) AS Year,
    t.rider_type                    AS rider_type,
    COUNT(t.bike_id)                AS Total_rides
  FROM trips         AS t
   GROUP BY Year, rider_type
                          )
  
Select 
  r.Year,
  r.rider_type,
  r.Total_rides,
  r2.Total_rides AS current_year_rides
  FROM rides AS r
  LEFT join rides AS r2 
         ON r2.rider_type=r.rider_type AND r2.Year = date_part('year', current_date) -- current year
;

--- BLOCK 2
-- Ranks stations with capacity over 30 by total rides, showing average trip duration and capacity.

SELECT 
    t.Station_id                      AS ID,
    t.Station_name                    AS Station_name,
    t.Total_rides                     AS Total_rides,
    a.avg_duration_minutes            AS Avg_duration_minutes,
    c.capacity                        AS Capacity
FROM (
    SELECT 
        start_station_id  AS Station_id,
        start_station     AS Station_name,
        COUNT(bike_id)     AS Total_rides
    FROM trips
    WHERE start_station_id IS NOT NULL
    GROUP BY start_station_id, start_station
) AS t
LEFT JOIN (
    SELECT 
        start_station_id                                              AS Station_id,
        start_station                                                 AS Station_name,
        ROUND(AVG(date_part('epoch', end_time - start_time) / 60), 1) AS avg_duration_minutes
    FROM trips
    WHERE start_station_id IS NOT NULL
    GROUP BY start_station_id, start_station
) AS a
       ON t.Station_id = a.Station_id
INNER JOIN (
    SELECT 
        short_name,
        capacity
    FROM station
    GROUP BY ALL
    HAVING capacity > 30
) AS c
        ON c.short_name = t.Station_id
ORDER BY Total_rides DESC;

--- BLOCK 3
-- Ranks stations within each neighborhood that perform above their neighborhood's average ride count.

WITH total_rides AS (
  
    SELECT 
        t.start_station_id  AS Station_id,
        MAX(t.start_station)AS Station_name,
        COUNT(t.bike_id)    AS Total_rides
    FROM trips              AS t
    WHERE t.start_station_id IS NOT null
      AND t.end_time > t.start_time
       -- Filter Duration Between 1 min and 24 hours --                 
      AND (date_part('epoch', t.end_time - t.start_time) / 60) < 1440
      AND (date_part('epoch', t.end_time - t.start_time) / 60) >= 1
  
    GROUP BY t.start_station_id, t.start_station
),

neighborhood_names AS (
  
    SELECT 
        s.neighborhood      AS Neighborhood,
        t.start_station_id  AS Station_id,
        MAX(t.start_station)AS Station_name
        
    FROM trips              AS t
    LEFT JOIN station       AS s
           ON t.start_station_id = s.short_name
    WHERE t.start_station_id IS NOT null
    GROUP BY ALL
),
  
neighborhood_avg_raides AS (
  
    SELECT 
        s.neighborhood                     AS Neighborhood,
        ROUND(AVG(t.Total_rides), 0)       AS avg_rides
        
    FROM total_rides                       AS t
    LEFT JOIN station                      AS s
           ON t.Station_id = s.short_name
    WHERE t.Station_id IS NOT null
    GROUP BY s.neighborhood
),

above_avg_stations AS (

    SELECT
        n.Station_id                      AS Station_id,
        n.Station_name                    AS Station_name,
        n.Neighborhood                    AS Neighborhood,
        SUM(t.Total_rides)                AS Total_rides,
        a.avg_rides                       AS Neighborhood_avg_rides
    FROM neighborhood_names               AS n
    LEFT JOIN total_rides                 AS t
           ON n.Station_id = t.Station_id
    LEFT JOIN neighborhood_avg_raides     AS a
           ON n.Neighborhood = a.Neighborhood
    WHERE n.Neighborhood IS NOT NULL
      AND t.Total_rides > a.avg_rides
  GROUP BY ALL
),

  ranked_above_avg AS (
    SELECT
        Station_id,
        Station_name,
        Neighborhood,
        Total_rides,
        Neighborhood_avg_rides,
        ROUND(Total_rides - Neighborhood_avg_rides, 0)      AS rides_above_avg,
        RANK() OVER (
            PARTITION BY Neighborhood 
            ORDER BY Total_rides - Neighborhood_avg_rides DESC
        )                                                    AS rank_in_neighborhood
    FROM above_avg_stations
)

SELECT *
FROM ranked_above_avg
ORDER BY Neighborhood, rank_in_neighborhood;

--- BLOCK 4
-- Identifies the single busiest station in each neighborhood and shows how far above the neighborhood average it rides.

WITH station_totals AS (
    SELECT 
        s.neighborhood      AS neighborhood,
        t.start_station_id  AS station_id,
        t.start_station     AS station_name,
        COUNT(t.bike_id)    AS total_rides
    FROM trips              AS t
  
    -- Connecting to the neighborhood data ----
    LEFT JOIN station       AS s
           ON t.start_station_id = s.short_name
    -------------------------------------------
    WHERE t.start_station_id IS NOT NULL -- Filter out data without Start station info
      AND t.end_time > t.start_time      -- Filter out data witho negative duration
      AND (date_part('epoch', t.end_time - t.start_time) / 60) BETWEEN 1 AND 1440 -- Filter out duration more 24 hours and false unlocks (less 1 minute)
    GROUP BY s.neighborhood, t.start_station_id, t.start_station
)
,

neighborhood_averages AS (
    SELECT 
        neighborhood,
        COUNT(station_id)          AS Stations_quantity,      -- count quantity of stations in the neighborhoods
        SUM(total_rides)           AS total_per_neighborhood, -- calculate quantity of rides in the neighborhoods
        ROUND(AVG(total_rides), 0) AS avg_rides_per_station   -- calculate average rides per station in the neighborhoods
    FROM station_totals
    GROUP BY neighborhood
)
,

busiest_per_neighborhood AS (
    SELECT 
        neighborhood,
        station_id,
        station_name,
        total_rides
    FROM station_totals
  -- Choose 1st statition by the quantity of rides in the neighborhoods --
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY neighborhood 
        ORDER BY total_rides DESC, station_id
    ) = 1
  ------------------------------------------------------------------------
)

SELECT
    b.neighborhood                                                 AS neighborhood, 
    b.station_id                                                   AS busiest_station_id,
    b.station_name                                                 AS busiest_station,
    b.total_rides                                                  AS station_rides,
    a.avg_rides_per_station                                        AS neighborhood_avg_rides,
    ROUND(b.total_rides - a.avg_rides_per_station, 0)              AS rides_above_average,
    a.Stations_quantity                                            AS stations_in_neighborhood,
    a.total_per_neighborhood                                       AS neighborhood_rides
    
FROM busiest_per_neighborhood                                      AS b
-- Connecting to the neighborhood data averages for total values by the neighborhoods --
LEFT JOIN neighborhood_averages                                    AS a
       ON b.neighborhood = a.neighborhood
---------------------------------------------------------------------------------------- 
WHERE b.neighborhood IS NOT NULL
ORDER BY rides_above_average DESC;

-- Day 3:

--- BLOCK 1
-- Counts how many trips are missing a start station and how many are missing an end station.

SELECT
  'start is null' AS condition,
  COUNT(*)
FROM trips
WHERE start_station IS NULL
UNION ALL
SELECT
  'end is null' AS condition,
  COUNT(*)
FROM trips
WHERE end_station IS NULL;

--- BLOCK 2
-- Finds trips with 'N/A' placeholder values in station id/name fields and totals rides for each such combination.

SELECT 
            
 t.start_station_id                                                             AS Start_station_id,
 t.start_station                                                                AS Start_station_name,
 t.end_station_id                                                               AS End_station_id,
 t.end_station                                                                  AS End_station_name,
 COUNT(t.bike_id)                                                               AS total_rides
            
         
FROM trips                                                                      AS t
 WHERE t.start_station_id Like 'N/A'
    OR t.start_station    Like 'N/A'
    OR t.end_station_id   Like 'N/A'
    OR t.end_station      Like 'N/A'
GROUP BY ALL;

--- BLOCK 3
-- Buckets trips by station capacity tier and ride duration range, showing ride counts and averages for each combination.

SELECT 
  CASE
   WHEN s.capacity > 40 THEN 'Large'
   WHEN s.capacity > 20 THEN 'Medium'
   WHEN s.capacity > 0  THEN 'Small'
   ELSE 'Unknown'
   END                                                                AS capacity_tier,
        
   CASE
    WHEN t.duration < 0                         THEN 'Negative'
    WHEN t.duration < 10                        THEN 'under 10 min'
    WHEN t.duration >= 10 AND  t.duration <= 30 THEN '10–30 min'
    WHEN t.duration > 30 AND  t.duration < 1440 THEN 'over 30 min'
    WHEN t.duration > 1440                      THEN 'over 24 h'
    ELSE 'Unknown'
    END                                                                AS duration_bucket,
        
    COUNT(t.bike_id)                                                   AS total_rides,
    ROUND(AVG(t.duration), 1)                                          AS avg_duration,
    ROUND(AVG(s.capacity), 0)                                          AS avg_capacity
        
FROM trips                                                             AS t
LEFT JOIN station                                                      AS s
       ON s.short_name = t.start_station_id
 GROUP BY ALL
 ORDER BY capacity_tier, duration_bucket;

--- BLOCK 4
-- Compares ride counts and average duration between trips matched to a known station/neighborhood versus unmatched ones.

WITH capacity AS(
SELECT
  s.neighborhood,
  s.short_name,
  s.name,
  s.lat,
  s.lon,
  s.capacity
  FROM station AS s)

 SELECT
    CASE
     WHEN s.short_name IS NULL THEN 'Unmatched' ELSE 'Matched' END                               AS flag_column,
    COALESCE(s.neighborhood,'Unknown')                                                           AS neighborhood,
    COUNT(t.bike_id)                                                                             AS total_rides, 
    ROUND(AVG(date_part('epoch', t.end_time - t.start_time) / 60),0)                             AS average_ride_duration_min 
                
                                
   FROM trips                                                                                     AS t 
            
  LEFT JOIN capacity                                                                              AS s
         ON t.start_station_id = s.short_name
                
   GROUP BY flag_column, neighborhood
              
   ORDER BY total_rides DESC;

-- Day 4:
-- Builds a full daily calendar of ride counts and flags anomalous days (Notable/Extreme) based on z-scores vs. global and monthly averages, for the highest peak in Stdev.

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
