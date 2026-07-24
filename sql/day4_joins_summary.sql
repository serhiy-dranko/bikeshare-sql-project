--- This file is used to JOIN the data for the SQL exercises in Day 4 of the Dataskools SQL course.

--- Block 1: 

-- 1. Confirm the column that identifies a station in `stations` (likely a station ID or name) and confirm the matching column exists in `trips` as `start_station` or `end_station`.

            SELECT * FROM station limit 1;
            SELECT * FROM trips limit 1;

-- short_name FROM station equal to start_station_id AND end_station_id FROM trips.
-- name FROM station equal to start_station AND end_station FROM trips.

-- 2. A basic `INNER JOIN` between `trips` and `stations`, matching on station name or ID, and pull back 10 rows to see what the combined result looks like.
-- 4. Join `trips` to `stations` on `start_station`, and separately, join on `end_station`.

              SELECT
                
                st.short_name,
                tr.start_station_id,
                st.name,
                tr.start_station
                
              FROM trips AS tr
              
              INNER JOIN station AS st ON tr.start_station_id = st.short_name -- this join is based on the start station ID from trips matching the short name from stations.
              
              GROUP BY ALL;

--Result 1043 rows 4 columns
        
              SELECT
                
                st.short_name,
                tr.end_station_id,
                st.name,
                tr.end_station
                
              FROM trips AS tr
              
              INNER JOIN station AS st ON tr.end_station_id = st.short_name -- this join is based on the end station ID from trips matching the short name from stations.
              
              GROUP BY ALL;

--Result 1043 rows 4 columns

-- 3. Select a useful columns from each table in your joined query — ride details from `trips`, capacity and neighborhood from `stations`.

              SELECT
                
                tr.start_station_id                                                                            AS ID_station,
                tr.start_station                                                                               AS Station_name,
                COUNT(tr.bike_id)                                                                              AS total_rides,
                ROUND((SUM(CASE WHEN tr.rider_type = 'casual' THEN 1 ELSE 0 END) / COUNT(tr.bike_id) *100),0)  AS casual_rides_percentage,
                ROUND(AVG(date_part('epoch', tr.end_time - tr.start_time) / 60),0)                             AS average_ride_duration_min,
                st.capacity                                                                                    AS capacity, -- the capacity of the station from the stations table
                st.lat                                                                                         AS latitude, -- the latitude of the station from the stations table
                st.lon                                                                                         AS longitude -- the longitude of the station from the stations table
                
              FROM trips               AS tr
              
              INNER JOIN station       AS st 
                ON tr.start_station_id = st.short_name
              
              GROUP BY ID_station,                        -- grouping by columns to aggregate the data correctly
                       Station_name,
                       capacity,
                       latitude,
                       longitude
              ORDER BY total_rides DESC;

--Result 1043 rows 8 columns

--5. Count distinct stations appear in `trips` VS how many rows exist in `stations`.

              SELECT 
                'trips'                                AS Table_name,   -- this is a label to indicate the source of the count
                COUNT(DISTINCT tr.start_station_id)    AS Unique_count
                FROM trips                             AS tr
              UNION ALL                                                 -- this combines the results of two queries into a single result set
              SELECT
                'station'                              AS Table_name,   -- this is a label to indicate the source of the count
                COUNT(DISTINCT st.short_name)          AS Unique_count
                FROM station                           AS st;

-- Result 2 rows 2 columns Trips show more stations compare to station_info. 
-- Three reasons for this: 
    -- 1.station_info actual data do not include Closed stations. 
    -- 2.We have misspeling in start_station AND end_station FROM trips wich create duplicates in distinct count
    -- 3.When our stations change the name.

--6. Join `trips` to `stations` and filter to rides that started at stations with a capacity above a specific number.

              SELECT
                t.start_station_id                                                                           AS ID_station,
                t.start_station                                                                              AS station_name,
                COUNT(t.bike_id)                                                                             AS total_rides,
                ROUND((SUM(CASE WHEN t.rider_type = 'casual' THEN 1 ELSE 0 END) / COUNT(t.bike_id) *100),0)  AS casual_rides_percentage,
                ROUND(AVG(date_part('epoch', t.end_time - t.start_time) / 60),0)                             AS average_ride_duration_min,
                AVG(st.capacity)                                                                             AS station_capacity
                                
              FROM trips                                                                                     AS t 

              JOIN station                                                                                   AS st
                ON t.start_station_id = st.short_name
              
              WHERE t.start_station is not null
                   AND t.end_time > t.start_time
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) < 1440
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) > 1
              
              GROUP BY ID_station, station_name
              HAVING station_capacity >= 40 -- this filters the results to only include stations with a capacity of 40 or more bikes.
              ORDER BY total_rides DESC;

