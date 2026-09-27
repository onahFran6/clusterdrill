# q103-33: Fix a Job manifest the API server rejects outright

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-33-job-invalid-restartpolicy-fix`

A Job manifest is at `~/practice-work/q103-33-job-invalid-restartpolicy-fix/broken-once.yaml`
in your terminal's working directory. It has not been applied. `kubectl apply` rejects it.

Fix `broken-once.yaml` so the API server accepts it, then apply it. Do not change the container
image (`busybox:1.36`), the command (`echo done`), or the Job's name. Once applied, the Job must
complete successfully exactly once. Leave `.spec.completions` and `.spec.parallelism` unset.

## Hint

Search kubernetes.io/docs for **"job pod restart policy"** - the Jobs concept page's "Pod
Template" section explains why `.spec.template.spec.restartPolicy` must be `Never` or
`OnFailure` for a Job, never `Always`. Applying the manifest as written fails with:

```
error: Job.batch "broken-once" is invalid: spec.template.spec.restartPolicy:
Unsupported value: "Always": supported values: "OnFailure", "Never"
```

`Always` would restart the container forever, so the Job could never complete.
