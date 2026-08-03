--- BLOCK 1

-- 1. Take your Day 1, Block 1, Task 3 query (stations above average capacity) and rewrite it using a CTE instead of a scalar subquery in WHERE.
WITH average_capacity AS (
  SELECT
    ROUND(AVG(sq.capacity),0)                             AS average_capacity
  FROM station AS sq
)
SELECT 
    
    s.short_name                                          AS station_id,
    s.name                                                AS station_name, 
    s.capacity                                            AS capacity,
    (SELECT average_capacity FROM average_capacity)       AS average_capacity
    
  FROM station                                            AS s
  
  ORDER BY capacity DESC;

-- Result 850 rows 4 column. Average capacity was rounded to whole number. The same as Day 1, Block 1, Task 3 query

-- 2. Take your Day 1, Block 3, Task 1 query (per-station totals aggregated by neighborhood) and rewrite the FROM subquery as a CTE. Confirm the result is identical.
-- 3. Run the CTE version and the original subquery version side by side and compare not just the results but which one you'd rather hand to someone else to read.

WITH average_rides_per_neighborhood AS (
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
  
)
SELECT
    st.Neighborhood                                                             AS Neighborhood,
    ROUND(AVG(st.total_rides), 0)                                               AS Averege_rides_per_neighborhood
FROM average_rides_per_neighborhood                                             AS st
GROUP BY st.Neighborhood
ORDER BY Averege_rides_per_neighborhood DESC;

-- Result 43 rows 2 columns. The same as Day 1, Block 3, Task 1. I would rather give CTE Version because it Easieer to read the code.

-- 4. Write a CTE that selects trips from a single year of your choice, then use it in an outer query to count rides by rider type — a case where the CTE is really just a readable filter, nothing fancier.

WITH rides_in_2026   AS (
  SELECT 
    t.rider_type     AS rider_type,
    COUNT(t.bike_id) AS Total_rides_2026
  FROM trips         AS t
    WHERE date_part('year', t.start_time) = 2026
  GROUP BY rider_type
                        )
  
Select * FROM rides_in_2026;

-- Result 2 rows 2 columns.

-- 5. Try referencing a CTE twice in the same outer query (for example, joining it to itself, or using it in both a SELECT and a WHERE). Confirm this works without redefining it.

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
         ON r2.rider_type=r.rider_type AND r2.Year = '2026'
;


--- BLOCK 2

-- 1. Write two separate, unrelated CTEs in one query: one computing total rides per station, one computing average trip duration per station. Join them together in the final SELECT.

WITH total_rides AS (
    SELECT 
        t.start_station_id  AS Station_id,
        t.start_station     AS Station_name,
        COUNT(t.bike_id)    AS Total_rides
    FROM trips              AS t
    WHERE t.start_station_id IS NOT null
    GROUP BY Station_id, Station_name
),
average_trip_duration AS (
    SELECT 
        t.start_station_id                                            AS Station_id,
        t.start_station                                               AS Station_name,
        ROUND(AVG(date_part('epoch', end_time - start_time) / 60), 1) AS avg_duration_minutes
    FROM trips                                                        AS t
    WHERE t.start_station_id IS NOT null
    GROUP BY Station_id, Station_name
)
SELECT 
    t.Station_id                    AS ID,
    t.Station_name                  AS Station_name,
    t.Total_rides                   AS Total_rides,
    a.avg_duration_minutes          AS Avg_duration_minutes
FROM total_rides                  AS t
LEFT JOIN average_trip_duration     AS a
       ON t.Station_id = a.Station_id
ORDER BY Total_rides DESC;

-- Result 1581 rows 4 columns.

-- 2. Add a third CTE identifying stations with capacity over 30, and filter the final result down to only those stations using all three CTEs together.

WITH total_rides AS (
    SELECT 
        t.start_station_id  AS Station_id,
        t.start_station     AS Station_name,
        COUNT(t.bike_id)    AS Total_rides
    FROM trips              AS t
    WHERE t.start_station_id IS NOT null
    GROUP BY Station_id, Station_name
),
average_trip_duration AS (
    SELECT 
        t.start_station_id                                            AS Station_id,
        t.start_station                                               AS Station_name,
        ROUND(AVG(date_part('epoch', end_time - start_time) / 60), 1) AS avg_duration_minutes
    FROM trips                                                        AS t
    WHERE t.start_station_id IS NOT null
    GROUP BY Station_id, Station_name
),

capacity AS (
   SELECT
    
    s.short_name,
    s.capacity
  FROM station AS s
  GROUP BY ALL
  having s.capacity > 30)
 
SELECT 
    t.Station_id                      AS ID,
    t.Station_name                    AS Station_name,
    t.Total_rides                     AS Total_rides,
    a.avg_duration_minutes            AS Avg_duration_minutes,
    c.capacity                        AS Capacity
  
FROM total_rides                      AS t
LEFT JOIN average_trip_duration       AS a
       ON t.Station_id = a.Station_id
INNER JOIN capacity                   AS c
        ON c.short_name = t.Station_id
ORDER BY Total_rides DESC;

-- Result 55 rows 4 columns.

-- 3. Take one of your CTEs from Task 1 and run it on its own, with just a plain SELECT * FROM that_cte_name swapped in as the final query, to confirm you can debug a single CTE in isolation.

