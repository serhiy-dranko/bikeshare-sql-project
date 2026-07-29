--- BLOCK 1
-- 1. Run SELECT COUNT(*) FROM trips and SELECT COUNT(duration) FROM trips side by side. If the numbers differ, you have NULL durations — note how many.

SELECT 
  COUNT(*) AS total_rows, 
  COUNT(duration) AS rows_with_duration
FROM trips;

-- Binder Error: Referenced column "duration" not found in FROM clause!
-- Candidate bindings: "end_station", "start_station", "start_station_id", "end_station_id", "end_time"
-- LINE 3:   COUNT(duration) AS rows_with_duration
-- We definitely need "duration" column in 'trips' table

-- Result after creating "duration" column:
--- 1 column 1 row
--- total_rows 31937007 and rows_with_duration 31937007 previous version have 31937071 rows we have 64 rows less. So we have 64 rows NULL durations or Duplicates between files.
                
-- 2. Try filtering WHERE duration = NULL and confirm it returns nothing, even though NULL durations exist. Then rewrite it correctly with IS NULL.

SELECT 
  COUNT(*)
FROM trips
WHERE duration IS NULL;

-- Result 1 row 1 column. Value 0.

-- 3. Find every column in trips and stations that can contain NULL, by running IS NULL counts on each candidate column. Keep a running list.

SELECT
 bike_id,
 start_station_id,
 start_station,
 end_station_id,
 end_station 
FROM trips
WHERE start_station IS NULL OR end_station IS NULL;

-- Result over 50K rows 5 columns.

-- Query with counts of them

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

-- Result 2 rows 2 columns.

-- 4. Revisit your Week 1, Day 4, Block 3 LEFT JOIN between trips and stations. Confirm again how many rows have NULL in a stations column, and cross-check it against your notes from that day.

--- "Unknown_count" Column in row Left join from Week 1, Day 4, Block 3, Task 5 show the same result as 'COUNT(*)' in 'start is null' in condition column - 3,951,423 rows 12,37 % from whole data. end_station 4,149,857 rows 12,99 % from whole data.

-- 5. Write a query using NOT IN against a column you now know can contain NULL (from Task 3), and confirm whether it silently returns zero or fewer rows than expected — this is the Day 1 pitfall, now demonstrated on purpose.

SELECT 
  COUNT(*)
FROM trips AS t 
WHERE t.start_station_id NOT IN ( SELECT
                                   end_station_id
                                FROM trips AS t2
                                WHERE end_station IS NOT NULL
                                GROUP BY ALL
);
-- Result 1 row 1 column. Value 0.

-- 6. Rewrite Task 5 using NOT EXISTS with a correlated subquery, and confirm it returns the correct, non-empty result.

SELECT 
  COUNT(*)
FROM trips AS t 
WHERE NOT EXISTS (
    SELECT 1 FROM trips AS t2 
    WHERE t2.end_station_id = t.start_station_id
);

-- Result 1 row 1 column. Value 3,951,423 rows. Show us Nulls in start_station_id


--- BLOCK 2
-- 1. Write a query selecting neighborhood from a joined trips/stations result, wrapped in COALESCE(neighborhood, 'Unknown'), and confirm rows that previously showed NULL now show 'Unknown'.

       SELECT 
            COALESCE(n.neighborhood, 'Unknown')                             AS Neighborhood,
            t.start_station_id                                              AS Station_id,
            t.start_station                                                 AS Station_name,
            n.lat                                                           AS Latitude,
            n.lon                                                           AS Longitude,
            COUNT(t.bike_id)                                                AS total_rides
        FROM trips                                                          AS t
        LEFT JOIN station                                                   AS n
               ON n.short_name = t.start_station_id
        GROUP BY ALL;

-- Result 1108 rows 6 columns. Result returns 64 rows with 'Unknown' in "Neighborhood" column.

-- 2. Group that query by the COALESCEd neighborhood and count rides per group. Confirm 'Unknown' now appears as its own visible group instead of being dropped or hidden.
      
        SELECT 
            COALESCE(n.neighborhood, 'Unknown')                             AS Neighborhood,
            COUNT(t.bike_id)                                                AS total_rides
        FROM trips                                                          AS t
        LEFT JOIN station                                                   AS n
               ON n.short_name = t.start_station_id
        GROUP BY Neighborhood
        ORDER BY total_rides DESC;

