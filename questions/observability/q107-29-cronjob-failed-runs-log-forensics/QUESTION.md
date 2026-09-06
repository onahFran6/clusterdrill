# q107-29: Investigate failed CronJob runs by reading logs from completed Job pods and fix the underlying script bug

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-29-cronjob-failed-runs-log-forensics`

`setup.sh` already created a CronJob named `nightly-cleanup` in namespace
`q107-29-cronjob-failed-runs-log-forensics`, scheduled every minute
(`*/1 * * * *`) with `concurrencyPolicy: Forbid` and `backoffLimit: 1`. Every
run of it has already failed, leaving one or more failed Jobs and Pods behind.

Investigate:

1. Run `kubectl get jobs -n q107-29-cronjob-failed-runs-log-forensics` and
   `kubectl get pods -n q107-29-cronjob-failed-runs-log-forensics --show-labels`
   to find the failed Job's pod(s).
2. Run `kubectl logs <pod> -n q107-29-cronjob-failed-runs-log-forensics` on one
   of them to see why it fails - the container runs
   `cat /data/manifest.txt`, but nothing is mounted at `/data`, so `cat`
   errors with "No such file or directory" and the container exits non-zero.

A ConfigMap named `cleanup-manifest` already exists in this namespace with a
key `manifest.txt` (content `cleanup-list-v1`) - it was meant to be mounted
into the Job's pods all along.

Fix `nightly-cleanup`'s `jobTemplate` pod spec so the fix actually works:

- add a volume named `data` that sources the `cleanup-manifest` ConfigMap
- mount that volume at `/data` in the container

Do not change the CronJob's name, schedule, `concurrencyPolicy`, `backoffLimit`,
or command. After fixing it, verify a subsequent run of `nightly-cleanup`
actually succeeds (`.status.succeeded: 1` on its Job).

## Hint

Search kubernetes.io/docs for **"populate a volume with configmap data"** -
the Configure a Pod to Use a ConfigMap task shows how to add a `configMap`
volume to a pod spec and mount it into a container, which is exactly what a
CronJob's `.spec.jobTemplate.spec.template.spec` needs here.
