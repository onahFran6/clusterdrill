# q105-46-configmap-missing-mount-pending: Diagnose a Deployment stuck on a missing ConfigMap volume

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-46-configmap-missing-mount-pending`

`setup.sh` already created a Deployment named `report-generator` (1 replica, image
`nginx:1.25-alpine`) in namespace `q105-46-configmap-missing-mount-pending`. Its pod template
mounts a ConfigMap named `settings-config` as a volume - but that ConfigMap does not exist, so the
pod is stuck (not `CrashLoopBackOff` - it never even starts its container). No ConfigMap exists
yet.

Inspect the pod's events (`kubectl describe pod ...`) to see the exact volume-mount failure, then
create the missing ConfigMap named `settings-config` with a key `MODE` set to `production` -
matching what the Deployment's volume already expects by name. Do not change the Deployment
itself. Once the ConfigMap exists, the pod's volume should mount successfully and the Deployment
should reach `1/1` ready replicas.

## Hint

Search kubernetes.io/docs for **"configure a pod to use a configmap"** - the Configure a Pod to
Use a ConfigMap task's troubleshooting notes explain that a Pod referencing a ConfigMap volume
that does not exist stays unscheduled/pending with a `FailedMount` event until the ConfigMap is
created.