-- Result 43 rows 2 columns. Result returns 4,893,918 rides (15.32 % from Total) with 'Unknown' in "Neighborhood" column.

-- 3. Compare the total row count of this grouped result against a version that grouped by raw neighborhood without COALESCE. Confirm the NULL group's rides are now accounted for somewhere instead of vanishing.
       
        SELECT 
            'With COALESCE'                                                 AS QUERY,
            COALESCE(n.neighborhood, 'Unknown')                             AS Neighborhood,
            COUNT(t.bike_id)                                                AS total_rides
        FROM trips                                                          AS t
        LEFT JOIN station                                                   AS n
               ON n.short_name = t.start_station_id
        WHERE n.neighborhood IS NULL
        GROUP BY ALL
        
        UNION ALL
        SELECT 
            'Without COALESCE'                                              AS QUERY,
            n.neighborhood                                                  AS Neighborhood,
            COUNT(t.bike_id)                                                AS total_rides
        FROM trips                                                          AS t
        LEFT JOIN station                                                   AS n
               ON n.short_name = t.start_station_id
        WHERE n.neighborhood IS NULL
        GROUP BY ALL;

-- Result 2 rows 2 columns. Values in "total_rides" equal in bouth variants so that is mean COALESCE works properly.

-- 4. Apply COALESCE to any duration-related NULLs you found in Block 1, using a reasonable fallback (for example, the overall average duration, computed with a scalar subquery from Day 1). Justify the fallback choice in one sentence.

SELECT
 bike_id, 
 start_time,
 end_time,
 duration
FROM trips 
Where start_time IS NULL 
   OR end_time   IS NULL 
   OR duration   IS NULL;

-- Result 0 rows 0 columns. IN our Data we do not have nulls in 'trips' table. 
--- So will try COALESCE in join table with Capacity values. 
--- For this task I'll delete COALESCE from "station_capacity" column in 'stations_summary' table and rewrite it for giving nulls.
--- It will create 51 null rows in 'stations_summary' table.

SELECT
  neighborhood,
  ID_station,
  station_capacity
FROM stations_summary
where station_capacity IS NULL;

-- Result 51 rows 3 columns. Check that works.

WITH station_capacity AS(
    SELECT
       s.neighborhood,
       s.ID_station,
       COALESCE(s.station_capacity,0)          AS capacity
     FROM stations_summary AS s
     GROUP BY ALL
                          )
     SELECT
      n.neighborhood                           AS Neighborhood,
      ROUND(AVG(c.capacity),0)                 AS Neighborhood_capacity
                 
     FROM stations_summary                     AS n
     LEFT JOIN station_capacity                AS c
            ON n.ID_station = c.ID_station
     GROUP BY n.neighborhood
     HAVING Neighborhood_capacity = 0;

-- Result 1 row 2 columns. Neighborhood_capacity equal to 0.
--- During appling HAVING Neighborhood_capacity = 0 we can see that COALESCE is working in 'station_capacity' because before 'Cluster history - Without geomarks' have NULL's in "station_capacity" column.

-- 5. Try chaining three arguments in a single COALESCE on a column of your choice, even if the third argument is just a hardcoded default like 0 or 'Unknown'.

       SELECT 
            CASE WHEN t.start_station_id IS null THEN NULL ELSE 'With start point' END     AS Null_column,
            t.start_station_id                                                             AS Station_id,
            t.start_station                                                                AS Station_name,
            COUNT(t.bike_id)                                                               AS total_rides,
            COALESCE(Null_column,t.start_station_id,t.start_station,'Without start point') AS start_point_mark
         
        FROM trips                                                                         AS t
        WHERE t.start_station_id IS NULL OR t.start_station IS NULL
        GROUP BY ALL;

-- Result 1 row 5 columns.

