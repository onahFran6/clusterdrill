# q103-32: Replace an in-flight CronJob run instead of skipping or stacking it

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-32-cronjob-concurrencypolicy-replace-slow-run`

`setup.sh` already created a CronJob named `heavy-sync` in namespace
`q103-32-cronjob-concurrencypolicy-replace-slow-run`. It runs every minute, and each run takes
noticeably longer than a minute to finish. `.spec.concurrencyPolicy` is currently unset, which
defaults to `Allow` - so by the time the next scheduled run fires, the previous run's Job may
still be active, and Kubernetes just lets a second Job start alongside it.

For `heavy-sync` specifically, a stale run is never worth finishing once a newer one is due: the
newest data always supersedes it. Skipping the new run entirely would also be wrong - the stale
run must not be allowed to keep going once a fresher run is due.

Edit `heavy-sync` so that whenever a new scheduled time arrives while a previous run is still
active, the previous run's Job is killed and replaced by the new one, rather than the two running
side by side or the new one being skipped. Do not change the schedule.

## Hint

Search kubernetes.io/docs for **"cronjob concurrency policy"** - the CronJob concept page's
"Concurrency Policy" section lists all three `.spec.concurrencyPolicy` values, including the one
that terminates the currently running job and replaces it with a new one.
