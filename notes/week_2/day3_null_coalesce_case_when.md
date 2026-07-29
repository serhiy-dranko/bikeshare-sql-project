# Day 3: NULL Handling, COALESCE & CASE WHEN

**Total time: 6 hours**

The unmatched-station problem has been sitting in your notes since Week 1, Day 4 — worked around, never actually resolved. Today you go back and handle it deliberately, using `COALESCE` and `CASE WHEN`, and apply the same tools to the other inconsistencies you've been noting since then: rider type variants, missing durations, and anything else that's been quietly making your aggregates less trustworthy than they look.

Read `day3_concepts.md` before starting if you haven't already — this task file assumes you understand three-valued logic, `IS NULL` vs `= NULL`, and how `CASE WHEN` behaves inside an aggregate.

## Time Budget

| Block | Topic | Time |
|-------|-------|------|
| 1 | NULL semantics and three-valued logic | 60 min |
| 2 | COALESCE for defaults | 75 min |
| 3 | CASE WHEN for categorization | 90 min |
| 4 | Cleaning the Week 1 station gap, with CTEs | 75 min |
| 5 | Reflection | 60 min |

---

## Block 1: NULL Semantics and Three-Valued Logic (60 min)

**Goal:** Confirm, with real queries against real data, how `NULL` actually behaves — not how it seems like it should behave.

1. Run SELECT COUNT(*) FROM trips and SELECT COUNT(duration) FROM trips side by side. If the numbers differ, you have NULL durations — note how many.

      Binder Error: Referenced column "duration" not found in FROM clause!
      Candidate bindings: "end_station", "start_station", "start_station_id", "end_station_id", "end_time"
      LINE 3:   COUNT(duration) AS rows_with_duration
      We definitely need "duration" column in 'trips' table
    
      Result after creating "duration" column:
      1 column 1 row
      total_rows 31937007 and rows_with_duration 31937007 previous version have 31937071 rows we have 64 rows less. So we have 64 rows NULL durations or Duplicates between files.
                
2. Try filtering WHERE duration = NULL and confirm it returns nothing, even though NULL durations exist. Then rewrite it correctly with IS NULL.

      Result 1 row 1 column. Value 0.

3. Find every column in trips and stations that can contain NULL, by running IS NULL counts on each candidate column. Keep a running list.

      Result 2 rows 2 columns.

4. Revisit your Week 1, Day 4, Block 3 LEFT JOIN between trips and stations. Confirm again how many rows have NULL in a stations column, and cross-check it against your notes from that day.

      "Unknown_count" Column in row Left join from Week 1, Day 4, Block 3, Task 5 show the same result as 'COUNT(*)' in 'start is null' in condition column - 3,951,423 rows 12,37 % from whole data. end_station 4,149,857 rows 12,99 % from whole data.

5. Write a query using NOT IN against a column you now know can contain NULL (from Task 3), and confirm whether it silently returns zero or fewer rows than expected — this is the Day 1 pitfall, now demonstrated on purpose.

      Result 1 row 1 column. Value 0.

6. Rewrite Task 5 using NOT EXISTS with a correlated subquery, and confirm it returns the correct, non-empty result.

      Result 1 row 1 column. Value 3,951,423 rows. Show us Nulls in start_station_id


## Block 2: COALESCE for Defaults (75 min)

**Goal:** Replace missing values with deliberate, visible defaults.


1. Write a query selecting neighborhood from a joined trips/stations result, wrapped in COALESCE(neighborhood, 'Unknown'), and confirm rows that previously showed NULL now show 'Unknown'.

    Result 1108 rows 6 columns. Result returns 64 rows with 'Unknown' in "Neighborhood" column.

2. Group that query by the COALESCEd neighborhood and count rides per group. Confirm 'Unknown' now appears as its own visible group instead of being dropped or hidden.
      
    Result 43 rows 2 columns. Result returns 4,893,918 rides (15.32 % from Total) with 'Unknown' in "Neighborhood" column.

3. Compare the total row count of this grouped result against a version that grouped by raw neighborhood without COALESCE. Confirm the NULL group's rides are now accounted for somewhere instead of vanishing.
       
   Result 2 rows 2 columns. Values in "total_rides" equal in bouth variants so that is mean COALESCE works properly.

