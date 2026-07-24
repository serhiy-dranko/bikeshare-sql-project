--- This file is used to filter the data in the "trips" table based on specific criteria for the SQL exercises in Day 2 of the Dataskools SQL course.

--- Block 1: 

--- That query that select only the start_time, end_station and rider_type columns for the first 20 rows returns rides where, we don't have an end_station values by members riders that started their ride at either "Columbus Circle / Union Station" or "New Hampshire Ave & T St NW" and the bike type is not a docked bike. The results are ordered by start_time in ascending order.

SELECT 
  
  strftime(start_time, '%d/%m/%Y %H:%M:%S')   AS start_datetime, -- convert the start_time to a more readable format 
  start_station,
  end_station, 
  rider_type,
  bike_type
  
FROM trips 
  
WHERE (start_station = 'Columbus Circle / Union Station' OR start_station = 'New Hampshire Ave & T St NW') -- Filtered rides only for the stations 'Columbus Circle / Union Station' or 'New Hampshire Ave & T St NW'
  AND LOWER(rider_type) = 'member' -- Filtered rides only for the riders that are members
  AND end_station IS null -- Filtered rides only for the rides that don't have an end_station value
  AND bike_type !='docked_bike' -- Filtered rides only for the rides that are not docked bikes

ORDER BY start_time ASC -- sort the results by start_time in ascending order to get the earliest rides first.
  
LIMIT 20; -- select the first 20 rows of the result set to get the earliest rides that match the filtering criteria.

--- Block 2: 

-- 1. The 10 most recent rides in the table, ordered by start_time descending.
SELECT 
  
  bike_id,
  strftime(start_time, '%d/%m/%Y %H:%M:%S')   AS start_datetime, 
  start_station,
  end_station, 
  rider_type,
  bike_type
  
FROM trips 
  
ORDER BY start_time DESC -- sort the results by start_time in descending order to get the most recent rides first.
  
LIMIT 10; -- select the first 10 rows of the result set to get the 10 most recent rides.

-- 2. The 10 earliest rides in the table.

SELECT 
  
  bike_id,
  strftime(start_time, '%d/%m/%Y %H:%M:%S')   AS start_datetime, 
  start_station,
  end_station, 
  rider_type,
  bike_type
  
FROM trips 
  
ORDER BY start_time ASC -- sort the results by start_time in ascending order to get the earliest rides first.
  
LIMIT 10; -- select the first 10 rows of the result set to get the 10 earliest rides.

-- 3. The 10 longest rides by duration.

SELECT 
  
  bike_id,
  strftime(start_time, '%d/%m/%Y %H:%M:%S')   AS start_datetime, 
  strftime(end_time, '%d/%m/%Y %H:%M:%S')     AS end_datetime,
  start_station,
  end_station, 
  rider_type,
  bike_type,
  date_part('epoch', end_time - start_time) / 60 AS duration_minutes -- calculate the duration in minutes
  
FROM trips 
  
ORDER BY duration_minutes DESC -- sort the results by duration in descending order to get the longest rides first.
  
LIMIT 10; -- select the first 10 rows of the result set to get the 10 longest rides.

-- 4.Pull the 10 shortest rides

SELECT 
  
  bike_id,
  strftime(start_time, '%d/%m/%Y %H:%M:%S')   AS start_datetime, 
  strftime(end_time, '%d/%m/%Y %H:%M:%S')     AS end_datetime,
  start_station,
  end_station, 
  rider_type,
  bike_type,
  date_part('epoch', end_time - start_time) / 60 AS duration_minutes
  
FROM trips 

WHERE date_part('epoch', end_time - start_time) / 60 >0.00
  
ORDER BY duration_minutes ASC -- sort the results by duration in ascending order to get the shortest rides first.

LIMIT 10; -- select the first 10 rows of the result set to get the 10 shortest rides.

-- 5.Combine WHERE with ORDER BY and LIMIT: the 5 longest rides taken by casual riders only.

SELECT 
  
  bike_id,
  strftime(start_time, '%d/%m/%Y %H:%M:%S')   AS start_datetime, 
  strftime(end_time, '%d/%m/%Y %H:%M:%S')     AS end_datetime,
  start_station,
  end_station, 
  rider_type,
  bike_type,
  date_part('epoch', end_time - start_time) / 60 AS duration_minutes
  
