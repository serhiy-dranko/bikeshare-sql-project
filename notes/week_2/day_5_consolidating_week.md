1. Compare how long today's consolidation took against how long you expected. Was two weeks of work harder or easier to bring together than you assumed going in?

    Honestly, editing the sections themselves was quick, but verifying that the numbers actually agreed across three documents in the README's, data_quality.md's  and the cross-reference in week2_trend_analysis.md. Two weeks of accumulated notes wasn't hard to read, but it was harder than expected to trust without checking.

2. Block 3 asked you to rewrite the "Known Data Issues" section rather than just append to it. What does keeping documentation current, instead of just additive, actually require — and is that something you'll keep doing naturally going forward, or does it need to stay a deliberate step like today?

    Keeping documentation current instead of additive requires treating every existing claim as a hypothesis to retest against the newest evidence, not a fact to build on top of. 
    Left to a default, I'd lean toward appending, since it's doesn't require holding the old claim and the new evidence in tension at the same time. 
    So I think this needs to stay a deliberate step, not something that happens naturally as a by product of writing new sections.

3. Looking at the repo as a whole now, what's the single query or table you're most confident you could defend to a skeptical reviewer, start to finish — and what's the one you'd still want to double check before standing behind it?

    The Day 3, Block 4 Matched/Unmatched quantification is the one I'd defend most confidently. 
    It's simple and it was checked two independent ways (start_station_id IS NULL and the LEFT JOIN no-match count) that converged on the same number, which is real evidence, not just a plausible story. 

4. Week 3 moves into window functions and a first introduction to dbt. Based on the repo as it stands today, what's one thing about your current SQL files or structure that you expect dbt's model-based approach will make you rethink?

    The thing I'd expect to change most is the amount of copy-pasted JOIN + COALESCE logic. The trips to station LEFT JOIN with COALESCE (neighborhood, 'Unknown') gets rebuilt independently in Day 2, Day 3 and Day 4's SQL files, 
    the dbt's model layer is built for defining that join once like a stg_trips_stations model and having every downstream query reference it, instead of trusting that five separately written CTEs all handle the unmatched-station flag identically.
