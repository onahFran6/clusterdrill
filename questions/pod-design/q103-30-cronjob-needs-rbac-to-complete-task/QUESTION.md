# q103-30: Grant a CronJob's ServiceAccount the RBAC it needs to finish its job

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-30-cronjob-needs-rbac-to-complete-task`

A CronJob named `status-recorder` already exists in namespace
`q103-30-cronjob-needs-rbac-to-complete-task`. Each run records that it ran by patching
`data.last_run_status` on a ConfigMap named `job-status` in the same namespace, using its
in-cluster credentials. It exits `0` on success.

The CronJob's pods run as ServiceAccount `status-recorder-sa`. Every run fails. Inspect a recent
run to see why.

Fix this so `status-recorder-sa` can finish the job:

1. Grant `status-recorder-sa` `patch` and `update` on the `job-status` ConfigMap in this
   namespace, with a `Role` and `RoleBinding`. Do not grant access outside this namespace, and
   do not rename the CronJob, the ServiceAccount, or the ConfigMap.
2. Trigger one fresh run of `status-recorder` without waiting for the schedule. It must complete
   successfully, and `job-status`'s `data.last_run_status` must change from `never-run`.

## Hint

Search kubernetes.io/docs for **"Role and RoleBinding"** - the RBAC concept page shows how to
bind a namespaced Role's verbs (`patch` and `update`) to a ServiceAccount. Create the run with
`kubectl create job --from=cronjob/status-recorder`. The container log shows the patch being
rejected until the Role allows it.