-- Result 8 rows 6 columns Trips show more stations compare to station_info.


--7. Join `trips` to `stations` and group by neighborhood (or region, depending on what the station file provides), counting total rides per neighborhood.

             SELECT
                t.start_station_id                                                                           AS ID_station,
                t.start_station                                                                              AS station_name,
                st.lat                                                                                       AS latitude,
                st.lon                                                                                       AS longitude,
                COUNT(t.bike_id)                                                                             AS total_rides,
                ROUND((SUM(CASE WHEN t.rider_type = 'casual' THEN 1 ELSE 0 END) / COUNT(t.bike_id) *100),0)  AS casual_rides_percentage,
                ROUND(AVG(date_part('epoch', t.end_time - t.start_time) / 60),0)                             AS average_ride_duration_min,
                AVG(st.capacity)                                                                             AS station_capacity
                                
              FROM trips                                                                                     AS t 

              INNER JOIN station                                                                             AS st
                ON t.start_station_id = st.short_name
              
              WHERE t.start_station is not null
                   AND t.end_time > t.start_time
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) < 1440
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) > 1
                   -- Filter for 5-10 blocks in Center of Washington DC --
                   AND (st.lat BETWEEN 38.8850 AND 38.9050)   -- this filters the results to only include stations within a specific latitude range in Washington DC
                   AND (st.lon BETWEEN -77.0464 AND -77.0264) -- this filters the results to only include stations within a specific longitude range in Washington DC
              
              GROUP BY ID_station, station_name, latitude, longitude
              ORDER BY total_rides DESC;

-- Result 42 rows 8 columns during JOIN

--8. The same join using `RIGHT JOIN` instead of `INNER JOIN`.

              SELECT
                t.start_station_id                                                                           AS ID_station,
                t.start_station                                                                              AS station_name,
                st.lat                                                                                       AS latitude,
                st.lon                                                                                       AS longitude,
                COUNT(t.bike_id)                                                                             AS total_rides,
                ROUND((SUM(CASE WHEN t.rider_type = 'casual' THEN 1 ELSE 0 END) / COUNT(t.bike_id) *100),0)  AS casual_rides_percentage,
                ROUND(AVG(date_part('epoch', t.end_time - t.start_time) / 60),0)                             AS average_ride_duration_min,
                AVG(st.capacity)                                                                             AS station_capacity
                                
              FROM trips                                                                                     AS t 

              RIGHT JOIN station                                                                             AS st
                ON t.start_station_id = st.short_name
              
              WHERE t.start_station is not null
                   AND t.end_time > t.start_time
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) < 1440
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) > 1
                   -- Filter for 5-10 blocks in Center of Washington DC --
                   AND (st.lat BETWEEN 38.8850 AND 38.9050) 
                   AND (st.lon BETWEEN -77.0464 AND -77.0264)
              
              GROUP BY ID_station, station_name, latitude, longitude
              ORDER BY total_rides DESC;

-- Result 42 rows 8 columns during RIGHT JOIN the same result as JOIN. 
-- That's means we do not have Stations without Rite data.

--9. Write one sentence describing, in plain language, what a join is actually doing to the two tables — not the SQL syntax, but the underlying operation.
--
-- A join takes two separate tables and, for each row in one table, finds the row's in the other table that share a matching value in some common column, 
-- then combines those matching rows side by side into a single wider row — effectively stitching together related information that was split across two places.

-- Block 2:

