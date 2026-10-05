# q103-33: Fix a Job manifest the API server rejects outright

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-33-job-invalid-restartpolicy-fix`

Vector Bioinformatics Lab's platform team drafted a one-shot Job manifest to run a
data-migration script, but nobody's applied it yet. It's sitting at
`~/practice-work/q103-33-job-invalid-restartpolicy-fix/broken-once.yaml` in your terminal's
working directory. `kubectl apply` rejects it outright.

Fix `broken-once.yaml` so the API server accepts it, then apply it. Do not change the container
image (`busybox:1.36`), the command (`echo done`), or the Job's name. Once applied, the Job must
complete successfully exactly once. Leave `.spec.completions` and `.spec.parallelism` unset.

## Hint

Run `kubectl apply -f broken-once.yaml` to see exactly why the API server rejects it. Then
search kubernetes.io/docs for **"job pod restart policy"** - the Jobs concept page's "Pod
Template" section explains which restart policies a Job's pod template accepts.