FROM trips 

WHERE LOWER(rider_type) = 'casual'
  AND date_part('epoch', end_time - start_time) / 60 <= 1440 -- Filtered rides only less than or equal to 1440 minutes (24 hours) to avoid outliers in the data.
  
ORDER BY duration_minutes DESC
  
LIMIT 5;

-- !!!! WE HAVE HUGE DURATIONS IN THE DATA OVER HALF YEAR !!!!

-- 6. Combine WHERE with ORDER BY and LIMIT: the 5 most recent rides at one specific station.

SELECT 
  
  bike_id,
  strftime(start_time, '%d/%m/%Y %H:%M:%S')   AS start_datetime, 
  strftime(end_time, '%d/%m/%Y %H:%M:%S')     AS end_datetime,
  start_station,
  end_station, 
  rider_type,
  bike_type,
  date_part('epoch', end_time - start_time) / 60 AS duration_minutes
  
FROM trips 

WHERE start_station = 'Columbus Circle / Union Station'
  
ORDER BY start_time DESC
  
LIMIT 5; -- select the 5 most recent rides at the station 'Columbus Circle / Union Station'

-- 7. Try ordering by two columns at once — for example, rider_type first, then start_time descending within each group — and describe what changes about how the results are arranged.

SELECT 
  
  bike_id,
  strftime(start_time, '%d/%m/%Y %H:%M:%S')   AS start_datetime, 
  strftime(end_time, '%d/%m/%Y %H:%M:%S')     AS end_datetime,
  start_station,
  end_station, 
  rider_type,
  bike_type,
  date_part('epoch', end_time - start_time) / 60 AS duration_minutes
  
FROM trips 

WHERE start_station = 'Columbus Circle / Union Station' -- Filtered rides only for the station 'Columbus Circle / Union Station'
  
ORDER BY rider_type ASC, start_time DESC -- First, the results are ordered by rider_type in ascending order (casual riders first, then members), and within each rider_type group, the results are ordered by start_time in descending order (most recent rides first).
  
LIMIT 5;

--- Block 3: 

----------------------------------------------------------------------------- Text filtering (5 tasks) -------------------------------------------------------------------

-- 1. Use LIKE with a wildcard to find every station whose name contains a specific word Union at the beginning.

SELECT 
  
  start_station
  
FROM trips 

WHERE start_station LIKE 'Union%' -- filtered rides only for the stations that start with 'Union' (case-insensitive)
  
GROUP BY start_station;

-- 2. Test case sensitivity directly: filter for 'Union%' and separately for 'union%', and compare the row counts. Are they the same? 

SELECT 
  
  start_station
  
FROM trips 

WHERE start_station LIKE 'union%' -- filtered rides only for the stations that start with 'union' (case-insensitive)
  
GROUP BY start_station;

-- No, they are the different. 

-- 3. Use IN to filter for rides starting at any one of three named stations at once, 'Columbus Circle / Union Station','New Hampshire Ave & T St NW','Lincoln Memorial'.

SELECT 
  
    start_station,
    COUNT(bike_id) AS rides_qty
  
FROM trips 
  
WHERE start_station IN ('Columbus Circle / Union Station','New Hampshire Ave & T St NW','Lincoln Memorial') -- Filtered rides only for the stations that are in the list of three named stations
  
GROUP BY ALL
  
ORDER BY rides_qty DESC;

-- 4.Use NOT IN to exclude those same three stations.

SELECT 
  
    start_station,
    COUNT(bike_id) AS rides_qty
  
FROM trips 
  
WHERE start_station NOT IN ('Columbus Circle / Union Station','New Hampshire Ave & T St NW','Lincoln Memorial') -- Filtered rides only for the stations that are not in the list of three named stations
  
GROUP BY ALL
  
ORDER BY rides_qty DESC;

-- Find every station name containing a number (a digit anywhere in the name) using LIKE with a wildcard pattern 

SELECT 
    start_station,
    COUNT(bike_id) AS rides_qty