-- 1. Rewrite Block 1 join using table aliases — `trips AS t` and `stations AS s` — and reference columns as `t.start_station` and `s.capacity` throughout.

              SELECT
                t.start_station_id                                                                           AS ID_station,
                t.start_station                                                                              AS station_name,
                s.lat                                                                                        AS latitude,
                s.lon                                                                                        AS longitude,
                COUNT(t.bike_id)                                                                             AS total_rides,
                ROUND((SUM(CASE WHEN t.rider_type = 'casual' THEN 1 ELSE 0 END) / COUNT(t.bike_id) *100),0)  AS casual_rides_percentage,
                ROUND(AVG(date_part('epoch', t.end_time - t.start_time) / 60),0)                             AS average_ride_duration_min,
                AVG(s.capacity)                                                                              AS station_capacity
                                
              FROM trips                                                                                     AS t -- alias for the trips table

              RIGHT JOIN station                                                                             AS s -- alias for the station table
                ON t.start_station_id = s.short_name
              
              WHERE t.start_station is not null
                   AND t.end_time > t.start_time
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) < 1440
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) > 1
                   -- Filter for 5-10 blocks in Center of Washington DC --
                   AND (s.lat BETWEEN 38.8850 AND 38.9050) 
                   AND (s.lon BETWEEN -77.0464 AND -77.0264)
              
              GROUP BY ID_station, station_name, latitude, longitude
              ORDER BY total_rides DESC;

-- Result 42 rows 8 columns during RIGHT JOIN

-- 2. Add a `WHERE` clause to a joined query that filters on a column from `trips`.

              SELECT
                t.start_station_id                                                                           AS ID_station,
                t.start_station                                                                              AS station_name,
                s.lat                                                                                        AS latitude,
                s.lon                                                                                        AS longitude,
                COUNT(t.bike_id)                                                                             AS total_rides,
                ROUND((SUM(CASE WHEN t.rider_type = 'casual' THEN 1 ELSE 0 END) / COUNT(t.bike_id) *100),0)  AS casual_rides_percentage,
                ROUND(AVG(date_part('epoch', t.end_time - t.start_time) / 60),0)                             AS average_ride_duration_min,
                AVG(s.capacity)                                                                              AS station_capacity
                                
              FROM trips                                                                                     AS t 

              RIGHT JOIN station                                                                             AS s
                ON t.start_station_id = s.short_name
              
              WHERE t.start_station is not null
                   AND t.end_time > t.start_time
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) < 1440
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) > 1
                   -- Filter for 5-10 blocks in Center of Washington DC --
                   AND (s.lat BETWEEN 38.8850 AND 38.9050) 
                   AND (s.lon BETWEEN -77.0464 AND -77.0264)
                   
                   AND t.rider_type = 'member'                   -- this filters the results to only include rides where the rider type is 'member'
              
              GROUP BY ID_station, station_name, latitude, longitude
              ORDER BY total_rides DESC;

-- Result 42 rows 8 columns during RIGHT JOIN
-- casual_rides_percentage show us 0 values witch conffirm us that we have only members in the data.

-- 3. A second `WHERE` condition filtering on a column from `stations`.

               SELECT
                
                t.start_station_id                                                                           AS ID_station,
                t.start_station                                                                              AS station_name,
                s.lat                                                                                        AS latitude,
                s.lon                                                                                        AS longitude,
                COUNT(t.bike_id)                                                                             AS total_rides,
                ROUND((SUM(CASE WHEN t.rider_type = 'casual' THEN 1 ELSE 0 END) / COUNT(t.bike_id) *100),0)  AS casual_rides_percentage,
                ROUND(AVG(date_part('epoch', t.end_time - t.start_time) / 60),0)                             AS average_ride_duration_min,
                AVG(s.capacity)                                                                              AS station_capacity
                                
              FROM trips                                                                                     AS t 

              RIGHT JOIN station                                                                             AS s
                ON t.start_station_id = s.short_name
              
              WHERE t.start_station is not null
                   AND t.end_time > t.start_time
                   -- Filter Duration Between 1 min and 24 hours --                 
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) < 1440
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) >= 1
                   -- Filter for 5-10 blocks in Center of Washington DC --
                   AND (s.lat BETWEEN 38.8850 AND 38.9050) 
                   AND (s.lon BETWEEN -77.0464 AND -77.0264)
                   -- Filter `rider_type` are member's --
                   AND t.rider_type = 'member'
              
              GROUP BY ID_station, station_name, latitude, longitude
              HAVING station_capacity >= 40                            -- this filters the results to only include stations with a capacity of 40 or more bikes.
              ORDER BY total_rides DESC;

-- Result 2 rows 8 columns during RIGHT JOIN
--   This is a perfect example. in result we have one Station in center Washington DC with one start_station_id but with two start_station with the same LEN Value. 
--   That's caused by renaming of the station. From 14th & D St NW / John A Wilson Building TO 14th & D St NW / Ronald Reagan Building in July 2023.
--   So better switch to the station name in station table.

