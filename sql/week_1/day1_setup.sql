--- This file is used to set up the database for the SQL exercises in Day 1 of the Dataskools SQL course.

--- It creates a table called "trips_legacy" that contains data from the old data format Capital bike share system before April 2020.
--- *do not have information about bike type, so we will set it to NULL for all records in this table. 
---    Also, the column names are different from the new data format, so we will rename them to match the new data format.

CREATE OR REPLACE TABLE trips_legacy AS
SELECT
    "Bike number"           AS bike_id,
    "Start date"            AS start_time,
    "End date"              AS end_time,
    "Start station number"  AS start_station_id,
    "Start station"         AS start_station,
    "End station number"    AS end_station_id,
    "End station"           AS end_station,
    LOWER("Member type")    AS rider_type,
    CAST(NULL AS VARCHAR)   AS bike_type
FROM read_csv_auto(
    [
        'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\2019*.csv',
        'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\202001*.csv',
        'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\202002*.csv',
        'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\202003*.csv'
    ],
    union_by_name = true,
    types = {"Start station number": 'VARCHAR', "End station number": 'VARCHAR'}
);

--- It creates a table called "trips_modern" that contains data from the new data format Capital bike share system since April 2020.

CREATE OR REPLACE TABLE trips_modern AS
SELECT
    ride_id              AS bike_id,
    started_at           AS start_time,
    ended_at             AS end_time,
    start_station_id     AS start_station_id,
    start_station_name   AS start_station,
    end_station_id       AS end_station_id,
    end_station_name     AS end_station,
    member_casual        AS rider_type,
    rideable_type        AS bike_type
FROM read_csv_auto(
  [
      'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\202004*.csv',
      'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\202005*.csv',
      'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\202006*.csv',
      'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\202007*.csv',
      'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\202008*.csv',
      'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\202009*.csv',
      'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\202010*.csv',
      'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\202011*.csv',
      'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\202012*.csv', 
      'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\2021*.csv', 
      'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\2022*.csv',
      'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\2023*.csv',
      'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\2024*.csv', 
      'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\2025*.csv',
      'C:\Users\User\Documents\Dataskools\week_9\day_1\Data\2026*.csv'
  ],
    union_by_name = true,
   types = {'start_station_id': 'VARCHAR', 'end_station_id': 'VARCHAR'}
);

--- It creates a table called "trips" that combines data from two different sources: trips_legacy and trips_modern.

CREATE OR REPLACE TABLE trips AS
  SELECT
    bike_id,
    start_time,
    end_time,
    start_station_id,
    start_station,
    end_station_id,
    end_station,
    rider_type,
    bike_type,
    ROUND(SUM(date_part('epoch', end_time - start_time) / 60),2) AS duration -- add duration in munutes
  FROM trips_legacy
  GROUP BY 
    bike_id,
    start_time,
    end_time,
    start_station_id,
    start_station,
    end_station_id,
    end_station,
    rider_type,
    bike_type
  
UNION ALL
  SELECT 
    bike_id,
    start_time,
    end_time,
    start_station_id,
    start_station,
    end_station_id,
    end_station,
    rider_type,
    bike_type,
    ROUND(SUM(date_part('epoch', end_time - start_time) / 60),2) AS duration -- add duration in munutes
  FROM trips_modern
  GROUP BY 
    bike_id,
    start_time,
    end_time,
    start_station_id,
    start_station,
    end_station_id,
    end_station,
    rider_type,
    bike_type
   ;

--- It creates a table called "station" that took data from.
---  "name": "station_information",
---  "url": "https://gbfs.lyft.com/gbfs/2.3/dca-cabi/en/station_information.json"

--- It creates a table called "stations". Table where we have capacity by station where we combain it with Neighborhood data Washington DC.

INSTALL spatial;
LOAD spatial;

CREATE OR REPLACE TABLE station AS
WITH dc_neighborhoods AS (
    SELECT * FROM ST_Read('C:\Users\User\Documents\Dataskools\week_10\day_1\neighborhood_data\Neighborhood_Clusters.geojson')
),
station_raw AS (
    SELECT 
        station.station_id,
        station.short_name,
        station.name,
        station.lat,
        station.lon,
        station.capacity
    FROM (
        SELECT unnest(data.stations) AS station
        FROM read_json_auto('https://gbfs.lyft.com/gbfs/2.3/dca-cabi/en/station_information.json')
    )
)
SELECT 
    s.station_id,
    s.short_name,
    s.name,
    s.lat,
    s.lon,
    s.capacity,
    COALESCE(n.NAME || ' - ' || n.NBH_NAMES, 'Cluster Other - Outside DC (VA/MD)') AS neighborhood
FROM station_raw AS s
LEFT JOIN dc_neighborhoods AS n
    ON ST_Contains(n.geom, ST_Point(s.lon, s.lat));

--- It creates a table called "stations_summary". Table where we have Summury by station where total_rides over 100.

CREATE OR REPLACE TABLE stations_summary AS
              SELECT
                t.start_station_id                                                                           AS ID_station,
                t.start_station                                                                              AS station_name,
                COALESCE(s.neighborhood,'Cluster history - Without geomarks')                                AS neighborhood,
                COALESCE(s.lat,'00.00')                                                                      AS latitude,
                COALESCE(s.lon,'00.00')                                                                      AS longitude,
                COUNT(t.bike_id)                                                                             AS total_rides, -- count total rides
                ROUND((SUM(CASE WHEN t.rider_type = 'casual' THEN 1 ELSE 0 END) / COUNT(t.bike_id) *100),0)  AS casual_rides_percentage, -- count casual rider's % to Total
                ROUND((SUM(CASE WHEN t.rider_type = 'member' THEN 1 ELSE 0 END) / COUNT(t.bike_id) *100),0)  AS member_rides_percentage, -- count member rider's % to Total
                ROUND(AVG(date_part('epoch', t.end_time - t.start_time) / 60),0)                             AS average_ride_duration_min, -- calculate average duration
                AVG(s.capacity,'0')                                                                          AS station_capacity -- show actual capacity
                                
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
                   
                                   
              GROUP BY ID_station, station_name, latitude, longitude, neighborhood
              -- Filter capacity equal or over 100 redes per 7 years --
              HAVING total_rides >= 100
              -- Sort by quantity of rides --   
              ORDER BY total_rides DESC;

--- It creates a table called "hourly_weather". Table where we have Summury by station with hourly temperature and precipitation.

CREATE OR REPLACE TABLE hourly_weather AS

WITH weather_data AS (

SELECT
    strftime(DATE, '%d/%m/%Y %H:00:00') AS Datetime,
    DATE_TRUNC('day', "DATE")           AS Date,
    Hour,
    STATION,
    Station_name,
    LATITUDE,
    LONGITUDE,
    temperature,
    COALESCE(precipitation,0) AS precipitation
FROM read_csv_auto(
    'C:/Users/User/Documents/Dataskools/week_10/day_1/weather_data/GHCNh_*.psv',
    delim = '|',
    header = true,
    union_by_name = true
)
WHERE temperature_Report_Type IN ('FM16','FM15')
)
  
 SELECT
    Datetime,
    Date,
    Hour,
    STATION,
    Station_name,
    LATITUDE,
    LONGITUDE,
    MAX(temperature)    AS temperature,
    MAX(precipitation)  AS precipitation
  
  FROM weather_data
GROUP BY Datetime, Date, Hour, STATION, Station_name, LATITUDE, LONGITUDE
ORDER BY Date ASC;


-- Reporter : Serhiy Dranko
-- Date : 2026-07-20
-- Update : 2026-08-04
