--- This file is used to aggregate the data for the SQL exercises in Day 3 of the Dataskools SQL course.

--- Block 1: 

-- 1. Run the query above and confirm it returns exactly the distinct rider_type values.

SELECT rider_type
FROM trips
GROUP BY rider_type;

--Result 4 columns Solution LOWER(rider_type) AS rider_type add this into trips_legacy table to have the same format as trips_modern table.

-- 2. Group by start_station alone (no aggregate yet) and check how many distinct stations come back.

SELECT 
  start_station
  
FROM trips
GROUP BY start_station;

--Result 1099 rows 1 column

-- 3. Add COUNT(*) to the station grouping:

SELECT 
  start_station,
  COUNT(*) -- Count the number of rows in each group
  
FROM trips
  where start_station is not null
GROUP BY start_station
ORDER BY COUNT(*) desc;

--Result 1099 rows 2 column

-- 4. Group by two columns at once — start_station and rider_type.

SELECT 
  
  LOWER(rider_type) AS rider_type,
  start_station,
  COUNT(*) 

FROM trips
GROUP BY rider_type,start_station;

--Result 3345 rows 3 column

-- 5. Group by the year extracted from start_time, and count rides per year.

SELECT 
  
  date_part('year', start_time) AS Year, -- Extract the year from start_time and group by it
  count(bike_id)                AS rides_count
  
FROM trips 
  
GROUP BY Year
ORDER BY Year desc;

--Result 8 rows 2 column

-- 6. Group by both year and rider type together.

SELECT 
  
  date_part('year', start_time) AS Year,
  LOWER(rider_type)             AS rider_type,
  count(bike_id)                AS rides_count
  
FROM trips 
  
GROUP BY Year, rider_type 
ORDER BY Year desc, rider_type desc;

--Result 16 rows 3 column

-- in 2020 we have split because of the format better to use in trips_legasy so I've changed it.

-- 7. Grouping by a column that isn't in the SELECT list.

SELECT 
  
  date_part('year', start_time) AS Year,
  count(bike_id)                AS rides_count
  
FROM trips 
  
GROUP BY Year, rider_type
ORDER BY Year desc;

--Result 16 rows 2 column

-- Query Grouped by rider_type wich not included in Selection area so we have split bu can't ot see why because rider_type not in the selection.

-- 8. Group by end_station instead of start_station.

SELECT 
  end_station,
  COUNT(*)
  
FROM trips
  Where end_station is not null
GROUP BY end_station
ORDER BY COUNT(*) desc;

--Result 1100 rows 2 column

-- In a bouth queries Columbus Circle / Union Station is the busiest station 32000 at the start VS 327951 at the end.

--- Block 2: 

-- 1. Total rides per station using COUNT(*), ordered from highest to lowest.

SELECT  
    start_station,
    COUNT(*)
  
FROM trips 
  
GROUP BY start_station
ORDER BY COUNT(*) DESC;

--Result 1099 rows 2 column

