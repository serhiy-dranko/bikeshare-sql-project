## Block 6: Reflection (30 min)

Answer in a few sentences each:

1. Block 2 asked you to decide whether gap days should be excluded or treated as `0`. Now that you've run the full anomaly-flagging pipeline, did that early decision end up mattering for your final results — did any gap day almost get mistaken for a real anomaly?

    Treating gap days as 0 via COALESCE rather than excluding them entirely meant those days entered the stats CTE and pulled the global mean downward and the standard deviation upward — which actually made it harder to flag real anomalies, not easier. 
    In practice none of the zero ride gap days came a day with a non-zero mean will produce a large negative z-score, which the anomaly_flag CASE caught correctly as Extreme on the low end. 
   
2. Block 4 showed your flagged-day list changing once you moved from one global standard deviation to per-month standard deviations. What does that tell you about the risk of applying a single statistical threshold to a dataset with strong seasonal patterns?

    A single global standard deviation effectively sets a higher bar in summer and a lower bar in winter, because high-volume summer days inflate the spread for everyone. 
    A January day with 8,000 rides might look completely normal against a global stddev built on July peaks, when in fact it is an extraordinary for January and the per month approach correctly flags it. 
    The cherry blossom spike at z = 4.03 monthly versus 3.89 global was a small difference in this case, but the direction is the point: collapsing twelve months of seasonal variance into one number quietly suppresses anomalies in low-season months and raises the detection
     bar in high-season ones.

   
3. Look back at Week 2 as a whole — subqueries, CTEs, NULL handling, and now anomaly detection. Which of those four tools did you end up leaning on most heavily today, and did you expect that going in?

     CTEs ended up carrying almost everything. Every logical step from date_range through daily_series through stats through the final comparison was a separate named CTE and the query would have been genuinely unreadable as nested subqueries.
     That was not fully expected going in NULL handling felt like it would dominate the day given how much time was spent on it earlier in the week, but it turned out to be a one-line COALESCE and a NULLIF guard, while the CTE chain grew to five or six layers before the final SELECT.
     CTEs are less a tool and more the scaffolding that makes all the other tools usable at scale.

   
4. This week's tools got you a defensible flagged list, but Block 5 still required real research and judgment to turn a flagged date into an actual explained finding. What does that tell you about where SQL's job ends and an analyst's job begins?

   SQL's job ends at producing a defensible, reproducible list of dates that are statistically unusual and  it cannot tell you why they are unusual, only that they are.
   The cherry blossom finding required knowing that Washington D.C. has an annual peak bloom event, recognising that 29 March fell on the day after it, and understanding that a casual-rider spike on a weekend fits the tourist-crowd pattern rather than a commuter one. None of that is in the data.
   The analyst's job is everything that happens after the flag: context, external research, ruling things in and out, and translating a z-score into a sentence a stakeholder can act on.
   
5. Week 3 introduces window functions, which the concepts file said would replace most of today's self-joins and correlated subqueries. Based on today's experience, which specific task from this file are you most looking forward to redoing with a window function instead?

    The trailing 7 day average self-join is the clearest candidate — joining daily_series to itself on a date range condition to compute AVG(total_rides) works, but it is expensive and conceptually awkward because it forces you to think about the join before you think about the calculation. 
  The day over day comparison self join is a close second for the same reason.