-- 6. If any text columns contain placeholder values like 'N/A' or empty strings instead of real NULLs, use NULLIF to convert them to actual NULLs first, then COALESCE them to your chosen default.

         SELECT 
            
            t.start_station_id                                                             AS Start_station_id,
            t.start_station                                                                AS Start_station_name,
            t.end_station_id                                                               AS End_station_id,
            t.end_station                                                                  AS End_station_name,
            COUNT(t.bike_id)                                                               AS total_rides
            
         
        FROM trips                                                                         AS t
        WHERE t.start_station_id Like 'N/A'
           OR t.start_station    Like 'N/A'
           OR t.end_station_id   Like 'N/A'
           OR t.end_station      Like 'N/A'
        GROUP BY ALL;

-- Result 0 row 0 columns. We do not have 'N/A'

        SELECT 
            CASE WHEN t.start_station_id IS null THEN NULL ELSE 'With start point' END     AS Null_column,
            NULLIF(t.start_station_id, 'N/A')                                              AS Station_id, -- add funktion for demonstration but we do not have N/A so we have the same result
            t.start_station                                                                AS Station_name,
            COUNT(t.bike_id)                                                               AS total_rides,
            COALESCE(Null_column,t.start_station_id,t.start_station,'Without start point') AS start_point_mark
         
        FROM trips                                                                         AS t
        WHERE t.start_station_id IS NULL OR t.start_station IS NULL
        GROUP BY ALL;
-- Result 1 row 5 columns.

-- 7. Write one sentence on a case where you'd deliberately choose not to COALESCE a NULL — where leaving it as NULL, and filtering it out explicitly, is more honest than papering over it with a default.

--- I think when calculating the average trip duration, you should leave NULL ride times as NULL rather than replacing them with 0 — because AVG() correctly ignores NULLs, 
---  while COALESCEing to 0 would drag the average down and misrepresent the true typical ride length.

--- BLOCK 3
-- 1. Write a CASE WHEN that buckets stations into capacity tiers (for example, Small / Medium / Large), with an ELSE catching anything unmatched, including NULL capacity.

SELECT
  short_name   AS station_id,
  name         AS station_name,
  capacity     AS station_capacity,
  CASE
    WHEN station_capacity > 40 THEN 'Large'
    WHEN station_capacity > 20 THEN 'Medium'
    WHEN station_capacity > 0  THEN 'Small'
    ELSE 'Unknown'
  END AS capacity_tier
FROM station;

-- Result 851 rows 4 columns.

-- 2.Group stations by that tier and count how many fall into each — including the ELSE bucket.

SELECT
  
  CASE
    WHEN capacity > 40 THEN 'Large'
    WHEN capacity > 20 THEN 'Medium'
    WHEN capacity > 0  THEN 'Small'
    ELSE 'Unknown'
  END AS capacity_tier,
  COUNT(short_name)   AS station_quantity
  
FROM station
  GROUP BY capacity_tier
  ORDER BY station_quantity DESC;

-- Result 3 rows 2 columns.

--- In that case we can not see 'Unknown' because 'station' table this is a table direct from JSON file. Switch to the stations_summary.

SELECT

CASE
    WHEN station_capacity > 40 THEN 'Large'
    WHEN station_capacity > 20 THEN 'Medium'
    WHEN station_capacity > 0  THEN 'Small'
    ELSE 'Unknown'
  END AS capacity_tier,
  COUNT(ID_station)   AS station_quantity
  
FROM stations_summary
  GROUP BY capacity_tier
  ORDER BY station_quantity DESC;

-- Result 4 rows 2 columns. 'Unknown' tier has 51 stations. 

--- This is exactly the same as in Week-2 Day-3 Block-2 TASK-4 Result 51 rows. So here we can see ours stations wich not conected to the JSON data.

-- 3.Write a CASE WHEN that buckets trip duration into ranges (for example, under 10 min, 10–30 min, over 30 min), and count trips per bucket.

        SELECT 
      
            CASE
              WHEN t.duration < 0                         THEN 'Negative'
              WHEN t.duration < 10                        THEN 'under 10 min'
              WHEN t.duration >= 10 AND  t.duration <= 30 THEN '10–30 min'
              WHEN t.duration > 30 AND  t.duration < 1440 THEN 'over 30 min'
              WHEN t.duration > 1440                      THEN 'over 24 h'
            ELSE 'Unknown'
            END                                                                AS duration_buckets,
            COUNT(t.bike_id)                                                   AS total_rides
          
        FROM trips                                                             AS t
        LEFT JOIN station                                                      AS n
               ON n.short_name = t.start_station_id
        GROUP BY ALL
        ORDER BY total_rides DESC;