-- 4. Move one of join conditions from the `ON` clause into the `WHERE` clause instead.

               SELECT
                
                t.start_station_id                                                                           AS ID_station,
                t.start_station                                                                              AS station_name,
                s.lat                                                                                        AS latitude,
                s.lon                                                                                        AS longitude,
                COUNT(t.bike_id)                                                                             AS total_rides,
                ROUND((SUM(CASE WHEN t.rider_type = 'casual' THEN 1 ELSE 0 END) / COUNT(t.bike_id) *100),0)  AS casual_rides_percentage,
                ROUND(AVG(date_part('epoch', t.end_time - t.start_time) / 60),0)                             AS average_ride_duration_min,
                AVG(s.capacity)                                                                              AS station_capacity
                                
              FROM trips                                                                                     AS t 

              INNER JOIN station                                                                             AS s
                ON t.start_station_id = s.short_name
              
              WHERE t.start_station_id = s.short_name -- this condition is moved from the ON clause to the WHERE clause.
                   AND t.end_time > t.start_time
                   -- Filter Duration Between 1 min and 24 hours --                 
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) < 1440
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) >= 1
                   -- Filter for 5-10 blocks in Center of Washington DC --
                   AND (s.lat BETWEEN 38.8850 AND 38.9050) 
                   AND (s.lon BETWEEN -77.0464 AND -77.0264)
                   -- Filter `rider_type` are member's --
                   AND t.rider_type = 'member'
              
              GROUP BY ID_station, station_name, latitude, longitude
              HAVING station_capacity >= 40
              ORDER BY total_rides DESC;

-- For INNER JOIN, ON vs WHERE gives the same result because unmatched rows are dropped either way. 
-- For LEFT JOIN, putting the condition in WHERE instead filters out the preserved NULL filled rows the join was supposed to keep, effectively turning it into an inner join. 
-- That's mean the placement matters there but not for INNER JOIN.

-- 5. A joined, aliased, filtered query that answers a specific question: total rides at stations with capacity over or equal to 40, for casual riders only, in a 2026 year.
                
              SELECT

                t.rider_type                                                                                 AS rider_type,
                t.start_station_id                                                                           AS ID_station,
                t.start_station                                                                              AS station_name,
                COUNT(t.bike_id)                                                                             AS total_rides,
                AVG(s.capacity)                                                                              AS station_capacity
                                
              FROM trips                                                                                     AS t 

              INNER JOIN station                                                                             AS s
                ON t.start_station_id = s.short_name
              
              WHERE date_part('year', start_time) = '2026'
                   AND t.start_station is not null
                   AND t.end_time > t.start_time
                   -- Filter Duration Between 1 min and 24 hours --                 
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) < 1440
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) >= 1
                   -- Filter `rider_type` are member's --
                   AND t.rider_type = 'casual'
              
              GROUP BY rider_type,ID_station, station_name
              HAVING station_capacity >= 40
              ORDER BY total_rides DESC;

-- 6. Add `GROUP BY`, aggregate functions, and rounding into a joined query with average ride duration per neighborhood, rounded to one decimal place.

              SELECT
                t.start_station_id                                                                           AS ID_station,
                t.start_station                                                                              AS station_name,
                s.lat                                                                                        AS latitude,
                s.lon                                                                                        AS longitude,
                COUNT(t.bike_id)                                                                             AS total_rides,
                ROUND((SUM(CASE WHEN t.rider_type = 'casual' THEN 1 ELSE 0 END) / COUNT(t.bike_id) *100),1)  AS casual_rides_percentage,
                AVG(s.capacity)                                                                              AS station_capacity,
                ROUND(AVG(date_part('epoch', t.end_time - t.start_time) / 60),1)                             AS average_ride_duration_min
                                
              FROM trips AS t 

              INNER JOIN station                                                                             AS s
                ON t.start_station_id = s.short_name  
              
              WHERE t.start_station is not null
                   AND t.end_time > t.start_time
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) < 1440
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) >= 1
                   -- Filter for 5-10 blocks in Center of Washington DC --
                   AND (s.lat BETWEEN 38.8850 AND 38.9050) 
                   AND (s.lon BETWEEN -77.0464 AND -77.0264)
              
              GROUP BY ID_station, station_name,latitude,longitude
              ORDER BY total_rides DESC;

