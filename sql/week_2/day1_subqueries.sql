--- BLOCK 1
-- 1. Write a scalar subquery that computes the average station capacity, and use it in a WHERE clause to find all stations above that average.

  SELECT 
    
    s.short_name   AS station_id,
    s.name         AS station_name, 
    s.capacity     AS capacity
    
  FROM station     AS s
  WHERE s.capacity > (
                      SELECT 
                        AVG(sq.capacity) 
                      FROM station AS sq
                      )
    ORDER BY capacity DESC;

-- Result 341 rows 3 column. Subquery result 17.07 min.

-- 2.Do the same for below-average capacity, and compare the row counts of the two results against the total station count — do they add up correctly?

  SELECT 
    
    s.short_name   AS station_id,
    s.name         AS station_name, 
    s.capacity     AS capacity
    
  FROM station     AS s
  WHERE s.capacity < (
                      SELECT 
                        AVG(sq.capacity) 
                      FROM station AS sq
                      )
    ORDER BY capacity DESC;

-- Result 509 rows 3 column. Subquery result 17.07 min.
-- Yes, total station count is 850 rows (509+341=850). So we have 341 stations above Average and 509 stations below Average.

-- 3.Write a query that attaches the overall average capacity as a column on every row of stations, using a scalar subquery in SELECT.

  SELECT 
    
    s.short_name                                          AS station_id,
    s.name                                                AS station_name, 
    s.capacity                                            AS capacity,
    (SELECT ROUND(AVG(sq.capacity),0) FROM station AS sq) AS average_capacity
    
  FROM station                                            AS s
  
  ORDER BY capacity DESC;

-- Result 850 rows 4 column. Average capacity was rounded to whole number.

-- 4.Extend Task 3 by adding a second computed column: the difference between each station's actual capacity and the average — a positive or negative number showing how far above or below average it is.

  SELECT 
    
    s.short_name                                                        AS station_id,
    s.name                                                              AS station_name, 
    s.capacity                                                          AS capacity,
    (SELECT ROUND(AVG(sq.capacity),0) FROM station AS sq)               AS average_capacity,
    s.capacity - (SELECT ROUND(AVG(sq.capacity), 0) FROM station AS sq) AS difference
    
  FROM station                                                          AS s
  
  ORDER BY capacity DESC;

-- Result 850 rows 5 columns.

-- 5.Write a scalar subquery finding the single busiest station by total ride count, using stations_summary from Week 1.

  SELECT
    
    su.ID_station       AS station_id,
    su.station_name     AS station_name,
    su.total_rides      AS total_rides

  FROM stations_summary AS su
    WHERE total_rides = (SELECT MAX(total_rides) FROM stations_summary);

-- Result 1 row 3 columns. Subquery tooks Maximum value from total_rides in stations_summary.
    
-- 6.Use that subquery inside a WHERE clause on stations_summary to pull back the full row for the busiest station — without hardcoding its name.

  SELECT *
  FROM stations_summary AS su
    WHERE total_rides = (SELECT MAX(total_rides) FROM stations_summary);

-- Result 1 row 9 columns. Subquery tooks Maximum value from total_rides in stations_summary.

-- 7.Try writing a scalar subquery that would actually return more than one row (for example, station capacity without an aggregate), and confirm you get an error. Read the error message carefully — you'll want to recognize it later.

--  SELECT*
--  FROM stations_summary AS su
--  WHERE total_rides = (SELECT capacity FROM stations_summary);

-- Result:
--  Binder Error: Referenced column "capacity" not found in FROM clause!
--  Candidate bindings: "latitude", "casual_rides_percentage", "average_ride_duration_min", "station_capacity"
--  LINE 4:     WHERE total_rides = (SELECT capacity FROM stations_summary);

--- BLOCK 2
-- 1. Write a subquery that returns the names of all stations with capacity above 30, then use IN in a separate query to find all trips that started at one of those stations.

  SELECT 
      tr.start_station_id                                                                            AS ID_station,
      tr.start_station                                                                               AS station_name,
      COUNT(tr.bike_id)                                                                              AS total_rides,
      ROUND((SUM(CASE WHEN tr.rider_type = 'casual' THEN 1 ELSE 0 END) / COUNT(tr.bike_id) *100),0)  AS casual_rides_percentage, 
      ROUND((SUM(CASE WHEN tr.rider_type = 'member' THEN 1 ELSE 0 END) / COUNT(tr.bike_id) *100),0)  AS member_rides_percentage
  
  FROM trips AS tr
   WHERE tr.start_station_id IN (
                            SELECT 
                              s.short_name 
                            FROM station AS s 
                              WHERE s.capacity > 30
                           )
  GROUP BY ID_station, station_name
  ORDER BY total_rides DESC;