FROM trips 
WHERE start_station LIKE '%0%' -- filtered rides only for the stations that contain a number (a digit anywhere in the name)
   OR start_station LIKE '%1%'
   OR start_station LIKE '%2%'
   OR start_station LIKE '%3%'
   OR start_station LIKE '%4%'
   OR start_station LIKE '%5%'
   OR start_station LIKE '%6%'
   OR start_station LIKE '%7%'
   OR start_station LIKE '%8%'
   OR start_station LIKE '%9%'
GROUP BY ALL
ORDER BY rides_qty DESC;

-------------------------------------------------------------------------------Date filtering (5 tasks)----------------------------------------------------------------

-- 6.Pull every ride from a single calendar year — 2021 only, for example.

SELECT 
  
  bike_id,
  strftime(start_time, '%d/%m/%Y %H:%M:%S')   AS start_datetime, 
  strftime(end_time, '%d/%m/%Y %H:%M:%S')     AS end_datetime,
  start_station,
  end_station, 
  rider_type,
  bike_type,
  date_part('epoch', end_time - start_time) / 60 AS duration_minutes
  
FROM trips 

WHERE date_part('year', start_time) = 2021 -- Filtered rides only for the year 2021
  
ORDER BY start_time ASC
LIMIT 10; -- Just for faster query work for proper data delete limit

-- 7.Pull every ride from a single month across all seven years — every ride that happened in July, regardless of year.
SELECT 
  
  bike_id,
  strftime(start_time, '%d/%m/%Y %H:%M:%S')   AS start_datetime, 
  strftime(end_time, '%d/%m/%Y %H:%M:%S')     AS end_datetime,
  start_station,
  end_station, 
  rider_type,
  bike_type,
  date_part('epoch', end_time - start_time) / 60 AS duration_minutes
  
FROM trips 

WHERE date_part('month', start_time) = 7 -- Filtered rides only for the month of July (7)
  
ORDER BY start_time ASC; -- sort the results by start_time in ascending order to get the earliest rides first.

--8.Pull every ride between two specific dates using BETWEEN, then rewrite the same query using a pair of >= / <= conditions instead, and confirm both return the same row count.

SELECT 
  
  bike_id,
  strftime(start_time, '%d/%m/%Y %H:%M:%S')   AS start_datetime, 
  strftime(end_time, '%d/%m/%Y %H:%M:%S')     AS end_datetime,
  start_station,
  end_station, 
  rider_type,
  bike_type,
  date_part('epoch', end_time - start_time) / 60 AS duration_minutes
  
FROM trips 

WHERE start_time BETWEEN '2021-09-01' AND '2021-09-03' -- Filtered rides only for the rides that started between September 1, 2021 and September 3, 2021 (inclusive)
  
ORDER BY start_time ASC;

-- TOTAL 16246 rows

SELECT 
  
  bike_id,
  strftime(start_time, '%d/%m/%Y %H:%M:%S')   AS start_datetime, 
  strftime(end_time, '%d/%m/%Y %H:%M:%S')     AS end_datetime,
  start_station,
  end_station, 
  rider_type,
  bike_type,
  date_part('epoch', end_time - start_time) / 60 AS duration_minutes
  
FROM trips 

WHERE start_time >= '2021-09-01' AND start_time < '2021-09-03' -- Filtered rides only for the rides that started on or after September 1, 2021 and before September 3, 2021 (exclusive)
  
ORDER BY start_time ASC;

-- TOTAL 16246 rows

-- The same quantity of rows so this methods of data filtering are the same

--9.Extract just the year from start_time for a small sample of rows, and manually check a handful against the raw timestamp to confirm the extraction is accurate — especially across the legacy/modern schema boundary from Day 1, where timestamp formatting may not be identical.

SELECT 
  
  bike_id,
  strftime(start_time, '%d/%m/%Y %H:%M:%S')      AS start_datetime,
  strftime(start_time, '%Y')                     AS start_Year, -- extract the year from start_time
  strftime(end_time, '%d/%m/%Y %H:%M:%S')        AS end_datetime,
  start_station,
  end_station, 
  rider_type,
  bike_type,
  date_part('epoch', end_time - start_time) / 60 AS duration_minutes
  
FROM trips 

WHERE start_time >= '2020-03-31 23:20:00' AND start_time < '2020-04-01 03:00:00' -- Filtered rides only for the rides that started on or after March 31, 2020 23:20:00 and before April 1, 2020 03:00:00 (exclusive)

ORDER BY start_time ASC;