-- 2. Total rides per station using COUNT(ride_id) (or your table's ID column) instead of COUNT(*).

SELECT  
 
  start_station,
  COUNT(bike_id)
  
FROM trips 

GROUP BY start_station
ORDER BY COUNT(bike_id) DESC;

--Result 1099 rows 2 column  

-- 3. Average ride duration per station, in minutes.

SELECT 
  
  start_station,
  ROUND(AVG(date_part('epoch', end_time - start_time) / 60),2) AS Avere_duration_minutes
  
FROM trips 

WHERE end_time > start_time
     AND (date_part('epoch', end_time - start_time) / 60) < 1440

GROUP BY start_station
ORDER BY Avere_duration_minutes DESC;

--Result 1099 rows 2 column

-- 4. The minimum and maximum ride duration per station in a single query, using MIN() and MAX() together.

SELECT
  start_station,
  ROUND(MIN(date_part('epoch', end_time - start_time) / 60),2) AS Min_duration_minutes,
  ROUND(MAX(date_part('epoch', end_time - start_time) / 60),2) AS Max_duration_minutes
  
FROM trips 

WHERE end_time > start_time
     AND (date_part('epoch', end_time - start_time) / 60) < 1440

GROUP BY start_station
ORDER BY start_station DESC;

--Result 1099 rows 3 columns

-- 5. Total ride duration per rider type, using SUM().

SELECT 
  
  rider_type,
  ROUND(SUM(date_part('epoch', end_time - start_time) / 60),2) AS Total_duration_minutes
  
FROM trips 

WHERE end_time > start_time
     AND (date_part('epoch', end_time - start_time) / 60) < 1440

GROUP BY rider_type
ORDER BY Total_duration_minutes DESC;

--Result 2 rows 2 columns

-- 6. The earliest and latest start_time per station, using MIN() and MAX() on a timestamp column rather than a numeric one.

SELECT 
    strftime(MIN(start_time), '%d/%m/%Y %H:%M:%S') AS min_start_time,
    strftime(MAX(start_time), '%d/%m/%Y %H:%M:%S') AS max_start_time
FROM trips;

--Result 1 row 2 columns

-- 7. Average rides per month for a single station, by first counting rides per month.

SELECT
  
 monthly_data.Month,
 monthly_data.start_station,
 ROUND(AVG(monthly_data.Rides_per_month),0) AS Average_rides_per_month
  
FROM        (
              SELECT                                                                                 -- Subquery to count rides per month for a specific station
                date_part('Year', start_time)                                AS Year,
                date_part('month', start_time)                               AS Month,
                start_station,
                COUNT (bike_id)                                              AS Rides_per_month
                                
              FROM trips 
              
              WHERE start_station = 'Columbus Circle / Union Station'
                   AND end_time > start_time
                   AND (date_part('epoch', end_time - start_time) / 60) < 1440
              
              GROUP BY Year, Month, start_station
              ORDER BY Year DESC, Month ASC
             ) monthly_data
 
GROUP BY monthly_data.Month, monthly_data.start_station
ORDER BY monthly_data.Month ASC;

--Result 12 rows 3 columns

-- 8. Comparing COUNT(*) grouped by year against AVG() of ride duration grouped by the same year, side by side, for the same set of years.

SELECT
    monthly_data.Month,
    monthly_data.start_station,
    ROUND(AVG(monthly_data.Rides_per_month), 0) AS Average_rides_per_month,                              -- Calculate the average rides per month for the station
    yearly_data.Rides_in_2019,
    yearly_data.Rides_in_2020,
    yearly_data.Rides_in_2021,
    yearly_data.Rides_in_2022,
    yearly_data.Rides_in_2023,
    yearly_data.Rides_in_2024, 
    yearly_data.Rides_in_2025,
    yearly_data.Rides_in_2026,
    yearly_data.Total_rides

FROM (
        SELECT                                                                                            -- Subquery to count rides per month for a specific station
            date_part('year', start_time)  AS Year,
            date_part('month', start_time) AS Month,
            start_station,
            COUNT(bike_id) AS Rides_per_month
        FROM trips 
        WHERE start_station = 'Columbus Circle / Union Station'
          AND end_time > start_time
          AND (end_time - start_time) < INTERVAL '24 hours'
        GROUP BY Year, Month, start_station
      ) monthly_data

LEFT JOIN (
            SELECT                                                                                         -- Subquery to count rides per year for the same station
              date_part('month', start_time) AS Month,
              start_station,
              SUM(CASE WHEN date_part('year', start_time) = 2019 THEN 1 ELSE 0 END) AS Rides_in_2019,
              SUM(CASE WHEN date_part('year', start_time) = 2020 THEN 1 ELSE 0 END) AS Rides_in_2020,
              SUM(CASE WHEN date_part('year', start_time) = 2021 THEN 1 ELSE 0 END) AS Rides_in_2021,
              SUM(CASE WHEN date_part('year', start_time) = 2022 THEN 1 ELSE 0 END) AS Rides_in_2022,
              SUM(CASE WHEN date_part('year', start_time) = 2023 THEN 1 ELSE 0 END) AS Rides_in_2023,
              SUM(CASE WHEN date_part('year', start_time) = 2024 THEN 1 ELSE 0 END) AS Rides_in_2024,
              SUM(CASE WHEN date_part('year', start_time) = 2025 THEN 1 ELSE 0 END) AS Rides_in_2025,
              SUM(CASE WHEN date_part('year', start_time) = 2026 THEN 1 ELSE 0 END) AS Rides_in_2026,
              COUNT (bike_id)                                                       AS Total_rides
            FROM trips 
            WHERE start_station = 'Columbus Circle / Union Station'
              AND end_time > start_time
              AND (end_time - start_time) < INTERVAL '24 hours'
            GROUP BY Month, start_station
           ) yearly_data 
        ON monthly_data.Month = yearly_data.Month
         AND monthly_data.start_station = yearly_data.start_station

GROUP BY ALL
ORDER BY monthly_data.Month ASC;

--Deliberately compute AVG() on a column that has some NULL values.

SELECT
    monthly_data.Month,
    monthly_data.bike_type,
    ROUND(AVG(monthly_data.Rides_per_month), 0) AS Average_rides_per_month,
    yearly_data.Rides_in_2019,
    yearly_data.Rides_in_2020,
    yearly_data.Rides_in_2021,
    yearly_data.Rides_in_2022,
    yearly_data.Rides_in_2023,
    yearly_data.Rides_in_2024, 
    yearly_data.Rides_in_2025,
    yearly_data.Rides_in_2026,
    yearly_data.Total_rides

FROM (
        SELECT
            date_part('year', start_time)  AS Year,
            date_part('month', start_time) AS Month,
            bike_type,
            COUNT(*) AS Rides_per_month
        FROM trips 
        WHERE  end_time > start_time
          AND (end_time - start_time) < INTERVAL '24 hours'
        GROUP BY Year, Month, bike_type
      ) monthly_data

LEFT JOIN (
            SELECT
              date_part('month', start_time) AS Month,
              bike_type,
              SUM(CASE WHEN date_part('year', start_time) = 2019 THEN 1 ELSE 0 END) AS Rides_in_2019,
              SUM(CASE WHEN date_part('year', start_time) = 2020 THEN 1 ELSE 0 END) AS Rides_in_2020,
              SUM(CASE WHEN date_part('year', start_time) = 2021 THEN 1 ELSE 0 END) AS Rides_in_2021,
              SUM(CASE WHEN date_part('year', start_time) = 2022 THEN 1 ELSE 0 END) AS Rides_in_2022,
              SUM(CASE WHEN date_part('year', start_time) = 2023 THEN 1 ELSE 0 END) AS Rides_in_2023,
              SUM(CASE WHEN date_part('year', start_time) = 2024 THEN 1 ELSE 0 END) AS Rides_in_2024,
              SUM(CASE WHEN date_part('year', start_time) = 2025 THEN 1 ELSE 0 END) AS Rides_in_2025,
              SUM(CASE WHEN date_part('year', start_time) = 2026 THEN 1 ELSE 0 END) AS Rides_in_2026,
              COUNT (*)                                                       AS Total_rides
            FROM trips 
            WHERE end_time > start_time
              AND (end_time - start_time) < INTERVAL '24 hours'
            GROUP BY Month, bike_type
           ) yearly_data 
        ON monthly_data.Month = yearly_data.Month
         AND monthly_data.bike_type = yearly_data.bike_type

WHERE monthly_data.Month = yearly_data.Month 
    AND monthly_data.bike_type = yearly_data.bike_type

GROUP BY ALL
ORDER BY monthly_data.Month ASC;


-- Block 3:

-- 1. SELECT start_station, COUNT(*) FROM trips WHERE COUNT(*) > 1000 GROUP BY start_station 
              SELECT
                start_station,
                COUNT (bike_id)  AS Rides
                                
              FROM trips 
              
              WHERE start_station is not null
                   AND end_time > start_time
                   AND (date_part('epoch', end_time - start_time) / 60) < 1440
                   AND Rides > 1000 -- this will not worlk because you cannot use an aggregate function.
              GROUP BY start_station
              ORDER BY Rides DESC;

-- This query will not run because we cannot use an aggregate function like COUNT(*) in the WHERE clause. Instead, we should use the HAVING clause to filter groups based on aggregate values.


-- 2. Fix the query from Task 1 by moving the condition to HAVING instead.

              SELECT
                start_station,
                COUNT (bike_id)  AS Rides
                                
              FROM trips 
              
              WHERE start_station is not null
                   AND end_time > start_time
                   AND (date_part('epoch', end_time - start_time) / 60) < 1440
              
              GROUP BY start_station
              HAVING Rides > 1000
              ORDER BY Rides DESC;

-- 3. Every station with more than 5,000 total rides across the full seven years, using GROUP BY and HAVING.

              SELECT
                start_station,
                COUNT (bike_id)  AS Rides
                                
              FROM trips 
              
              WHERE start_station is not null
                   AND end_time > start_time
                   AND (date_part('epoch', end_time - start_time) / 60) < 1440
              
              GROUP BY start_station -- Group the results by start station
              HAVING Rides > 5000 -- this will show us stations with more than 5000 rides across the full seven years.
              ORDER BY Rides DESC;

--Result 561 rows 2 columns

-- 4. Every station with fewer than 50 total rides.

              SELECT
                start_station,
                COUNT (bike_id)  AS Rides
                                
              FROM trips 
              
              WHERE start_station is not null
                   AND end_time > start_time
                   AND (date_part('epoch', end_time - start_time) / 60) < 1440
              
              GROUP BY start_station
              HAVING Rides < 50 -- this will show us stations with fewer than 50 rides across the full seven years.
              ORDER BY Rides DESC;

--Result 55 rows 2 columns

-- 5. Combine WHERE and HAVING in the same query: 

             SELECT
                rider_type,
                start_station,
                COUNT (bike_id)  AS Rides
                                
              FROM trips 
              
              WHERE start_station is not null
                   AND rider_type = 'casual' -- this will filter the results to only include casual riders
                   AND end_time > start_time
                   AND (date_part('epoch', end_time - start_time) / 60) < 1440
              
              GROUP BY rider_type,start_station
              HAVING Rides > 500 -- this will show us stations with more than 500 casual rides across the full seven years.
              ORDER BY Rides DESC;

--Result 832 rows 3 columns

-- 6. Query using HAVING with an AVG() condition.

              SELECT 
                
                start_station,
                ROUND(AVG(date_part('epoch', end_time - start_time) / 60),2) AS Avere_duration_minutes -- this will calculate the average ride duration in minutes for each station
                
              FROM trips 
              
              WHERE end_time > start_time
                   AND (date_part('epoch', end_time - start_time) / 60) < 1440
                   AND start_station IS NOT NULL
              
              GROUP BY start_station
              HAVING Avere_duration_minutes BETWEEN 25.0 AND 30.0 -- this will show us stations where the average ride duration is between 25 and 30 minutes
              ORDER BY Avere_duration_minutes DESC;

--Result 115 rows 2 columns

-- 7. Write one sentence, in your own words, explaining why WHERE rider_type = 'member' and HAVING COUNT(*) > 1000 can appear in the same query without conflicting, even though they seem to be doing a similar job.
-- They defenetley NOT doing a similar job. WHERE rider_type = 'member'  Filtering data by rider_type and HAVING COUNT(*) > 1000 showing us category of data wich have over 1000 records. WHERE working with data before grouping without calculation HAVING after grouping with calculation of result.

-- Block 4:

-- 1. Rewrite one of Block 2 queries using column aliases (AS).

SELECT 
  
  start_station,
  COUNT(bike_id)                                       AS total_rides, -- alias for the count of rides
  AVG(date_part('epoch', end_time - start_time) / 60)  AS avg_duration_minutes -- alias for the average ride duration in minutes
  
FROM trips 

WHERE start_station IS NOT NULL
     AND end_time > start_time
     AND (date_part('epoch', end_time - start_time) / 60) < 1440

GROUP BY start_station
ORDER BY total_rides DESC
LIMIT 10;

--Result 10 rows 3 columns

-- 2. Use ROUND() on an average duration calculation and show the unrounded and rounded output side by side.

SELECT 
  
  start_station,
  COUNT(bike_id)                                               AS total_rides,
  AVG(date_part('epoch', end_time - start_time) / 60)          AS raw_avg_duration_minutes, -- unrounded average duration in minutes
  ROUND(AVG(date_part('epoch', end_time - start_time) / 60),2) AS avg_duration_minutes      -- rounded average duration in minutes
  
FROM trips 

WHERE start_station IS NOT NULL
     AND end_time > start_time
     AND (date_part('epoch', end_time - start_time) / 60) < 1440

GROUP BY start_station
ORDER BY total_rides DESC
LIMIT 10;

--Result 10 rows 4 columns  We have 15 decimal places the unrounded version.

-- 3. Round a percentage-style calculation.

SELECT 
  
  start_station,
  COUNT(bike_id)                                                                        AS total_rides,
  ROUND((SUM(CASE WHEN rider_type = 'casual' THEN 1 ELSE 0 END)/COUNT(bike_id) *100),2) AS casual_rides_percentage, -- rounded percentage of casual rides at the station
  ROUND(AVG(date_part('epoch', end_time - start_time) / 60),2)                          AS avg_duration_minutes
  
FROM trips 

WHERE start_station IS NOT NULL
     AND end_time > start_time
     AND (date_part('epoch', end_time - start_time) / 60) < 1440

GROUP BY start_station
ORDER BY total_rides DESC
LIMIT 10;

--Result 10 rows 4 columns

-- 4. Alias a table name itself.

SELECT 
  
  t.start_station,
  COUNT(t.bike_id)                                                                          AS total_rides,
  ROUND((SUM(CASE WHEN t.rider_type = 'casual' THEN 1 ELSE 0 END)/COUNT(t.bike_id) *100),2) AS casual_rides_percentage,
  ROUND(AVG(date_part('epoch', t.end_time - t.start_time) / 60),2)                          AS avg_duration_minutes
  
FROM trips AS t -- aliasing the trips table as t for easier reference in the query

WHERE t.start_station IS NOT NULL
     AND t.end_time > t.start_time
     AND (date_part('epoch', t.end_time - t.start_time) / 60) < 1440

GROUP BY t.start_station
ORDER BY COUNT(t.bike_id) DESC
LIMIT 10;

--Result 10 rows 4 columns

-- 5. Combine aliasing and rounding into a single clean query: station name, total rides (aliased), and average duration in minutes (aliased and rounded to one decimal place).

SELECT 
  
  t.start_station                                                                           AS station_name, -- alias for the start station name
  COUNT(t.bike_id)                                                                          AS total_rides,  -- alias for the count of rides
  ROUND(AVG(date_part('epoch', t.end_time - t.start_time) / 60),1)                          AS average_duration_in_minutes -- alias for the average ride duration in minutes, rounded to one decimal place
  
FROM trips AS t

WHERE t.start_station IS NOT NULL
     AND t.end_time > t.start_time
     AND (date_part('epoch', t.end_time - t.start_time) / 60) < 1440

GROUP BY t.start_station
ORDER BY COUNT(t.bike_id) DESC;

--Result 1098 rows 3 columns

-- 6. Took the messiest-looking query output you've produced so far day 3 and rewrite it fully with aliases and rounding.

              SELECT
                
                t.start_station                                                                              AS station_name,
                COUNT(t.bike_id)                                                                             AS total_rides,
                ROUND((SUM(CASE WHEN t.rider_type = 'casual' THEN 1 ELSE 0 END) / COUNT(t.bike_id) *100),2)  AS casual_rides_percentage,
                ROUND(AVG(date_part('epoch', t.end_time - t.start_time) / 60),1)                             AS average_duration_in_minutes
                                
              FROM trips AS t 
              
              WHERE t.start_station is not null
                   AND t.end_time > t.start_time
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) < 1440
              
              GROUP BY t.start_station
              HAVING total_rides > 15000
              ORDER BY total_rides DESC;

--Result 386 rows 4 columns

---List of the Start station which have over 15,000 rides since 2019 with Casual riders percentage and average duration.

-- Block 5:

-- 1. Single query returning every station, its total ride count, and its average ride duration, ordered by total ride count descending.
-- 2. The top 10 stations by ride count, 0ation (rounded), and percentage of rides by casual riders — all as clean, aliased columns.

              SELECT
                
                t.start_station                                                                              AS station_name,
                COUNT(t.bike_id)                                                                             AS total_rides,
                ROUND((SUM(CASE WHEN t.rider_type = 'casual' THEN 1 ELSE 0 END) / COUNT(t.bike_id) *100),0)  AS casual_rides_percentage,
                ROUND(AVG(date_part('epoch', t.end_time - t.start_time) / 60),0)                             AS average_ride_duration_min
                                
              FROM trips AS t 
              
              WHERE t.start_station is not null
                   AND t.end_time > t.start_time
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) < 1440
                   AND (date_part('epoch', t.end_time - t.start_time) / 60) > 1
              
              GROUP BY t.start_station
              ORDER BY total_rides DESC
              LIMIT 10;

-- Reporter : Serhiy Dranko
-- Date : 2026-07-22