WITH average_trip_duration AS (
    SELECT 
        t.start_station_id                                            AS Station_id,
        t.start_station                                               AS Station_name,
        ROUND(AVG(date_part('epoch', end_time - start_time) / 60), 1) AS avg_duration_minutes
    FROM trips                                                        AS t
    WHERE t.start_station_id IS NOT null
    GROUP BY Station_id, Station_name
)
SELECT * FROM average_trip_duration
ORDER BY avg_duration_minutes DESC;

-- Result 1107 rows 3 columns.

-- 4. Rewrite Task 2 as a single query with no CTEs at all — nested subqueries or a single complex join. Compare readability directly against the CTE version.

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

-- Result 55 rows 4 columns. The same result Mesier data.


--- BLOCK 3

-- 1. Build a three-stage chained CTE: first, per-station ride totals; second, attach neighborhood via a join to stations; third, compute the average ride total per neighborhood.

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
        MAX(t.start_station)AS Station_id,
        t.start_station     AS Station_name
        
    FROM trips              AS t
    LEFT JOIN station       AS s
           ON t.start_station_id = s.short_name
    WHERE t.start_station_id IS NOT null
      
    GROUP BY ALL
),
  
neighborhood_avg_raides AS (
  
  SELECT 
        s.neighborhood                                                   AS Neighborhood,
        ROUND(AVG(t.Total_rides),0)                                      AS avg_rides
        
    FROM total_rides AS t
    LEFT JOIN station AS s
           ON t.Station_id = s.short_name
    WHERE t.Station_id IS NOT null
  GROUP BY s.neighborhood
)
  
SELECT
  n.Neighborhood                    AS Neighborhood,
  SUM(t.Total_rides)                AS Total_rides,
  a.avg_rides                       AS Average_raides_per_station
FROM neighborhood_names             AS n
  LEFT JOIN total_rides             AS t 
         ON n.Station_id = t.Station_id
  LEFT JOIN neighborhood_avg_raides AS a
         ON n.Neighborhood = a.Neighborhood
WHERE n.Neighborhood IS NOT NULL
GROUP BY ALL
ORDER BY Total_rides DESC;

-- Result 42 rows 3 columns.

-- 2. Extend the chain with a fourth stage that filters stations whose ride total is above their neighborhood's average — the same question as Day 1, Block 4, Task 3, but now as a readable chain instead of a correlated subquery.

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
)

SELECT *
FROM above_avg_stations

ORDER BY Neighborhood_avg_rides DESC;

-- Result 348 rows 4 columns.
  
-- 4. Add a fifth stage to the chain that ranks the qualifying stations from Task 2 by how far above their neighborhood's average they are.

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

-- Result 348 rows 7 columns.


-- 6. Take one chained CTE and add a one-line comment above each stage explaining what that stage does, as if leaving it for someone else on the team.

WITH rides AS (                                    -- creating a common table expression (CTE) named 'rides' to store the aggregated ride data
  SELECT 
    date_part('year', t.start_time) AS Year,       -- selecting the year from the start_time column
    t.rider_type                    AS rider_type, -- selecting the rider type
    COUNT(t.bike_id)                AS Total_rides -- counting the total number of rides for each year and rider type
  FROM trips         AS t
     GROUP BY Year, rider_type                       -- grouping the results by year and rider type
                          ) 
  
Select                                              -- selecting data from the CTE and joining it with itself to get the total rides for the current year (2026)
  r.Year,
  r.rider_type,
  r.Total_rides,                                    -- selecting the total rides for each year and rider type from the CTE
  r2.Total_rides AS current_year_rides              -- selecting the total rides for the current year (2026) from the joined CTE
  FROM rides AS r
  LEFT join rides AS r2                             -- joining the CTE with itself to get the total rides for the current year (2026)
         ON r2.rider_type=r.rider_type AND r2.Year = '2026'
;

--- BLOCK 4

-- 2.Build the first CTE stage: per-station totals joined to neighborhood.

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
-- Select for check data:
-- SELECT * FROM station_totals
-- ORDER BY neighborhood, total_rides DESC

--- Result 1106 rows 4 columns.

  -- 3.Build the second stage: neighborhood averages, computed from the first stage.
  
neighborhood_averages AS (
    SELECT 
        neighborhood,
        COUNT(station_id)          AS Stations_quantity, -- count quantity of stations in the neighborhoods
        SUM(total_rides)           AS total_per_neighborhood, -- calculate quantity of rides in the neighborhoods
        ROUND(AVG(total_rides), 0) AS avg_rides_per_station  -- calculate average rides per station in the neighborhoods
    FROM station_totals
    GROUP BY neighborhood
)
,
-- Select for check data:
-- SELECT * FROM neighborhood_averages
-- ORDER BY avg_rides_per_station DESC;

--- Result 43 rows 3 columns.

-- 4.Build the third stage: each neighborhood's single busiest station, using the first two stages together.

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
-- Select for check data:
-- SELECT * FROM busiest_per_neighborhood
-- ORDER BY total_rides DESC;

--- Result 43 rows 4 columns.

-- 5.Combine everything into a final SELECT showing neighborhood, busiest station, its ride count, the neighborhood average, and the difference between them.

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
ORDER BY rides_above_average DESC; --sort results decending by difference between neighborhoods average and total station rides.

--- Result 42 rows 8 columns. EXCLUDE null neighborhood. Add comments

-- Reporter : Serhiy Dranko
-- Date : 2026-07-28