-- This time frame was chosen because it is right around the time when the legacy schema ended and the modern schema began, so it will allow us to check that the year extraction is accurate across both schemas.


--- 10. Write a query that returns ride counts for one specific station, run once per year (five or six separate queries, one per year, using only WHERE — no GROUP BY yet), and note the numbers side by sid

SELECT 
      COUNT(bike_id) AS rides_qty
FROM trips 
WHERE date_part('year', start_time) = 2019 AND start_station = 'Columbus Circle / Union Station';

-- TOTAL 58533
SELECT 
      COUNT(bike_id) AS rides_qty
FROM trips 
WHERE date_part('year', start_time) = 2020 AND start_station = 'Columbus Circle / Union Station';

-- TOTAL 18144
SELECT 
      COUNT(bike_id) AS rides_qty
FROM trips 
WHERE date_part('year', start_time) = 2021 AND start_station = 'Columbus Circle / Union Station';

-- TOTAL 21038
SELECT 
      COUNT(bike_id) AS rides_qty
FROM trips 
WHERE date_part('year', start_time) = 2022 AND start_station = 'Columbus Circle / Union Station';

-- TOTAL 35641
SELECT 
      COUNT(bike_id) AS rides_qty
FROM trips 
WHERE date_part('year', start_time) = 2023 AND start_station = 'Columbus Circle / Union Station';

-- TOTAL 4616
SELECT 
      COUNT(bike_id) AS rides_qty
FROM trips 
WHERE date_part('year', start_time) = 2024 AND start_station = 'Columbus Circle / Union Station';

-- TOTAL 50582
SELECT 
      COUNT(bike_id) AS rides_qty
FROM trips 
WHERE date_part('year', start_time) = 2025 AND start_station = 'Columbus Circle / Union Station';

-- TOTAL 57095
SELECT 
      COUNT(bike_id) AS rides_qty
FROM trips 
WHERE date_part('year', start_time) = 2026 AND start_station = 'Columbus Circle / Union Station';

-- TOTAL 27873

--SUMMARY QUERY FOR CHECK additional information about the number of rides per year for the station 'Columbus Circle / Union Station' using GROUP BY to aggregate the results by year.
SELECT 
      date_part('year', start_time) AS Year,
      start_station,
      COUNT(bike_id) AS rides_qty
FROM trips 
WHERE start_station = 'Columbus Circle / Union Station'
GROUP BY ALL;

--- Block 4: 

SELECT 
      date_part('year', start_time) AS Year,
      start_station,
      --sta_station, -- #1 Misspelled column name
      COUNT(bike_id) AS rides_qty
  
FROM trips
--FROM strips -- #5 Reference a table name that doesn't exist
--WHERE start_station = 'Columbus Circle / Union Station -- #2 Missing closing quote
--WHERE start_station LIKE = 'Columbus Circle / Union Station' -- #3 Mix up = and LIKE on a text field
--WHERE (rider_type = 'member' AND start_station = 'X' -- #6 Mismatched parentheses in a compound WHERE clause
WHERE start_station = 'Columbus Circle / Union Station'
--AND start_time = '2021-21-01' -- #4 Wrong date format
GROUP BY ALL;

--Screenshots of mistakes : https://github.com/serhiy-dranko/Dataskools/tree/main/Week_9/Day_2/screenshots

--- Block 5:

SELECT  
  
  start_station,
  Sum(Case When date_part('year', start_time) = 2026 then 1 else 0 END) AS Rides_in_2026, -- Calculate the number of rides in 2026 for each station
  count(bike_id) AS Total_rides                                                           -- Calculate the total number of rides for each station across all years
  
FROM trips 
  
  WHERE start_station in (
                          SELECT  start_station                                    -- Subquery to get the TOP 5 stations by number of rides in 2026
                          FROM trips 
                          WHERE date_part('year', start_time) >= '2026'
                          AND start_station IS NOT null
                          GROUP BY start_station, strftime(start_time, '%Y')
                          ORDER BY count(bike_id) desc
                          LIMIT 5
                          )

GROUP BY start_station
ORDER BY Rides_in_2026 desc; -- sort the results by the number of rides in 2026 in descending order to get the busiest stations first.

-- Reporter : Serhiy Dranko
-- Date : 2026-07-21