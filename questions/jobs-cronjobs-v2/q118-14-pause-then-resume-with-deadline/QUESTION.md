# q118-14: Pause billing and avoid late catch-up runs

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-14-pause-then-resume-with-deadline`

Team Ganymede has *CronJob* `billing` running every minute.
Pause it without deleting it and compare Job counts over two minutes (practice observation, ungraded).
Then resume it with a rule that skips runs more than **30 seconds** late.
Keep its image, command, and schedule unchanged.

## Hint

Search kubernetes.io/docs for "CronJob suspension" and "deadline for delayed Job start".
