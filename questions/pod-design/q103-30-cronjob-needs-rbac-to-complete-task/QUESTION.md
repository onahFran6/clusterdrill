# q103-30: Grant a CronJob's ServiceAccount the RBAC it needs to finish its job

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-30-cronjob-needs-rbac-to-complete-task`

`setup.sh` already created a CronJob named `status-recorder` in namespace
`q103-30-cronjob-needs-rbac-to-complete-task`. Each run's real job is to record that it ran: the
container patches `data.last_run_status` on a ConfigMap named `job-status` (in the same namespace)
using its own in-cluster credentials, then exits `0` on success or a non-zero code if the patch
itself failed.

The CronJob's pods run under a dedicated ServiceAccount, `status-recorder-sa`. Right now every run
fails - the container's own log shows the patch attempt being rejected. Inspect a recent run (or
trigger a fresh one) to see why.

Fix this so `status-recorder-sa` can actually complete the job:

1. Create whatever `Role` and `RoleBinding` are needed so `status-recorder-sa` can `patch`/`update`
   the `job-status` ConfigMap in this namespace. Do not loosen anything outside this namespace, and
   do not change the CronJob, the ServiceAccount, or the ConfigMap's name.
2. Trigger one fresh run of `status-recorder` (`kubectl create job --from=cronjob/status-recorder
   ...` - don't wait for the schedule) and confirm it completes successfully, and that
   `job-status`'s `data.last_run_status` field has actually changed from its original value of
   `never-run`.

## Hint

Search kubernetes.io/docs for **"Role and RoleBinding"** - the RBAC concept page shows how to bind
a namespaced Role's verbs (like `patch` and `update` on a resource) to a specific ServiceAccount
subject.