-- Result 43 rows 5 columns. Subquery tooks capacity value from capacity in station above 30 bikes.

-- 2. Rewrite Task 1 using EXISTS and a correlated condition instead of IN. Confirm the two versions return the same trips.

  SELECT 
      tr.start_station_id                                                                            AS ID_station,
      tr.start_station                                                                               AS station_name,
      COUNT(tr.bike_id)                                                                              AS total_rides,
      ROUND((SUM(CASE WHEN tr.rider_type = 'casual' THEN 1 ELSE 0 END) / COUNT(tr.bike_id) *100),0)  AS casual_rides_percentage, 
      ROUND((SUM(CASE WHEN tr.rider_type = 'member' THEN 1 ELSE 0 END) / COUNT(tr.bike_id) *100),0)  AS member_rides_percentage
  
  FROM trips AS tr
   WHERE EXISTS (
                  SELECT 1
                  FROM station AS s
                  WHERE s.short_name = tr.start_station_id
                    AND s.capacity > 30
                  )
  GROUP BY ID_station, station_name
  ORDER BY total_rides DESC;

-- Result 43 rows 5 columns. EXISTS checks capacity value from capacity in station above 30 bikes and check it with start_station_id in trips. The same result diffeerent way.

-- 3. Find all stations that have never appeared as a start_station in trips, using NOT IN.

   SELECT 
    s.short_name,
    s.name
   FROM station AS s
   WHERE s.short_name NOT IN (
                              SELECT tr.start_station_id 
                              FROM trips AS tr
                              );
-- Returns null result so switch to the name instead id for example.

  SELECT 
    s.short_name,
    s.name
   FROM station AS s
   WHERE s.name NOT IN (
                         SELECT tr.start_station
                         FROM trips AS tr
                         GROUP BY tr.start_station
                        );

-- Returns null result so we do not have station without rides.

-- 4. Rewrite Task 3 using NOT EXISTS instead. Compare the results — if they differ, that's the NULL pitfall from the theory file showing up in real data. Investigate whether trips.start_station actually contains any NULLs to confirm.

  SELECT 
    s.short_name,
    s.name
   FROM station AS s
    WHERE NOT EXISTS (
                       SELECT 1
                       FROM trips AS tr
                       WHERE s.short_name = tr.start_station_id
                      );

-- Returns null result so switch to the name instead id for example.

  SELECT 
    s.short_name,
    s.name
   FROM station AS s
    WHERE NOT EXISTS (
                       SELECT 1
                       FROM trips AS tr
                       WHERE s.name = tr.start_station
                      );

-- Returns 31971 Penrose Sq / Columbia Pike & S Barton St , this station was renamed a couple times. So we have conection by ID but it is defenetley the issue. 

-- 5. Write a query finding neighborhoods that contain at least one station with capacity over 40, using EXISTS.

  SELECT 
    
    su.ID_station       AS station_id,
    su.station_name     AS station_name,
    su.total_rides      AS total_rides,
    su.station_capacity AS station_capacity
    
  FROM stations_summary AS su
    WHERE EXISTS (
                   SELECT 1
                   FROM station AS s
                   WHERE s.short_name = su.ID_station
                    AND s.capacity > 40
                  );

-- Result 6 rows 4 columns.

-- 6. Find all rider types in trips that appear at high-capacity stations (capacity over 30) but do not appear at any low-capacity station (capacity 30 or under) — this needs both an IN/EXISTS and a NOT IN/NOT EXISTS working together.

  SELECT 
    tr.rider_type
  FROM trips AS tr
  WHERE EXISTS (
                SELECT 1
                FROM station AS s
                 WHERE s.short_name = tr.start_station_id
                 AND s.capacity > 30
                )
  AND NOT EXISTS (
                  SELECT 1
                  FROM trips AS tr2
                  LEFT JOIN station AS s2 
                     ON s2.short_name = tr2.start_station_id
                   WHERE tr2.rider_type = tr.rider_type
                     AND s2.capacity <= 30
                   )
   GROUP BY tr.rider_type;

-- Result 0 rows.

   SELECT tr.rider_type
    FROM trips AS tr
     WHERE tr.start_station_id IN (
                                   SELECT s.short_name 
                                    FROM station AS s 
                                     WHERE s.capacity > 30
                                   )
       AND tr.rider_type NOT IN (
                                 SELECT tr2.rider_type
                                  FROM trips AS tr2
                                   WHERE tr2.start_station_id IN (
                                                                  SELECT s2.short_name 
                                                                   FROM station AS s2 
                                                                    WHERE s2.capacity <= 30
                                                                  )
       AND tr2.rider_type IS NOT NULL
                                 );

