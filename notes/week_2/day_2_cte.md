# Day 2: Common Table Expressions

**Total time: 6 hours**

## Time Budget

| Block | Topic | Time |
|-------|-------|------|
| 1 | CTE basics: rewriting subqueries | 75 min |
| 2 | Multiple CTEs in one query | 75 min |
| 3 | Chained CTEs | 90 min |
| 4 | Mini-project: a multi-step ridership report | 75 min |
| 5 | Reflection | 45 min |

---

## Block 1: CTE Basics — Rewriting Subqueries (75 min)

**Goal:** Get comfortable with `WITH` syntax by converting queries you already trust.

### Do this: 7 tasks


6. Try writing a `WITH` clause with no trailing `SELECT` at all, just to see what error you get — useful for recognizing that error quickly later.

  Parser Error: syntax error at or near ";" LINE 7:   GROUP BY rider_type); ^LINE 7:   GROUP BY rider_type);
   
7. Write one or two sentences on how the CTE version of Task 1 compares to reading the original scalar subquery. Be specific about what got easier, not just "it's cleaner."

   Calculating are separated from query and calculated before as temp view.

---

## Block 2: Multiple CTEs in One Query (75 min)

**Goal:** Break a question into named, independent pieces before combining them.

5. Identify a case where using multiple CTEs is actually unnecessary — where a single `GROUP BY` with a `JOIN` would answer the same question just as clearly. Write that simpler version.
   
   Task 1's two-CTE join (total_rides + average_trip_duration) is unnecessary — both CTEs group trips by the exact same keys (start_station_id, start_station), so they're really one aggregation split into two for no reason: One GROUP BY gets both metrics — no join needed, since both come from the same table and the same grouping.
   
6. Write a short note on how you'd decide, going forward, whether a question needs multiple named CTEs or just one straightforward query.

   If a later step needs to reuse an earlier calculation as an independent, checkable unit (or the grouping keys differ between stages), use named CTEs.
   If everything aggregates from the same table on the same keys with no reuse, one straightforward GROUP BY + JOIN is clearer and there's nothing gained by splitting it up.

---

## Block 3: Chained CTEs (90 min)

**Goal:** Build a multi-step transformation where each CTE depends on the one before it.

5. Deliberately break the chain by referencing a CTE before it's defined (reorder your `WITH` clauses) and read the error message carefully — this is a mistake worth recognizing quickly.

   Catalog Error: Table with name above_avg_stations does not exist!

7. Time roughly how long it took you to build this chain versus how long Day 1's equivalent correlated subquery took to get right. Note which felt more like debugging and which felt more like building.

   Correlated subquery: usually written faster "the first time", because it is one block of logic - but when something goes wrong (wrong numbers, duplicates), it is harder to understand where the problem is, because there are no intermediate check points. This often feels like blind debugging.
   Chained CTE: longer to write at once (more named stages), but each step can be SELECT * FROM <cte> and checked in isolation. This feels more like building brick by brick its slower at the start, faster when fixing errors.

---

## Block 4: Mini-Project — A Multi-Step Ridership Report (75 min)

**Goal:** Use everything from today to build one real, chained report from scratch.

1. Design a report answering: "For each neighborhood, what's the busiest station, and how much busier is it than that neighborhood's average station?" Sketch the stages you'll need before writing any SQL.

      Station_totals: one row per station, with its neighborhood and its total ride count. This is the raw material everything else builds on.
      
      Neighborhood_averages: one row per neighborhood, with the average total_rides across its stations (computed from Station_totals, not from trips again).
      
      Busiest_per_neighborhood: one row per neighborhood — just the single station with the max total_rides (computed from Station_totals, using a ranking function).
      
      Final SELECT: join busiest station to neighborhood average and compute the difference.


---

## Block 5: Reflection (45 min)

Answer in a few sentences each:

1. Pick one query from today that you also wrote a version of yesterday, using subqueries. Set the two versions side by side. What specifically changed — not "it's more readable," but where exactly did the readability come from?

      Query pair: the "stations above their neighborhood average" question — yesterday as a correlated subquery, today as total_rides → neighborhood_names → neighborhood_avg_raides → above_avg_stations. 
      The correlated subquery has one anonymous inline SELECT AVG(...) sitting inside a WHERE clause, so you have to mentally execute it to know what it means. 
      The chained version gives that same calculation a name (neighborhood_avg_raides) and a place in a sequence, so you can point at it, run it alone, and know what it holds without re-deriving it from the surrounding logic.
   
2. Block 3 asked you to time chained CTEs against yesterday's correlated subquery for the same question. What does that comparison tell you about when the extra structure of a CTE is worth it, and when it might be overkill for a simpler question?

      It tells me the extra structure earns its cost when a question has more than one moving part that gets reused. 
      Here, total_rides is read by both neighborhood_avg_raides and above_avg_stations, so naming it once avoids repeating that logic twice (which the correlated subquery effectively forces, since the aggregation is recomputed per row anyway). 
      For a single purpose, one-shot filter with no reuse  like "just show me rows where X > average of X" and nothing downstream needs that average again — a subquery is proportional to the problem and a 4-stage CTE chain would be structure for its own sake.
      
3. The concepts file noted that a CTE isn't automatically cached or free — it can still cost what the equivalent subquery costs. Given that, what's actually driving your choice to use a CTE: performance, or something else? Be honest about which one it actually is.

      Honestly, it's not performance. DuckDB doesn't materialize or cache CTEs by default, so a chain can cost exactly what the equivalent nested subqueries would. 
      What's actually driving the choice is debuggability and communication: being able to isolate one stage with SELECT * FROM   stage_name and inspect it, and having stage names that describe what a teammate (or future me) is looking at without re-reading the logic inside. 
      That's a readability/maintenance win, not a runtime one, and I should stop implicitly justifying it as "cleaner/faster" when what I mean is "easier to reason about."
   
4. Tomorrow moves into `NULL` handling, `COALESCE`, and `CASE WHEN` — the tools for actually fixing the data issues you've been noting since Week 1's unmatched-station problem. Looking back at your `notes/data_quality.md` from Week 1, Day 5, which issue there do you expect tomorrow's tools to actually resolve, and which do you suspect will still need a judgment call?

      I'd expect COALESCE to actually resolve the unmatched-station fallback labeling. Turning the NULL neighborhood (stations outside DC, in VA/MD) into an explicit value like 'Cluster Other - Outside DC (VA/MD)' instead of a silent NULL that quietly drops out of joins or groupings. 
      What I don't expect it to resolve on its own is the genuine ambiguity cases - e.g., a station sitting right on a cluster boundary, or a short_name/station_id mismatch between trips and station that isn't a clean 1:1 join. 
      CASE WHEN can encode a rule, but deciding which rule is correct for a boundary station still needs a judgment call, not just cleaner NULL-handling.
   

**Deliverable:** The finished chained-CTE query from Block 4, with a one-line comment above each CTE stage, plus your four reflection answers.