4. Apply COALESCE to any duration-related NULLs you found in Block 1, using a reasonable fallback (for example, the overall average duration, computed with a scalar subquery from Day 1). Justify the fallback choice in one sentence.

    Result 0 rows 0 columns.
       IN our Data we do not have nulls in 'trips' table. So will try COALESCE in join table with Capacity values. For this task I'll delete COALESCE from "station_capacity" column in 'stations_summary' table and rewrite it for giving nulls.It will create 51 null rows in 'stations_summary' table.


    Result 1 row 2 columns. Neighborhood_capacity equal to 0.
      During appling HAVING Neighborhood_capacity = 0 we can see that COALESCE is working in 'station_capacity' because before 'Cluster history - Without geomarks' have NULL's in "station_capacity" column.

5. Try chaining three arguments in a single COALESCE on a column of your choice, even if the third argument is just a hardcoded default like 0 or 'Unknown'.
      
    Result 1 row 5 columns.

6. If any text columns contain placeholder values like 'N/A' or empty strings instead of real NULLs, use NULLIF to convert them to actual NULLs first, then COALESCE them to your chosen default.

    Result 0 row 0 columns. We do not have 'N/A'

7. Write one sentence on a case where you'd deliberately choose not to COALESCE a NULL — where leaving it as NULL, and filtering it out explicitly, is more honest than papering over it with a default.

      I think when calculating the average trip duration, you should leave NULL ride times as NULL rather than replacing them with 0 — because AVG() correctly ignores NULLs, while COALESCEing to 0 would drag the average down and misrepresent the true typical ride length.

## Block 3: CASE WHEN for Categorization (90 min)

**Goal:** Build your own categories and conditional counts directly in SQL.


  1. Write a CASE WHEN that buckets stations into capacity tiers (for example, Small / Medium / Large), with an ELSE catching anything unmatched, including NULL capacity.

     Result 851 rows 4 columns.

   2. Group stations by that tier and count how many fall into each — including the ELSE bucket.

      Result 3 rows 2 columns.

      In that case we can not see 'Unknown' because 'station' table this is a table direct from JSON file. Switch to the stations_summary.

      Result 4 rows 2 columns. 'Unknown' tier has 51 stations. 

      This is exactly the same as in Week-2 Day-3 Block-2 TASK-4 Result 51 rows. So here we can see ours stations wich not conected to the JSON data.

3. Write a CASE WHEN that buckets trip duration into ranges (for example, under 10 min, 10–30 min, over 30 min), and count trips per bucket.

      Result 5 rows 2 columns. under 10 min 47,79 % of our rides during 2019 - mid 2026. 8712 rows have negative duration.

4. Use COUNT(CASE WHEN ... THEN 1 END) to compute, in a single query, the number of casual rides and member rides per neighborhood — no separate filtered queries, no GROUP BY on rider type itself.     

      Result 43 rows 4 columns. Cluster 8 is the most popular in Washigton DC. 2,889,564 rides. 67.9 % of rides by member type.

5. Extend Task 4 to add a third conditional count for any rider type value that doesn't cleanly match either of the two you expected — this surfaces inconsistent or unexpected values in the column.
         
      Result 0 rows 0 columns. HAVING other_rides > 0 give us info about other type of rider.

6. Investigate what Task 5 actually turned up. Are there genuinely a third rider type, inconsistent capitalization, or something else? Note it.

      If we do not use LOWER("Member type") in 'trips_legacy' table it will calculate all rides from 'trips_legacy' table because "Member type" was like Member and Casual.

7. Write a CASE WHEN that labels each trip as 'Weekday' or 'Weekend' based on its start date, and use it to compare ride counts between the two.
   
      Result 2 rows 2 columns.

8. Combine two CASE WHEN expressions in one query — capacity tier and duration bucket, for example — to build a small cross-tabulated summary in a single SELECT.

     Result 20 rows 5 columns.
 

## Block 4: Cleaning the Week 1 Station Gap, With CTEs (75 min)

**Goal:** Actually resolve the unmatched-station problem, using Day 2's CTEs alongside today's `COALESCE` and `CASE WHEN`.