-- Result 0 rows.

-- 7. Take one query from this block and rewrite it as an equivalent JOIN. Note which version reads more clearly for that specific question, and why.

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

-- Result 10 rows 4 columns.

-- 8. Write one sentence on when you'd now reach for EXISTS over IN by default, based on what Task 4 showed you.

-- I'd reach for EXISTS over IN by default whenever the subquery's column could contain NULLs, 
-- since NOT IN silently returns zero rows if even one NULL sneaks into the subquery's result, 
-- while NOT EXISTS (and EXISTS) evaluate row-by-row and are immune to that trap.

--- BLOCK 3
-- 1. Write an inner query that computes total rides per station (grouping trips by start_station), then wrap it in an outer query that computes the average of those per-station totals, per neighborhood — requiring a join to stations for the neighborhood column somewhere in the process.
-- 2.Give your subquery in FROM a clear alias, and confirm every column referenced in the outer query is unambiguous.

SELECT
    st.Neighborhood                                                         AS Neighborhood,
    ROUND(AVG(st.total_rides), 0)                                           AS Averege_rides_per_neighborhood
FROM (
        SELECT 
            COALESCE(n.neighborhood, 'Cluster history - Without geomarks')  AS Neighborhood,
            s.ID_Station                                                    AS Station_id,
            s.station_name                                                  AS Station_name,
            s.latitude                                                      AS Latitude,
            s.longitude                                                     AS Longitude,
            SUM(s.total_rides)                                              AS total_rides
        FROM stations_summary                                               AS s
        LEFT JOIN station_and_neighborhoods                                 AS n
               ON n.short_name = s.ID_Station
        GROUP BY n.neighborhood, s.ID_Station, s.station_name, s.latitude, s.longitude
        )                                                                   AS st
GROUP BY st.Neighborhood
ORDER BY Averege_rides_per_neighborhood DESC;

-- Result 43 rows 2 columns.

-- 3.Extend Task 1 to also show the minimum and maximum per-station ride totals within each neighborhood, alongside the average.

SELECT
    st.Neighborhood                                                         AS Neighborhood,
    MIN(st.total_rides)                                                     AS Minrides_per_neighborhood,
    ROUND(AVG(st.total_rides), 0)                                           AS Averege_rides_per_neighborhood,
    MAX(st.total_rides)                                                     AS Max_rides_per_neighborhood
FROM (
        SELECT 
            COALESCE(n.neighborhood, 'Cluster history - Without geomarks')  AS Neighborhood,
            s.ID_Station                                                    AS Station_id,
            s.station_name                                                  AS Station_name,
            s.latitude                                                      AS Latitude,
            s.longitude                                                     AS Longitude,
            SUM(s.total_rides)                                              AS total_rides
        FROM stations_summary                                               AS s
        LEFT JOIN station_and_neighborhoods                                 AS n
               ON n.short_name = s.ID_Station
        GROUP BY n.neighborhood, s.ID_Station, s.station_name, s.latitude, s.longitude
        )                                                                   AS st
GROUP BY st.Neighborhood
ORDER BY Averege_rides_per_neighborhood DESC;

-- Result 43 rows 4 columns.

-- 4.Write a query that finds the single highest-ridership station within each neighborhood — not overall — using a FROM subquery to first compute per-station totals, then filtering per neighborhood in the outer query.

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
        LEFT JOIN station_and_neighborhoods                                 AS n
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
                                    LEFT JOIN station_and_neighborhoods                                 AS n2
                                           ON n2.short_name = s2.ID_Station
                                    GROUP BY n2.neighborhood, s2.ID_Station
                                  ) AS nt
                            WHERE nt.Neighborhood = st.Neighborhood
                          )

ORDER BY st.total_rides DESC;

-- Result 36 rows 4 columns.

-- 5.Try solving Task 4 without any subquery, using only GROUP BY on the joined tables directly. Explain in a sentence why it can't fully answer the same question that way.

SELECT 
    COALESCE(n.neighborhood, 'Cluster history - Without geomarks') AS Neighborhood,
    s.ID_Station     AS Station_id,
    s.station_name   AS Station_name,
    SUM(s.total_rides) AS total_rides,
    RANK() OVER (PARTITION BY Neighborhood ORDER BY SUM(total_rides) DESC) AS Rank
  
FROM stations_summary AS s
LEFT JOIN station_and_neighborhoods AS n ON n.short_name = s.ID_Station
GROUP BY n.neighborhood, s.ID_Station, s.station_name
--HAVING Rank = '1'
ORDER BY Neighborhood, total_rides DESC;

-- We can't took only 1st stations Errror during window functions.

