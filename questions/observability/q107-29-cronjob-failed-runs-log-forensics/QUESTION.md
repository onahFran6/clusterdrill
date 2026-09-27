# q107-29: Investigate failed CronJob runs by reading logs from completed Job pods and fix the underlying script bug

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-29-cronjob-failed-runs-log-forensics`

A CronJob named `nightly-cleanup` already exists in namespace
`q107-29-cronjob-failed-runs-log-forensics`, scheduled every minute (`*/1 * * * *`) with
`concurrencyPolicy: Forbid` and `backoffLimit: 1`. Its runs have failed, leaving failed Jobs and
Pods behind. A ConfigMap named `cleanup-manifest` already exists in this namespace with a key
`manifest.txt` (content `cleanup-list-v1`).

Fix `nightly-cleanup`'s `jobTemplate` pod spec:

- add a volume named `data` that sources the `cleanup-manifest` ConfigMap
- mount that volume at `/data` in the container

Do not change the CronJob's name, schedule, `concurrencyPolicy`, `backoffLimit`, or command.
A subsequent run of `nightly-cleanup` must succeed (`.status.succeeded: 1` on its Job).

## Hint

Search kubernetes.io/docs for **"populate a volume with configmap data"** - the Configure a Pod
to Use a ConfigMap task shows how to add a `configMap` volume to a pod spec and mount it into a
container, which is what a CronJob's `.spec.jobTemplate.spec.template.spec` needs here. The
container runs `cat /data/manifest.txt` and exits non-zero because nothing is mounted at `/data`.
Check the failed Job's pods with `kubectl get jobs` and `kubectl get pods --show-labels`, then
read one pod's logs.
