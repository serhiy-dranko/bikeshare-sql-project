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
  SELECT * 
  FROM trips_legacy
UNION ALL
  SELECT * 
  FROM trips_modern;

--- It creates a table called "station" that took data from.
---  "name": "station_information",
---  "url": "https://gbfs.lyft.com/gbfs/2.3/dca-cabi/en/station_information.json"

CREATE OR REPLACE TABLE station AS
SELECT 
    station.station_id,
    station.name,
    station.lat,
    station.lon,
    station.capacity
FROM (
    SELECT unnest(data.stations) AS station
    FROM read_json_auto('https://gbfs.lyft.com/gbfs/2.3/dca-cabi/en/station_information.json')
);

-- Reporter : Serhiy Dranko
-- Date : 2026-07-20