-- Result 5 rows 2 columns. under 10 min 47,79 % of our rides during 2019 - mid 2026. 8712 rows have negative duration.

-- 4.Use COUNT(CASE WHEN ... THEN 1 END) to compute, in a single query, the number of casual rides and member rides per neighborhood — no separate filtered queries, no GROUP BY on rider type itself.

        SELECT 
            COALESCE(n.neighborhood, 'Unknown')                             AS Neighborhood,
            SUM(
            CASE
              WHEN t.rider_type = 'casual' THEN 1 
               ELSE 0 END)                                                  AS casual_rides,
            SUM(
            CASE
              WHEN t.rider_type = 'member' THEN 1 
               ELSE 0 END)                                                  AS member_rides,
  
            COUNT(t.bike_id)                                                AS total_rides
        FROM trips                                                          AS t
        LEFT JOIN station                                                   AS n
               ON n.short_name = t.start_station_id
        GROUP BY ALL
        ORDER BY member_rides DESC;

-- Result 43 rows 4 columns. Cluster 8 is the most popular in Washigton DC. 2,889,564 rides. 67.9 % of rides by member type.

-- 5.Extend Task 4 to add a third conditional count for any rider type value that doesn't cleanly match either of the two you expected — this surfaces inconsistent or unexpected values in the column.

         SELECT 
            COALESCE(n.neighborhood, 'Unknown')                             AS Neighborhood,
            SUM(
            CASE
              WHEN t.rider_type = 'casual' THEN 1 
               ELSE 0 END)                                                  AS casual_rides,
            SUM(
            CASE
              WHEN t.rider_type = 'member' THEN 1 
               ELSE 0 END)                                                  AS member_rides,
           SUM(
            CASE
              WHEN t.rider_type NOT IN ('casual', 'member') THEN 1 
               ELSE 0 END)                                                  AS other_rides,
  
            COUNT(t.bike_id)                                                AS total_rides
        FROM trips                                                          AS t
        LEFT JOIN station                                                   AS n
               ON n.short_name = t.start_station_id
        GROUP BY ALL
        HAVING other_rides > 0;

-- Result 0 rows 0 columns. HAVING other_rides > 0 give us info about other type of rider.

-- 6.Investigate what Task 5 actually turned up. Are there genuinely a third rider type, inconsistent capitalization, or something else? Note it.

--- If we do not use LOWER("Member type") in 'trips_legacy' table it will calculate all rides from 'trips_legacy' table because "Member type" was like Member and Casual.

-- 7.Write a CASE WHEN that labels each trip as 'Weekday' or 'Weekend' based on its start date, and use it to compare ride counts between the two.

         SELECT 
            
            CASE 
              WHEN DAYOFWEEK(t.start_time) IN (0, 6) THEN 'Weekend'
               ELSE 'Weekday'
                END                                                           AS day_type,
            COUNT(t.bike_id)                                                  AS total_rides
          
        FROM trips                                                             AS t
        LEFT JOIN station                                                      AS n
               ON n.short_name = t.start_station_id
        
        GROUP BY day_type
        ORDER BY total_rides DESC;

-- Result 2 rows 2 columns.

-- 8.Combine two CASE WHEN expressions in one query — capacity tier and duration bucket, for example — to build a small cross-tabulated summary in a single SELECT.

        SELECT 
            CASE
              WHEN s.capacity > 40 THEN 'Large'
              WHEN s.capacity > 20 THEN 'Medium'
              WHEN s.capacity > 0  THEN 'Small'
              ELSE 'Unknown'
            END                                                               AS capacity_tier,
        
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



--- BLOCK 5 answears saved in markdowns in notes
-- Reporter : Serhiy Dranko
-- Date : 2026-07-29