-- 7. Fully clean: aliased tables, aliased output columns, and conditions ordered.
               
               -- Choose columns from trips table and create calculations for final resuls --
               SELECT
                
                t.start_station_id                                                                           AS ID_station,
                t.start_station                                                                              AS station_name,
                s.lat                                                                                        AS latitude,
                s.lon                                                                                        AS longitude,
                COUNT(t.bike_id)                                                                             AS total_rides, -- count total rides
                ROUND((SUM(CASE WHEN t.rider_type = 'casual' THEN 1 ELSE 0 END) / COUNT(t.bike_id) *100),0)  AS casual_rides_percentage, -- count casual rider's % to Total
                ROUND(AVG(date_part('epoch', t.end_time - t.start_time) / 60),0)                             AS average_ride_duration_min, -- calculate average duration
                AVG(s.capacity)                                                                              AS station_capacity -- show actual capacity
                                
              FROM trips                                                                                     AS t 
              -- Connecting to the Capacity data ---
              INNER JOIN station                                                                             AS s
                ON t.start_station_id = s.short_name

                 
                    -- Choose data only with station filled --
              WHERE t.start_station is not null 
                   -- Filter only possitive Duration's --
                   AND t.end_time > t.start_time
                   -- Filter Duration Between 1 min and 24 hours --                 
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) < 1440
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) >= 1
                   -- Filter for 5-10 blocks in Center of Washington DC by Latitude and Longitude --
                   AND (s.lat BETWEEN 38.8850 AND 38.9050) 
                   AND (s.lon BETWEEN -77.0464 AND -77.0264)
                   
              
              GROUP BY ID_station, station_name, latitude, longitude
              -- Filter Stantion's with capacity over 40 bikes at the moment --
              HAVING station_capacity >= 40
              -- Sort by quantity of rides --   
              ORDER BY total_rides DESC;

-- Block 3:

-- 1. Rewrite Block 1 join as a `LEFT JOIN` from `trips` to `stations`.

             SELECT
                
                st.short_name,
                tr.start_station_id,
                st.name,
                tr.start_station
                
              FROM trips AS tr
              
              LEFT JOIN station AS st ON tr.start_station_id = st.short_name
              
              GROUP BY ALL;

-- Result 1108 rows 4 columns during LEFT JOIN.

-- 2. Count rows in that `LEFT JOIN` have a `NULL` value in a `stations` column.

             SELECT
                
                st.short_name,
                tr.start_station_id,
                st.name,
                tr.start_station
                
              FROM trips AS tr
              
              LEFT JOIN station AS st ON tr.start_station_id = st.short_name

              WHERE st.short_name IS null AND tr.start_station_id IS NOT null
              
              GROUP BY ALL;

-- Result 64 rows 4 columns during LEFT JOIN.

-- 3. Asample of the distinct station names from `trips` that produced those `NULL`s.
                
                st.short_name,
                st.name,
                tr.start_station_id,
                tr.start_station,
                MAX(strftime(tr.start_time, '%d/%m/%Y')) AS last_date_recorded
                
              FROM trips AS tr
              
              LEFT JOIN station AS st ON tr.start_station_id = st.short_name

              WHERE st.short_name IS null AND tr.start_station_id IS NOT null -- this filters the results to only include rows where the station short name is null (indicating no match in the stations table) and the start station ID is not null (indicating a valid station ID in trips).
              
              GROUP BY ALL
              ORDER BY tr.start_station_id ASC;

-- Result 64 rows 4 columns during LEFT JOIN. We have last date records wich show us that last from the list was recorded in the end of 2025 AND 00000 22nd & H NW matched as disabled.
-- So we can say that is the list of stations witch were disabled. ALSO Reston Cmty Ctr/Hunters Woods Plaza has longer ID and MTL-ECO5-03 looks like a test station.

-- 4.  `COALESCE()` to replace `NULL`  values with a placeholder `'Unknown'`.
             SELECT
                
                COALESCE(st.short_name,'Unknown')                               AS short_name, -- this replaces any null values in the short_name column with the string 'Unknown'
                COALESCE(st.name,'Unknown')                                     AS name,       -- this replaces any null values in the name column with the string 'Unknown'
                tr.start_station_id,
                tr.start_station,
                MAX(strftime(tr.start_time, '%d/%m/%Y'))                        AS last_date_recorded
                
              FROM trips AS tr
              
              LEFT JOIN station AS st ON tr.start_station_id = st.short_name

              WHERE st.short_name IS null AND tr.start_station_id IS NOT null
              
              GROUP BY ALL
              ORDER BY tr.start_station_id ASC;

