# q107-14: Fix a manifest that uses a removed apiVersion

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-14-deprecated-apiversion-fix`

`setup.sh` wrote a manifest file to `$HOME/practice-work/q107-14-deprecated-apiversion-fix/q107-14-cronjob.yaml`
(this question's terminal working directory - shown above the terminal panel, and where a new
terminal tab starts) for a `CronJob` named `nightly-cleanup` that runs `busybox:1.36` with command
`["sh", "-c", "echo cleanup ran"]` on schedule `"0 2 * * *"`.
The manifest was copied from a very old tutorial and still declares `apiVersion: batch/v1beta1` -
an API version that was removed from Kubernetes entirely (not just deprecated) several releases
ago. Applying the file as-is fails with `no matches for kind "CronJob" in version "batch/v1beta1"`.

Fix the manifest and create the CronJob in namespace `q107-14-deprecated-apiversion-fix`:

- change `apiVersion` to the current, non-removed API group/version for `CronJob`
- keep the name `nightly-cleanup`, the schedule `"0 2 * * *"`, and the container image/command
  exactly as described above
- apply the corrected manifest so the `CronJob` actually exists in the cluster

## Hint

Search kubernetes.io/docs for **"CronJob"** - the workloads API reference and the CronJob concept
page both show the current `apiVersion` a `CronJob` manifest must use on a supported Kubernetes
version.
