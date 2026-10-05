# q103-18: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/

**Approach A - Fastest (exam default).** `kubectl edit cronjob data-sync -n
q103-18-cronjob-fix-job-template`, then in vim find the broken image and change it in place -
the fix is visible on screen before you save, unlike a hand-typed JSON path:

```text
/busybox:this-tag-does-not-exist
ciwbusybox:1.36<Esc>
:wq
```

**Approach B - Scripted equivalent (what this file executes).** A JSON patch reaches the same
result non-interactively - this repo's automated grading runs exactly this, since an editor
session isn't scriptable:

```sh
kubectl patch cronjob data-sync -n q103-18-cronjob-fix-job-template \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/image", "value": "busybox:1.36"}]'
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - kubectl edit | low | low (change visible before save) | high |
| B - JSON patch | medium | medium (a path typo fails silently or patches the wrong field) | medium |