-- 5. Compare total ride counts between an `INNER JOIN` and a `LEFT JOIN` version of the same query — the difference in row count is exactly the set of rides with no station match.
              
              SELECT 
                'Left join'                                                                                        AS type, -- this is a label to indicate the type of join used in the query
                COUNT(*)                                                                                           AS Rows_count,
                COUNT(DISTINCT tr.bike_id)                                                                         AS Unique_count, -- this counts the number of unique bike IDs in the result set
                ROUND(SUM(CASE WHEN st.short_name IS null AND tr.start_station_id IS null THEN 1 ELSE 0 END),0)    AS Unknown_count -- this counts the number of rows where both the station short name and start station ID are null, indicating unmatched rides
                FROM trips                                                                                         AS tr
                LEFT JOIN station                                                                                  AS st 
                       ON tr.start_station_id = st.short_name
                GROUP BY ALL
              UNION ALL
              SELECT
                'Inner join'                                                                                       AS type, -- this is a label to indicate the type of join used in the query
                COUNT(*)                                                                                           AS Rows_count,
                COUNT(DISTINCT tr.bike_id)                                                                         AS Unique_count,
                ROUND(SUM(CASE WHEN st.short_name IS null AND tr.start_station_id IS null THEN 1 ELSE 0 END),0)    AS Unknown_count
                FROM trips                                                                                         AS tr
                INNER JOIN station                                                                                 AS st 
                        ON tr.start_station_id = st.short_name
                GROUP BY ALL;

-- 6. Decide, and justify in a sentence, whether an analysis of "rides by neighborhood" should use an `INNER JOIN` (only rides with a known station) or a `LEFT JOIN` with `COALESCE` (all rides, including unmatched ones grouped as unknown) — there's a real argument for either, depending on the question being asked.
--     Better use `LEFT JOIN` with `COALESCE` ant to avoid to many unknowns better uniton our station to the table with old stations but with mark disable.

-- 7. Check whether the unmatched-station trip data than the newer data, by filtering your `LEFT JOIN` `NULL` rows by year.

                SELECT 
                'Left join'                                                                                                       AS type,
                date_part('year', start_time)                                                                                     AS year,
                COUNT(*)                                                                                                          AS Rows_count,
                ROUND(SUM(CASE WHEN st.short_name IS null AND tr.start_station_id IS null THEN 1 ELSE 0 END),0)                   AS Unknown_count,
                ROUND((SUM(CASE WHEN st.short_name IS null AND tr.start_station_id IS null THEN 1 ELSE 0 END) / COUNT(*) *100),2) AS Unknown_percentage
                FROM trips                                                                                                        AS tr
                LEFT JOIN station                                                                                                 AS st 
                       ON tr.start_station_id = st.short_name
                GROUP BY ALL
                ORDER BY year ASC;

-- 8. Write a short note (two or three sentences) as if leaving it for the next person working on this data: what's unreliable about the station join, and what they should watch out for.

--  Use LEFT JOIN when you need the full ride history - it keeps every trip even when the station doesn't currently exist in the station table (e.g. it's since been closed, renamed, or renumbered), just with NULL station attributes for those rows. But here we can use Unknown marks during COALESCE. 
--  If you use INNER JOIN instead, you'll silently drop every ride to/from a station that isn't in the current station table.
--  Which quietly excludes closed or historical stations rather than flagging them. So ride counts and totals will look artificially low without any error to warn you. 
--  Always check the Unknown_count from the LEFT JOIN version first to see how much history would be lost before deciding an INNER JOIN is safe to use for a given analysis.

-- Block 4:


