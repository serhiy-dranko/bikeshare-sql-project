## Week 1 Reflection and Next Steps

### Part A: Looking Back Across the Week

Answer these in a few sentences each — written answers, not just thought through, since the act of writing tends to surface gaps that just thinking past doesn't.

1. Day 1 was about building `trips` from raw, inconsistent files. Which specific decision from that day — the schema standardization, the `union_by_name` handling, the capitalization cleanup — turned out to matter most by the time you reached Day 4? Would you have predicted that on Day 1?

    The station name cleanup (LOWER/TRIM) and the shift to joining on station IDs instead of names ended up mattering most. 
    Free text name matching was the real fragility point. It's exactly what caused the silent join failures. 
    At the time, schema standardization felt like the harder problem and the naming/ID issue looked like a minor detail.

2. Day 2 relied entirely on manual filtering and hand comparison — no aggregation. Day 3 replaced that with `GROUP BY`. Describe, concretely, one moment this week where you felt that shift: a task that would have been painful the old way and was straightforward the new way.

    I'd used GROUP BY in Power BI before, so the logic itself wasn't new - but applying it directly in SQL through Beekeeper felt far more transparent and controllable than Power BI's abstracted aggregation layer.
    Writing the group and the filter myself made it obvious why a number came out the way it did, instead of trusting a visual instrument.

3. Block 3 today surfaced stations in `trips` with no match in `stations` — a real data quality problem, not a hypothetical one. If you were handing `stations_summary` to someone else on the team, what would you tell them about trusting the neighborhood and capacity figures, given what you now know about the unmatched stations?

    I'd flag that these figures aren't fully reliable yet. 
    Before trusting them, we need a proper crosswalk table mapping station ID to canonical name, lat and lon. 
    So raw trips data joins against a clean, authoritative reference instead of inconsistent station names pulled straight from the source files.

4. Across the week, where did you personally get stuck longest — not where the material was hardest in the abstract, but where you specifically lost the most time? What was actually going wrong when that happened, looking back on it now?
    
    Documentation, more than the material itself.
    This week's content was largely familiar to me, so the friction was in tracking down the right syntax/reference rather than understanding the concepts.

5. The course opened Week 1 by pointing at a real problem: loading seven years of raw trip data into Power BI was slow. Has that problem actually been solved by what you built this week, partially solved, or not solved yet? Be specific about what `stations_summary` would and wouldn't fix if you connected it to Power BI right now.

    Yes, largely solved. What took hours in Power BI now runs in under a minute. 
    We basically traded the family car for a starship. The next bottleneck isn't performance anymore, it's data quality.
    Better to spend time cleaning stations_summary properly before handing it back to Power BI, rather than rushing a shiny but unreliable table into a dashboard.

### Part B: Conceptual Check

6. Explain, without looking anything up, the difference between `WHERE` and `HAVING` — and separately, the difference between `INNER JOIN` and `LEFT JOIN`. If either explanation feels shaky, that's useful information about what to revisit before Week 2 builds on it.

    `WHERE` filters raw rows before grouping happens; 
    `HAVING` filters groups after aggregation (like filtering on a `COUNT` or AVG result). 
    You can't swap them because WHERE runs too early to see an aggregate, and HAVING runs too late to be efficient on row-level filters.

    `INNER JOIN` only keeps rows that match in both tables. 
    `LEFT JOIN` keeps every row from the left table even without a match, filling the right side with NULL. 
    We saw this directly: INNER JOIN on stations silently drops rides at closed stations, LEFT JOIN keeps them.

7. `stations_summary` is a materialized table, not a live query. What has to be true about how often the underlying `trips` and `stations` data changes for that decision — storing a snapshot instead of always querying fresh — to be the right one?

    `stations_summary` as a static table only makes sense if trips and station don't change often. 
    Historical data loaded in batches, not updated live. If either source changed frequently, the snapshot would go stale and mislead anyone using it and you'd need to refresh it regularly or just query live instead.

8. If you had to defend one number in `stations_summary` to someone skeptical of it — say, the average duration for your busiest station — could you trace that number back through every transformation that produced it, from the raw CSV files on Day 1 to the final table today? Try actually doing it, not just answering yes or no.

    raw CSVs → 
    loaded into trips_legacy (old schema) and trips_modern (new schema) → 
    combined into trips → 
    filtered for valid duration and non-null stations → 
    LEFT JOINed to station for capacity&coordinates → 
    averaged and rounded → 
    filtered by HAVING capacity >= 100

    I can explain the logic of every step, but I wouldn't fully trust the number yet without re-checking weak points, like whether the station join is matching correctly for that specific station if we have renaming of the station or want stations witch where closed, beter create cross table with all stations info and then join them to the id in our data. Before defending it to a skeptic, I'd rerun the join-match diagnostic.

### Part C: Next Steps

- Write down one open question about the bikeshare data that you don't yet know how to answer in SQL. Revisit it at the end of Week 2 and check whether it's answerable now.

    Open question: 
    Which specific routes (start station → end station pairs) are the most popular over the last seven years. Not just the busiest individual stations, but the most-traveled station-to-station combinations?
