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

# Week 2

  Week 1 covered loading, cleaning, and basic aggregation. Week 2 moved into nested and reusable SQL patterns — subqueries, CTEs, explicit NULL handling, and time-series anomaly detection — and used them to go back and actually resolve, rather than just work around, the unmatched-station issue flagged at the end of Week 1.
  
  **What was built:**
  
  - Subqueries (Day 1) to answer questions that need a value computed before filtering can happen, like "the single busiest station" or "the busiest station per neighborhood."
  - CTEs (Day 2) to break multi-step logic (station totals → neighborhood averages → ranking) into named, readable stages instead of nesting subqueries several layers deep.
  - NULL/CASE handling (Day 3) to quantify exactly how much of `trips` is missing critical fields, and to explicitly flag rows as 'Matched'/'Unmatched' against the stations table instead of letting them fall through as silent NULLs.
  - Time-series anomaly detection (Day 4) — built a full daily ride-count calendar (including zero-ride days) and flagged days that deviate from the global and monthly average using z-scores.
        
  **Questions it answers:**
  - Which station is the single busiest system-wide, and which station leads each neighborhood?
  - How much of `trips` is missing station or duration data, and does that gap fall evenly across neighborhoods and years, or is it concentrated?
  - Which specific days in the seven-year dataset are statistically anomalous, and is there a real-world explanation or a data problem behind each one?
  

## What's in sql/

### Week 1:

  ### day1_setup.sql 
  Loads and standardizes legacy vs. current schema files into trips_legacy / trips_modern, combines into trips.
  ### day2_filtering.sql
  Early hand-filtered queries comparing stations and ride counts one at a time, before aggregation was introduced.
  ### day3_aggregation.sql 
  Introduces GROUP BY, HAVING, and conditional aggregation (SUM(CASE WHEN...)) to replace manual comparisons.
  ### day4_joins_summary.sql
  Joins trips to stations, builds stations_summary, and surfaces the unmatched-station data issue.

### Week 2:

  ### day1_subqueries.sql
  
  Introduces subqueries as SELECT statement nested inside another SQL statement.
  
  ### day2_cte.sql 
  
  Introduces CTE as temporary result set that exists only for the duration of one query.
  
  ### day3_null_coalesce_case_when.sql
  
  Uses COALESCE and CASE WHEN to quantify NULLs, bucket stations/trips into tiers, and flag rows as Matched/Unmatched against the stations table.
  
  ### day4_anomalies.sql
  
  Builds a full daily ride-count time series and flags anomalous days using z-scores against global and monthly baselines.
  
  ### day5_week_summury.sql
  
  Week-closing mini-project applying subqueries, CTEs, and CASE together across the full dataset.

## Key Findings

  Switching from Power BI to a DuckDB/SQL workflow cut load-and-aggregate time from hours to under a minute for the full seven-year dataset.
  The practical bottleneck moved from "can I even run this" to "is the data underneath it trustworthy."
  
  Columbus Circle / Union Station
    "The busiest station accounts for 317,795 rides over seven years, with a casual member split of casual 24% vs member 76%".

  14th & D St NW / Ronald Reagan Building
    "The station in center of Washington with the largest capacity accounts for 34,378 rides over seven years with Station capacity 41 bike, with a casual member split of casual 38.9 % vs member 61.1%".
  
  Cherry Blossom Peak Bloom spike (Week 2 Day 4)
    Z-score anomaly detection flagged 29–30 March 2025 as extreme outliers, tracing back to Washington D.C.'s cherry blossom peak bloom weekend — 29 March 2025 is the all-time single-day ridership record. See [`notes/week2_trend_analysis.md`](notes/week2_trend_analysis.md) for the full investigation.

## Known Data Issues

  Joining trips to stations on station ID surfaces a real gap: a portion of rides reference station IDs that don't exist in the current stations table, because that table only reflects currently active stations. 
  Rides at stations that have since closed, been renamed, or been renumbered over the seven-year span won't match and this problem is expected to be worse in older (2019–2020) data, since more time has passed for stations to change. 
  
  As of Day 3 (Week 2), this is no longer a silent gap: `COALESCE` supplies visible defaults ('Unknown' neighborhood, 0 capacity) instead of NULLs, and every row is explicitly flagged 'Matched' or 'Unmatched' against the stations table, so the affected rides can be measured and reported on rather than quietly dropped or blended in. That's the "partially resolved" part — the gap is now quantified and explicit.

 Still outstanding: the underlying cause. `stations` is a live snapshot, not a historical record, so 'Unmatched' rows are still missing real capacity/coordinate data rather than recovering it. The actual fix is  a station ID crosswalk table that preserves historical station identities across renames/closures it hasn't been built yet.

## Next Steps

  Week 3 moves into more advanced SQL (window functions, more complex CTEs and query performance/optimization) and introduces dbt.
  Building the station ID crosswalk table is the real fix for the unmatched-station gap quantified in Week 2. Is a leading candidate for the first dbt model.
   
