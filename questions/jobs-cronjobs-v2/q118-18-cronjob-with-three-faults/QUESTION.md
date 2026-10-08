# q118-18: Repair a report manifest with three faults

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-18-cronjob-with-three-faults`

Team Deimos has a local manifest `report-cj.yaml` in your terminal working directory.
It should create *CronJob* `report` every five minutes using key `token` from *Secret* `report-secret`, but it cannot apply and has three faults.
Find each fault and note whether it appears during apply or Pod startup (practice observations, ungraded).
Fix the file, apply it, and trigger *Job* `report-now` that completes and prints `report sent`.
Keep the Secret and report workload unchanged.

## Hint

Search kubernetes.io/docs for "CronJob schedule syntax", "Job restart policy", and "Secret optional keys"; check both API errors and Pod events.
