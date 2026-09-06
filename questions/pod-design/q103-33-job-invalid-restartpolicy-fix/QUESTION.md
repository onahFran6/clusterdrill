# q103-33: Fix a Job manifest the API server rejects outright

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-33-job-invalid-restartpolicy-fix`

`setup.sh` wrote a Job manifest to `~/practice-work/q103-33-job-invalid-restartpolicy-fix/broken-once.yaml`
in your terminal's working directory, but never applied it - trying to `kubectl apply` it as-is
fails validation:

```
error: Job.batch "broken-once" is invalid: spec.template.spec.restartPolicy:
Unsupported value: "Always": supported values: "OnFailure", "Never"
```

A Job's pod template cannot use `restartPolicy: Always` - unlike a Deployment's pods, a Job's pods
are expected to eventually stop running, and `Always` would make the kubelet restart the container
forever, so the Job could never reach a completed state at all.

Fix `broken-once.yaml` so it uses a `restartPolicy` the API server accepts, then apply it. Do not
change the container image (`busybox:1.36`), the command (`echo done`), or the Job's name. Once
applied, the Job must run to completion successfully exactly once (leave `.spec.completions` and
`.spec.parallelism` unset - the default single-run behavior is correct here).

## Hint

Search kubernetes.io/docs for **"job pod restart policy"** - the Jobs concept page's "Pod
Template" section explains why `.spec.template.spec.restartPolicy` must be `Never` or `OnFailure`
for a Job, never `Always`.
