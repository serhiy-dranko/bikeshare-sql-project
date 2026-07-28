# Day 1: Writing Your First Subqueries

**Total time: 6 hours**

## Time Budget

| Block | Topic | Time |
|-------|-------|------|
| 1 | Scalar subqueries in SELECT and WHERE | 90 min |
| 2 | Multi-row subqueries: IN, EXISTS | 90 min |
| 3 | Subqueries in FROM | 75 min |
| 4 | Correlated subqueries | 75 min |
| 5 | Reflection | 30 min |

---

## Block 1: Scalar Subqueries in SELECT and WHERE (90 min)

**Goal:** Use a single computed value as a comparison point or an attached column.


 Try writing a scalar subquery that would actually return more than one row (for example, station capacity without an aggregate), and confirm you get an error. Read the error message carefully — you'll want to recognize it later.

  Binder Error: Referenced column "capacity" not found in FROM clause!
  Candidate bindings: "latitude", "casual_rides_percentage", "average_ride_duration_min", "station_capacity"
  LINE 4:     WHERE total_rides = (SELECT capacity FROM stations_summary);

---

## Block 2: Multi-Row Subqueries — IN and EXISTS (90 min)

**Goal:** Filter based on a list of values or on whether a match exists at all, without joining.

 Write one sentence on when you'd now reach for `EXISTS` over `IN` by default, based on what Task 4 showed you.

   I'd reach for EXISTS over IN by default whenever the subquery's column could contain NULLs, since NOT IN silently returns zero rows if even one NULL sneaks into the subquery's result, while NOT EXISTS (and EXISTS) evaluate row-by-row and are immune to that trap.

---

## Block 3: Subqueries in FROM (75 min)

**Goal:** Treat a query's result as a table, so you can aggregate something that's already an aggregate.

---

## Block 4: Correlated Subqueries (75 min)

**Goal:** Write subqueries that reference the outer query's current row, and recognize when that's actually necessary.


4. Time, even roughly, how Task 3 feels to write compared to Block 3's neighborhood-based queries. Which approach would you reach for first next time, and why?

   This query was much faster to write than Block 3, mostly because neighborhoods_summary already has everything pre-joined and pre-aggregated — no COALESCE, no rebuilding joins, just one WHERE and a self-referencing subquery. 
   Block 3 took longer because I was still constructing that join from raw tables and debugging alias mismatches along the way. Next time I'd reach for a pre-built summary table first whenever one exists, since the actual analysis logic is simple once the data is already flat.
   I'd only go back to the full LEFT JOIN + GROUP BY chain from raw tables when I need to build that summary table in the first place.
   
7. Write two or three sentences distinguishing correlated from non-correlated subqueries in your own words — not the definition from the theory file, but how you'd explain it to someone who hasn't read it.

    Basically: non-correlated is "calculate this one number first, then use it everywhere," while correlated is "for each row, ask a fresh, personalized question."
    A non-correlated subquery is completely self-contained. 
    A correlated subquery can't do that, because it reaches back into the outer query for a value (like "this row's neighborhood") and uses it in its own filter.


---

## Block 5: Reflection (30 min)

Answer in a few sentences each:

1. Before today, every multi-table question got solved with a `JOIN`. Now you have three tools — join, subquery, and correlated subquery — that can overlap in what they solve. Walk through one query from today and explain why you chose the approach you used over the alternatives.

  For "top station per neighborhood," I used a FROM subquery plus a correlated WHERE subquery instead of a plain JOIN, because the question needed two levels of aggregation. 
  Per station totals, then a per neighborhood max and a single JOIN/GROUP BY can't compare one row's aggregate against another row's aggregate within the same group.
   
2. Block 2 surfaced a real difference between `IN`/`NOT IN` and `EXISTS`/`NOT EXISTS` around `NULL`s. Where else in this dataset, based on what you know from Week 1, might that same gap quietly affect a result without throwing an error?.

  Any NOT IN filter built on start_station_id, end_station_id, or rider_type is at risk, since we already know those columns contain NULLs. 
  The query like "stations that never appear in trips" using NOT IN would silently return zero rows the moment one NULL sneaks in, the same trap we hit and fixed with NOT EXISTS.
   
3. Subqueries nested inside subqueries — a `FROM` subquery containing a `WHERE` subquery — get hard to track quickly. Did you run into that today? CTEs, coming up later this week, exist specifically to solve that readability problem. Based on today, what would you want a CTE to do differently?

  Yes, the neighborhood ranking query got hard to track because the same "totals by station" logic had to be duplicated almost word by word in both the FROM and the WHERE subquery. 
  I'd want a CTE to let me name that logic once and reference it twice, instead of keeping two copies in sync by hand.

**Deliverable:** A short SQL file with your final answers to Block 3, Task 4 (highest-ridership station per neighborhood) and Block 4, Task 3 (stations above their neighborhood's average), each with a one-line comment explaining the approach.
