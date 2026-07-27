# Data Quality Notes

## 1. Unmatched-Station Issue (Day 4, Block 3)

###  What it is:

  Joining trips to stations on start_station_id = short_name (via LEFT JOIN) reveals that a meaningful share of rides reference station IDs that don't exist in the current stations table. 
  The stations table is a live snapshot pulled from the current GBFS feed, so it only reflects stations that are active today — it has no memory of stations that were closed, renamed or renumbered at any point over the last seven years. 
  Any ride tied to one of those historical IDs will find no match, and its capacity/coordinate fields fall back to NULL.

###  How many rows it affects:

| Year | Rows qty | Unmatched qty | Unmatched % to Total |
| --- | ------ | ---- | ---- |
| 2019	| 3398417 |	0|	0 |
| 2020	| 2215956 |	84639 |	3.82 |
| 2021	| 2749881 |	196326 |	7.14 |
| 2022	| 3476782 |	139820 |	4.02 |
| 2023	| 4467334 |	406630 |	9.1 |
| 2024	| 6114359 |	1190978|	19.48 |
| 2025	| 6662659 |	1509937 |	22.66 |
| 2026	| 2851683 |	423098 |	14.84 |

###  Status: 

  Not yet fixed. 
  Current handling is a LEFT JOIN (so rows aren't silently dropped) with COALESCE placeholders in stations_summary for missing capacity/coordinates. .
  The proper fix is a historical station ID crosswalk table that preserves station identity across renames/closures, rather than relying on a live/current-only reference table.

## 2. Other Inconsistencies This Week

  Schema differences between years (Day 1): 
  
  Capital Bikeshare changed its file format around April 2020 — legacy files used Bike number, Start date, End date, Member type; current files use ride_id, started_at, ended_at, member_casual, rideable_type.
  
  Alphanumeric station IDs (Day 1): 
  
  Some start_station_id and end_station_id values (e.g. MTL-ECO5-03) are text, not numbers, which broke DuckDB's auto-detected BIGINT type when loading current-schema files.
  
  Capitalization inconsistency (rider_type): 
  
  Values like Member vs member didn't match under exact-case (=) comparisons.
  
  Whitespace and formatting: 
  
  Station names and other text fields occasionally needed trimming (leading & trailing spaces, repeated internal spaces) before they could be trusted for grouping or joining.
  
  Timestamp formatting vs sorting: 
  
  Formatting start_time into a display string (DD/MM/YYYY) and then sorting by that string broke chronological order, since string sorting is lexicographic, not date-aware.
  
  Integer division in percentage calculations: 
  
  SUM(...) / COUNT(...) without * 100.0 silently returned 0 instead of a decimal percentage, due to integer division truncating the result.

## 3. How Each Was Handled

  Unmatched stations: 
  
  Not yet handled, currently masked by LEFT JOIN + COALESCE placeholders. 
  The real fix (station ID crosswalk table) is planned but not built, so treat stations_summary's capacity/coordinate columns as provisional until that exists.
  
  Schema differences: 
  
  Handled by loading each era into its own staging table (trips_legacy, trips_modern) with explicit column renaming, then combining with UNION ALL, because a single read_csv_auto call across both schemas would have silently misaligned columns.
  
  Alphanumeric station IDs: 
  
  Handled by explicitly setting types = {'start_station_id': 'VARCHAR'} on load, since letting DuckDB auto-infer from a sample caused it to guess BIGINT and fail partway through the file.
  
  Capitalization: 
  
  Handled at query time with LOWER() rather than cleaning the source data, since it was faster during exploration this a permanent fix would normalize the stored values once rather than repeating this in every query.
  
  Whitespace noise: 
  
  Handled at query time with TRIM(), chosen over a permanent UPDATE so the raw loaded data stays untouched while still experimenting.
  
  Timestamp formatting vs sorting: 
  
  Handled by always sorting on the raw TIMESTAMP column and only formatting for display in the final SELECT, since formatting and sorting on the same column silently breaks chronological order.
  
  Integer division: 
  
  Handled by forcing float division with * 100  in every percentage calculation, fixed as soon as a 0-only result made the bug obvious.



