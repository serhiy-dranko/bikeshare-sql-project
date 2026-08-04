## Block 6: Reflection

1. Pick one query you rebuilt today and had also built in Week 1 or Week 2 using a subquery, join, or self-join. Set both versions side by side. Beyond just being shorter, what changed about how easy the query is to actually trust at a glance?

    Week 3 Day1 Block 5 Task 2
    Beyond length, what changed is where the correctness lives. In the self-join, correctness depends on three separate things lining up: the join direction (prev joining to today, not the reverse), the date arithmetic in the BETWEEN (getting -7 days and -1 day right, and not off-by-one), and the GROUP BY afterward doing what I expect instead of silently fanning out rows if the join condition ever matched more or fewer rows than intended. 
    The window version collapses those three moving parts into one declarative statement: ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING names exactly which rows are included, directly in the syntax, with no join condition to misdirect and no GROUP BY. 

2. Block 2 showed `RANK()` and `DENSE_RANK()` diverging on ties. Pick a real question from this dataset where the choice between them would actually change your answer, not just the row numbers.

    "What are the top 3 busiest days by ride count?" is a case where the choice matters, not just cosmetically. If three days are tied for the busiest, RANK() gives them all rank 1 and then jumps straight to rank 4 for the next day.
     So filtering WHERE rank <= 3 returns only those 3 tied days, excluding a 4th day that might otherwise feel like it belongs in "the top 3."
     DENSE_RANK() would assign rank 2 to that next day, so WHERE rank <= 3 would include it. The actual set of days returned changes depending on which function you pick, not just their labels.

3. Block 4, Task 8 asked which version you'd trust more in someone else's code. Now flip it: if you were the one leaving code for someone else, would you always default to the window function version, or is there a case from today where the more explicit self-join or subquery might still communicate the intent better?

    No, Block 3's day-over-day LAG() and Block 4's z-score stats CTE are different situations. LAG() for "yesterday" is unambiguous and the window version is strictly better. 
    But something like a multi-condition join (matching trips to stations on both ID and a date-effective range, from Week 2) can genuinely be clearer as an explicit JOIN ... ON with named conditions than as a window function forced to express relationships
    it wasn't designed for a window function trying to do a job that isn't a strict "look at nearby rows in one order" job can end up more cryptic than a join, not less.

    
4. The Day 1 concepts file closed with a note that today's `SELECT` statements are close in shape to what a dbt model looks like. Pick one query you wrote today and, in a sentence, describe what you think would need to change (if anything) for it to live on its own as a single `.sql` file that other queries could build on top of.

    Taking the daily_series CTE from today's rebuilds wouldn't need much structural change since it's already a clean, self-contained transformation (calendar spine + LEFT JOIN + COALESCE), but I'd need to drop the hardcoded strftime display formatting (that's presentation logic, not data logic)
     and materialize it as its own model so the LAG/AVG() OVER() analysis queries could reference it via Temporary table daily_series  instead of re-declaring the CTE every time.

5. Tomorrow extends today's `OVER()` clause with window **frames** — controlling exactly which nearby rows a function considers, beyond just partitioning — and adds a new weather dataset to measure volatility, not just averages. Based on Block 5, Task 2's preview, what do you expect `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` is actually doing, in your own words?

    In my own words: for every row, instead of computing a function over the whole table or partition, it builds a small "sliding window" of exactly 7 rows.  The current row plus the 6 rows immediately before it in the specified order and only that slice is fed into the aggregate. 
    As the query moves row by row, the window slides along with it, always keeping the same width but shifting which rows are inside it. It's the mechanism that turns "average of everything" into "average of just what's nearby,"
    which is presumably also what'll let tomorrow's volatility/weather work measure how spread out or noisy a local stretch of data is, rather than the dataset as a whole.
