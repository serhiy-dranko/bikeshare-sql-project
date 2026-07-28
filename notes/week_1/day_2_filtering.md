## Reflection Questions

1. `WHERE rider_type = 'Member'` and `WHERE rider_type = 'member'` can return different results. Why does that happen, and what does it tell you about how a database compares text versus how you might casually think about "the same" value?   

        By default, SQL comparison is byte-for-byte on the string's characters, so 'Member' and 'member' are literally different sequences of bytes even though they represent the same concept to a human. This is a reminder that a database doesn't understand meaning  "sameness" to a machine is exact character equality unless you explicitly tell it to normalize case (e.g. with LOWER()).

2. In Block 3, filtering by month across all seven years (every July, regardless of year) is a fundamentally different question than filtering by a single year. Explain, in your own words, why these require different SQL logic even though they both involve `start_time`.  

        Filtering by year keeps the date's natural ordering (years are sequential, so a simple range like >= AND < works cleanly), but filtering by "every July regardless of year" throws away that ordering entirely — you're not asking "is this timestamp in a range," you're asking "does one specific component of this timestamp match a value." That requires decomposing the timestamp into its parts first (date_part('month', ...)) rather than comparing the whole thing as a range.

3. Task 4 in Block 4 showed a query that ran without error but silently returned the wrong result. Why is that kind of failure more dangerous in real analytics work than a query that throws an obvious error?  

        An error stops you immediately and forces you to investigate before you can act on anything, so the mistake never leaves the query editor. A silently wrong result looks legitimate, gets copied into a report or dashboard,and can drive real decisions before anyone notices. The cost of discovering it is much higher because it may already be embedded in downstream conclusions.

4. In Block 5, you approximated a "top stations" ranking by running several separate filtered queries and comparing counts by hand. What specifically makes this approach fragile or hard to trust as the number of candidate stations grows — and what would you need in order to trust the ranking fully?  

        Every additional station means another separate query, another number to remember, and another chance to mistype a filter or misread a result when eyeballing them side by side. there's no single sorted view guaranteeing the comparison is complete or correct. To trust the ranking fully you'd need one query that groups and orders all stations at once (i.e. GROUP BY + ORDER BY), so the ranking is computed and verified by the database rather than assembled by hand.

5. Day 1 introduced the idea that Capital Bikeshare's raw files have two different schemas across the seven-year range. Where in today's tasks did that schema difference actually have the potential to produce a wrong answer, even if you didn't hit it directly?  

        Any task touching bike_id, rider_type, or bike_type (like Block 4's CASE/year counts, or Block 5's station groupings) could silently under- or overcount if some years used different column names or category labels (e.g. "member" vs "Member") that weren't perfectly reconciled by union_by_name, even though the query ran without error. The risk is highest anywhere you filter or group on a column whose meaning or spelling shifted between the old and new Capital Bikeshare schema.

6. If someone on the operations team asked you "which station is busiest," what's actually missing from your Block 5 answer that would make you hesitate to hand it over as a final answer, rather than a rough first pass? 

        What's missing before calling it final: The current answer only counts raw ride volume per station without checking for data completeness (missing months/years, duplicate loads) or considering whether "busiest" should account for things like time period, ride duration, or per-day rate rather than a raw total count. It's a first pass, not a verified metric, until those caveats are checked and the definition of "busiest" is confirmed with the person asking.

7. Today deliberately avoided `GROUP BY`. Based on the friction you felt in Block 5, write a short prediction: what do you expect `GROUP BY` to actually do differently, before you've been taught it formally? 

        I expect GROUP BY will let the database do in one query what I was doing manually across severa. Collapsing all rows for each station into one row automatically and computing the aggregate for every group at once. That should eliminate the fragility of hand comparing separate filtered queries and directly produce a trustworthy ranked list of all stations, not just the ones I happened to check.
