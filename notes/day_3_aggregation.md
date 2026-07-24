## Reflection Questions

c1. `GROUP BY` on its own, with no aggregate function, just returns distinct values. Why does adding `COUNT(*)`, `SUM()`, or `AVG()` change what each row in the result actually represents?

   Without an aggregate, GROUP BY just deduplicates rows, so each row still represents a single raw value with no computation behind it. Adding COUNT(*), SUM(), or AVG() turns each row into a summary of every row that shared that group's value, so it now represents a calculation across many original rows, not one of them.

2. In Block 3, `WHERE` failed when used directly on `COUNT(*)`. Explain, in terms of the order SQL actually processes a query, why `WHERE` and `HAVING` can't be swapped for each other.

   SQL processes WHERE before grouping/aggregation happens and HAVING after, so WHERE only ever sees raw, ungrouped rows and has no concept of an aggregate value yet. HAVING exists specifically to filter on the aggregates that only come into existence once GROUP BY has already run, so swapping them asks each clause to filter on something that doesn't exist yet at that stage of processing.

3. Block 5, Task 3 asked whether the top 10 stations change when filtered to a single year versus the full seven-year range. What would a large difference between those two rankings actually suggest about how the system has changed over time?
 
   A big difference would suggest the system itself has meaningfully changed over time. New stations opening, ridership shifting to different neighborhoods, seasonal or pandemic-driven demand shocks, etc. It would mean a single "TOP-10" label without a time context is misleading, since "busiest" depends heavily on which slice of history you're looking at.

4. In Block 2, `COUNT(*)` and `COUNT(ride_id)` could theoretically disagree. What would it mean, practically, if they didn't match on this dataset?

   If COUNT(*) and COUNT(ride_id) disagreed, it would mean some rows have a NULL in ride_id, since COUNT(*) counts every row while COUNT(column) skips NULLs. Practically, that would flag incomplete or corrupted records worth investigating before trusting any ride-level counts.

5. You compared a hand-picked, intuition-based ranking (Day 2) against a fully computed one (today). Beyond just being faster, what does the computed version protect you from that intuition doesn't?

   A computed ranking is exhaustive and consistent. It evaluates every station by the same rule and can't accidentally skip or misjudge one the way memory or gut feel can. Intuition is shaped by whichever stations happen to be memorable or recently seen. So it protects you from a systematic blind spot that speed alone wouldn't fix.

6. If a station appears in the "top 10 by total rides" ranking but not in the "top 10 by average duration" ranking, what does that combination actually tell you about how people use that station?

   It suggests the station has high overall traffic but each individual ride tends to be short, which usually points to commuter or point to point usage rather than leisure or tourist riding. That combination is a signal of how a station is used not just how much, since volume and duration are answering two different questions.

7. Block 4 pushed rounding and aliasing as a habit, not just a formatting nicety. What could go wrong later in a longer analysis if raw, unrounded, unaliased aggregate output gets used directly in a report without anyone cleaning it up first?

   Unrounded output can display long floating-point strings that look precise but aren't meaningfully more accurate, misleading readers about the certainty of the number. Unaliased output shows raw expressions like SUM(CASE WHEN...) as column headers, which is confusing or meaningless to anyone reading the report without seeing the underlying query.