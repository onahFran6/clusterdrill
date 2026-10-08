# q118-12: Keep sync runs from overlapping

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-12-forbid-stops-overlap`

Team Europa has *CronJob* `sync` running every minute; each run lasts about two and a half minutes.
Observe the active Job count after about three minutes (practice observation, ungraded).
Change it so a new run is skipped while the previous run is active, and let the active run finish rather than replacing it.
Keep the image, command, and schedule unchanged; clear old Jobs, wait another three minutes, and confirm no more than one Job is active.

## Hint

Search kubernetes.io/docs for "CronJob concurrency policy" and compare what happens to a running Job.