1. Build a CTE that joins trips to stations with a LEFT JOIN, and applies COALESCE(neighborhood, 'Unknown') and COALESCE(capacity, 0) in the same step.

    Result 65 rows 6 columns.

2. Build a second CTE on top of the first that adds a CASE WHEN column flagging each row as 'Matched' or 'Unmatched', based on whether the original stations join produced a real value or a default.

      Result 65 rows 7 columns.

3. Use the two CTEs together to report total rides and average duration, split by the 'Matched'/'Unmatched' flag — this quantifies, precisely, how much of your data the station gap actually affects.
    
    Result 43 rows 4 columns.

4. Decide whether stations_summary from Week 1 should be rebuilt using this cleaner approach. Rebuild it if so, using CREATE TABLE stations_summary AS SELECT ... from the chained CTEs.
    
    Probobly COALESCE(s.capacity,'0') affect to averege per Neighborhood so better use null for ignore this in calculations.

## Block 5: Reflection (60 min)

Answer in a few sentences each:

1. Block 1 demonstrated the `NOT IN`/`NULL` pitfall on real data from this dataset, not a hypothetical. Where else, now that you know which columns can contain `NULL` from your Task 3 list, would you go back and double check earlier Week 1 or Week 2 queries for the same silent failure?

    The most exposed earlier queries are any WHERE or JOIN filters touching start_station_id, end_station_id, start_station and end_station columns. 
    Task 3 confirmed can hold both true NULL. 
    Any NOT IN or = comparison on those columns without a paired IS NULL check was silently dropping rows, meaning ride counts in neighborhood aggregations or station-level summaries from Week 1 were quietly understated without any error or warning.
   
2. Block 2, Task 7 asked you to name a case where `NULL` should stay `NULL` rather than get a default. Explain that choice in more depth now — what would `COALESCE`ing it have hidden, and from whom?

    COALESCE-ing a NULL duration to 0 would have pulled the average trip length downward in every aggregation. Hiding the true typical ride from analysts, stakeholders or people who making decisions about bike redistribution or pricing. 
    The people most harmed by that hidden distortion would be anyone using the average as a benchmark: a  zero inflated mean looks like riders are taking shorter trips than they actually are.
    Which could quietly justify cutting station capacity or electric bike availability in ways the real data would never support.


3. Block 3 surfaced whether `rider_type` actually has more than two clean values. If it does, walk through how you'd decide whether that's a data entry problem, a genuine third category, or something that changed partway through the seven-year date range.

    The most robust first step is normalizing the field before any frequency count. Wrapping rider_type in LOWER(TRIM()) in 'trips_legacy' table collapses case that would otherwise register as distinct categories.
    In a seven-year dataset spanning likely multiple data pipelines, a value like 'Member' and 'member' are almost certainly the same category, not two, and counting them separately would overstate the problem. 

4. Block 4 quantified exactly how much of your data the station gap affects. Now that it's a real percentage instead of a vague concern, has your opinion changed on whether it's a small footnote or something that should be flagged prominently in any report built on this data?

    Once the missing station data becomes a concrete percentage rather than a vague "some rows are missing," it stops being a mistery.
    If even 5–10% of rides have no neighborhood linkage, every neighborhood-level ranking or heatmap in the report is built on a biased subset, and any reader who does not know that will draw confident conclusions from incomplete geography. 
    In our case we have in 'start is null' in condition column - 3,951,423 rows 12,37 % from whole data. end_station 4,149,857 rows 12,99 % from whole data.
    It should be called out in a data quality section at the top of any report, not buried in an appendix, because the gap does not affect all neighborhoods equally.  Stations with looser ID consistency likely skew toward specific areas.

5. Tomorrow moves into detecting anomalous periods in the trip data over time — separating a genuine trend from a data gap or a one-off event. Based on everything you've cleaned and flagged today, name one specific period or pattern in the data you'd want to investigate first, and why.

    The first target would be 2019–2021, because any sharp drop in ride volume there is ambiguous — it could be a genuine COVID-era behavior shift, a temporary station closure, or a data collection gap.
    Separating that period cleanly matters before fitting any seasonality model, because if those months are left in as normal data points they will flatten the baseline and make post-2022 recovery look like ordinary growth rather than a rebound.