-- 1 Design the columns your summary table should have: station name, neighborhood, capacity, total rides, average duration, and percentage of casual riders are a reasonable starting set — adjust based on what you found interesting across the week.
-- 2 Write the full SELECT query that produces exactly those columns, using the join, aggregation, aliasing, and rounding skills from this week.
-- 3 Wrap that query in CREATE TABLE stations_summary AS SELECT ... to actually materialize it as a table in your database, instead of just viewing the result.            

             CREATE TABLE stations_summary AS
              SELECT
                t.start_station_id                                                                           AS ID_station,
                t.start_station                                                                              AS station_name,
                COALESCE(s.lat,'00.00')                                                                      AS latitude,
                COALESCE(s.lon,'00.00')                                                                      AS longitude,
                COUNT(t.bike_id)                                                                             AS total_rides, -- count total rides
                ROUND((SUM(CASE WHEN t.rider_type = 'casual' THEN 1 ELSE 0 END) / COUNT(t.bike_id) *100),0)  AS casual_rides_percentage, -- count casual rider's % to Total
                ROUND((SUM(CASE WHEN t.rider_type = 'member' THEN 1 ELSE 0 END) / COUNT(t.bike_id) *100),0)  AS member_rides_percentage, -- count member rider's % to Total
                ROUND(AVG(date_part('epoch', t.end_time - t.start_time) / 60),0)                             AS average_ride_duration_min, -- calculate average duration
                AVG(COALESCE(s.capacity,'0'))                                                                AS station_capacity -- show actual capacity
                                
              FROM trips                                                                                     AS t 
              -- Connecting to the Capacity data ---
              Left JOIN station                                                                              AS s
                ON t.start_station_id = s.short_name

                    -- Choose data only with station filled --
              WHERE t.start_station is not null 
                   -- Filter only possitive Duration's --
                   AND t.end_time > t.start_time
                   -- Filter Duration Between 1 min and 24 hours --                 
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) < 1440
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) >= 1
                                   
              GROUP BY ID_station, station_name, latitude, longitude
              -- Sort by quantity of rides --   
              ORDER BY total_rides DESC;

-- Result 1106 rows 9 columns.

-- 4 Query stations_summary directly and confirm it behaves like any other table — filter it, sort it, and check that it returns instantly compared to re-running the full join-and-aggregate query from scratch.

              select * from stations_summary;

-- Result 1106 rows 9 columns.

-- 5 Add a WHERE or HAVING condition to the original query and rebuild stations_summary with a minimum ride-count threshold, excluding very low-traffic stations from the summary entirely.


              CREATE OR REPLACE TABLE stations_summary AS
              SELECT
                t.start_station_id                                                                           AS ID_station,
                t.start_station                                                                              AS station_name,
                COALESCE(s.lat,'00.00')                                                                      AS latitude,
                COALESCE(s.lon,'00.00')                                                                      AS longitude,
                COUNT(t.bike_id)                                                                             AS total_rides, -- count total rides
                ROUND((SUM(CASE WHEN t.rider_type = 'casual' THEN 1 ELSE 0 END) / COUNT(t.bike_id) *100),0)  AS casual_rides_percentage, -- count casual rider's % to Total
                ROUND((SUM(CASE WHEN t.rider_type = 'member' THEN 1 ELSE 0 END) / COUNT(t.bike_id) *100),0)  AS member_rides_percentage, -- count member rider's % to Total
                ROUND(AVG(date_part('epoch', t.end_time - t.start_time) / 60),0)                             AS average_ride_duration_min, -- calculate average duration
                AVG(COALESCE(s.capacity,'0'))                                                                AS station_capacity -- show actual capacity
                                
              FROM trips                                                                                     AS t 
              -- Connecting to the Capacity data ---
              Left JOIN station                                                                              AS s
                ON t.start_station_id = s.short_name

                 
                    -- Choose data only with station filled --
              WHERE t.start_station is not null 
                   -- Filter only possitive Duration's --
                   AND t.end_time > t.start_time
                   -- Filter Duration Between 1 min and 24 hours --                 
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) < 1440
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) >= 1
                   -- Filter suspicios stations ---
                   AND t.start_station_id NOT IN ('00000', 'MTL-ECO5-03')
                   
                                   
              GROUP BY ID_station, station_name, latitude, longitude
              -- Filter capacity equal or over 100 redes per 7 years --
              HAVING total_rides >= 100
              -- Sort by quantity of rides --   
              ORDER BY total_rides DESC;

-- Result 1020 rows 9 columns.

-- 6 Time, even roughly, the difference between querying stations_summary directly versus rerunning the full joined aggregation each time. This is the same performance idea from earlier in the week — Power BI struggling with seven years of raw trips — now solved at the SQL layer instead.
-- 7 Decide what should happen if trips gets new data added later — would stations_summary need to be fully rebuilt, or could it be updated incrementally? You don't need to implement this, just reason through it in a few sentences; it's a preview of ideas Week 5 covers properly with dbt.
-- 8 Export or note the final row count and a few sample rows from stations_summary — this table is the actual deliverable for the week, not just a query result that disappears after the session ends.

               select * from stations_summary Limit 10;

-- Result 10 rows 9 columns.

-- Reporter : Serhiy Dranko
-- Date : 2026-07-22