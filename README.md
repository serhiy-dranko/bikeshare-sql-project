# Capital Bikeshare SQL Analysis

## Overview

Capital Bikeshare is Washington D.C.'s public bikesharing system.

This project analyzes seven years of Capital Bikeshare trip data (2019–2026) using SQL, covering roughly [31.9 million] individual rides, to explore ridership patterns, station usage, and ride duration across a period that spans a major schema change in how the data itself was recorded. 

The goal was to move this kind of analysis out of Power BI - where loading years of raw CSVs was slow and into a proper SQL workflow that's faster and easier to audit.

## Data Source

The data comes from [Capital Bikeshare's publicly published historical trip data](https://s3.amazonaws.com/capitalbikeshare-data/index.html), covering January 2019 through June 2026. Two distinct file schemas exist across this range:

2019 - March 2020: legacy format with columns like Bike number, Start date, End date, Member type.
April 2020 - 2026: current format with columns like ride_id, started_at, ended_at, member_casual, rideable_type.


[Station reference data (stations)](https://gbfs.lyft.com/gbfs/2.3/dca-cabi/en/station_information.json) — names, coordinates, capacity. 
It comes from Capital Bikeshare's live feed: station_information.json. 
This is a live snapshot of currently active stations, not a historical record, which is directly related to the data issue noted below.

## Setup

This project was built in DuckDB, using Beekeeper Studio as the SQL client. To recreate it:

1. Download Capital Bikeshare's historical trip data CSVs for the years/months you want to cover (not included in this repo due to file size).
2. Load the legacy-schema files (2019–March 2020) into trips_legacy, renaming columns to a common schema.
3. Load the current-schema files (April 2020 onward) into trips_modern, explicitly casting start_station_id/end_station_id to VARCHAR (some station IDs are alphanumeric and break DuckDB's type auto-detection).
4. Combine both into a single trips table using UNION ALL (or union_by_name = true on load).
5. Pull current station metadata from the GBFS feed URL directly into a stations table using DuckDB's read_json_auto.
6. Run the queries in sql/ in order to reproduce the cleaning and summary steps.

## What's in sql/

  ### day1_setup.sql 
  Loads and standardizes legacy vs. current schema files into trips_legacy / trips_modern, combines into trips.
  ### day2_filtering.sql
  Early hand-filtered queries comparing stations and ride counts one at a time, before aggregation was introduced.
  ### day3_aggregation.sql 
  Introduces GROUP BY, HAVING, and conditional aggregation (SUM(CASE WHEN...)) to replace manual comparisons.
  ### day4_joins_summary.sql
  Joins trips to stations, builds stations_summary, and surfaces the unmatched-station data issue.

## Key Findings

  Switching from Power BI to a DuckDB/SQL workflow cut load-and-aggregate time from hours to under a minute for the full seven-year dataset.
  The practical bottleneck moved from "can I even run this" to "is the data underneath it trustworthy."
  
  Columbus Circle / Union Station
    "The busiest station accounts for 317,795 rides over seven years, with a casual member split of casual 24% vs member 76%".

  14th & D St NW / Ronald Reagan Building
    "The station in center of Washington with the largest capacity accounts for 34,378 rides over seven years with Station capacity 41 bike, with a casual member split of casual 38.9 % vs member 61.1%".

## Known Data Issues

  Joining trips to stations on station ID surfaces a real gap: a portion of rides reference station IDs that don't exist in the current stations table, because that table only reflects currently active stations. 
  Rides at stations that have since closed, been renamed, or been renumbered over the seven-year span won't match and this problem is expected to be worse in older (2019–2020) data, since more time has passed for stations to change. 
  
  Right now, stations_summary handles this with a LEFT JOIN (so rides aren't silently dropped) and COALESCE-based placeholders for missing capacity&coordinates,but the placeholders are provisional. 
  
  A proper fix would need a station ID crosswalk table that preserves historical station identities rather than only the current snapshot.

## Next Steps

Week 2 builds directly on this foundation, introducing subqueries to replace some of the flatter query patterns used here, along with deeper data cleaning.
Including addressing the unmatched-station problem above with a proper historical station crosswalk rather than a LEFT JOIN workaround.

 
