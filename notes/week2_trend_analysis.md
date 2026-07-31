# Week 2 Trend Analysis - Anomaly Report
## Flagged Period: 29-30 March 2025

### What the data shows
Z-score analysis flagged two consecutive days in late March 2025 as extreme outliers.
The surrounding week for context:

  <img width="1095" height="447" alt="Screenshot 2026-07-31 103616" src="https://github.com/user-attachments/assets/cda46ac2-c554-41ea-9efd-215e8992e036" />


  Both flagged days exceed ±3 under both global and per-month standardization,
confirming this is not a seasonal artifact but genuinely anomalous even relative
to other March days across all seven years.

### Ruling out a data gap
The surrounding week shows continuous daily counts with no NULLs or zero-ride days
before or after the spike. The only documented schema boundary in this dataset -
the transition from `trips_legacy` to `trips_modern` - occurred in late March 2020,
not 2025. This period sits cleanly within a single pipeline era. No data gap
coincides with these dates.

### Ruling out a weather effect
NOAA weather data was not loaded as part of this SQL project, which is a limitation
of this analysis. However, the shape of the spike argues against weather as the
primary driver: a weather event would typically produce a gradual build and decay,
whereas the data shows an abrupt single-day peak on 29/03 and 31/03 followed by an immediate
return to Normal on 01/04. Weather separetley rarely produces that sharp a profile.

### Ruling in a known external event is Cherry Blossom Peak Bloom
29 March 2025 was the day after Washington D.C.'s cherry blossoms reached peak
bloom witch one of the most heavily attended annual events in the city. 

This explains every feature of the spike:

- **35,569 rides on 29/03** is the all-time single-day record for Capital Bikeshare.

  <img width="497" height="318" alt="Screenshot 2026-07-31 103727" src="https://github.com/user-attachments/assets/d60f36c9-a2bc-4de0-983d-63269fa7c7ad" />


- The build-up from 27–28/03 (Notable) reflects crowds arriving ahead of peak bloom
  weekend, with Saturday and Sunday drawing the largest volumes.
- The immediate return to Normal on 01/04 (Monday) is consistent with tourist
  crowds dispersing after the weekend rather than any structural shift in ridership.

### Conclusion
The 29–30 March 2025 spike is a confirmed real-world event, not a data artifact.
Cherry Blossom Peak Bloom drove Capital Bikeshare to its all-time daily record,
producing z-scores of 4.03 and 3.18 against the March baseline. It should be
documented in any report as a known annual outlier and excluded from baseline
trend calculations, while being preserved as a separate signal of how major civic events interact with bikeshare demand.

### Limitations
- NOAA weather data not loaded; temperature and precipitation on 29–30/03/2025 cannot be confirmed from within this SQL project.