-- Binder Error: HAVING clause cannot contain window functions!
-- LINE 6:     RANK() OVER (PARTITION BY Neighborhood ORDER BY SUM(total_r...
            
-- 6.Take your Task 1 query and try flattening it into a single-level query with no subquery. If you can, note why; if you can't, note specifically what blocks you.

SELECT 
    COALESCE(n.neighborhood, 'Cluster history - Without geomarks') AS Neighborhood,
    ROUND(AVG(s.total_rides), 0) AS Averege_rides_per_neighborhood
FROM stations_summary AS s
LEFT JOIN station_and_neighborhoods AS n ON n.short_name = s.ID_Station
GROUP BY n.neighborhood;

-- Result 43 rows 2 columns.

--- BLOCK 4
-- 1. Write a correlated subquery that attaches, to each row in stations, the count of trips starting there — without using a JOIN or GROUP BY in the outer query.

SELECT 
    s.short_name,
    s.name,
    (
        SELECT COUNT(*)
        FROM trips AS t
        WHERE t.start_station_id = s.short_name
    ) AS trip_count
FROM station AS s
ORDER BY trip_count DESC;

-- Result 850 rows 3 columns.

-- 2. Extend Task 1 to also attach the average ride duration for trips starting at each station, as a second correlated subquery column.

SELECT 
    s.short_name,
    s.name,
    (
      SELECT COUNT(*)
      FROM trips                                                                    AS t
        WHERE t.start_station_id = s.short_name
    )                                                                               AS trip_count,
    (
      SELECT ROUND(AVG(date_part('epoch', t2.end_time - t2.start_time) / 60), 2)
      FROM trips                                                                    AS t2
        WHERE t2.start_station_id = s.short_name
    )                                                                               AS avg_duration_minutes
  
FROM station                                                                         AS s
ORDER BY trip_count DESC;

-- Result 850 rows 4 columns.

-- 3. Write a correlated subquery that finds all stations whose ride count is above the average ride count for their own neighborhood — not the overall average. This should reference both the outer row's neighborhood and station.

SELECT 
    n.neighborhood,
    n.ID_station,
    n.station_name,
    n.total_rides
FROM neighborhoods_summary AS n
WHERE n.total_rides > (
    SELECT AVG(nh.total_rides)
    FROM neighborhoods_summary AS nh
    WHERE nh.neighborhood = n.neighborhood
)
ORDER BY n.neighborhood, n.total_rides DESC;

-- Result 351 rows 4 columns.

-- 4. Time, even roughly, how Task 3 feels to write compared to Block 3's neighborhood-based queries. Which approach would you reach for first next time, and why?

-- This query was much faster to write than Block 3, mostly because neighborhoods_summary already has everything pre-joined and pre-aggregated — no COALESCE, no rebuilding joins, just one WHERE and a self-referencing subquery. 
-- Block 3 took longer because I was still constructing that join from raw tables and debugging alias mismatches along the way. Next time I'd reach for a pre-built summary table first whenever one exists, since the actual analysis logic is simple once the data is already flat.
-- I'd only go back to the full LEFT JOIN + GROUP BY chain from raw tables when I need to build that summary table in the first place.

-- 5. Rewrite Task 1 as a LEFT JOIN with GROUP BY instead, and compare both the query and the result. Do they produce the same numbers for stations with zero trips?

SELECT 
    s.short_name,
    s.name,
    COUNT(t.bike_id) AS trip_count
FROM station AS s
LEFT JOIN trips AS t 
       ON t.start_station_id = s.short_name
GROUP BY s.short_name, s.name
ORDER BY trip_count DESC;

-- Result 850 rows 3 columns. Yes they are the same.

-- 6. Identify one question from earlier this week (Week 1) that would have been easier to answer with a correlated subquery than with the join-based approach you actually used. Write the correlated version now.

--- WEEK 1 DAY 3 Block 3 Task 3 Every station with more than 5,000 total rides across the full seven years, using GROUP BY and HAVING. Result 561 rows 2 columns.

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

-- Result 561 rows 2 columns.These are simply two different ways of formulating the same question and not an improvement/worsening of one by the other.

-- 7. Write two or three sentences distinguishing correlated from non-correlated subqueries in your own words — not the definition from the theory file, but how you'd explain it to someone who hasn't read it.

--- Basically: non-correlated is "calculate this one number first, then use it everywhere," while correlated is "for each row, ask a fresh, personalized question."
--- A non-correlated subquery is completely self-contained. 
--- A correlated subquery can't do that, because it reaches back into the outer query for a value (like "this row's neighborhood") and uses it in its own filter.


-- Reporter : Serhiy Dranko
-- Date : 2026-07-27
