# q103-21: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#suspending-a-job

**Approach A - Fastest (exam default).** `kubectl edit job archive-purge -n
q103-21-job-suspend-unsuspend`, flip `suspend: true` to `false` in vim, save - the one-word
change is visible before you commit it:

```text
/suspend
ciwfalse<Esc>
:wq
```

**Approach B - Scripted equivalent (what this file executes).** A patch reaches the same result
non-interactively - this repo's automated grading runs exactly this:

```sh
kubectl patch job archive-purge -n q103-21-job-suspend-unsuspend \
  -p '{"spec": {"suspend": false}}'
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - kubectl edit | lowest | low (change visible before save) | high |
| B - patch | low | low | high |
