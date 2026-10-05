# q103-19: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#time-zones

**Approach A - Fastest (exam default).** `kubectl edit cronjob morning-standup-reminder -n
q103-19-cronjob-timezone-fix`, then add a `timeZone` line next to `schedule` in vim - visible
before you save:

```text
/schedule:
o  timeZone: America/New_York<Esc>
:wq
```

**Approach B - Scripted equivalent (what this file executes).** A JSON patch adds the same
field non-interactively - this repo's automated grading runs exactly this:

```sh
kubectl patch cronjob morning-standup-reminder -n q103-19-cronjob-timezone-fix \
  --type='json' -p='[{"op": "add", "path": "/spec/timeZone", "value": "America/New_York"}]'
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - kubectl edit | low | low (new line visible before save) | high |
| B - JSON patch | low-medium | medium (wrong `op`/path fails silently) | medium |
