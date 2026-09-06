# q107-20: Diagnose an init container stuck in Init state blocking app startup

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-20-init-container-blocking-app`

`setup.sh` already created a pod named `report-gen` in namespace
`q107-20-init-container-blocking-app`. It has one init container named `wait-for-config`
(image `busybox:1.36`) that loops doing an `nslookup` against
`config-svc.q107-20-init-container-blocking-app.svc.cluster.local` until it succeeds, and one
main container named `app` (image `nginx:1.25-alpine`). `kubectl get pod report-gen -n
q107-20-init-container-blocking-app` currently shows `STATUS Init:0/1` - the init container never
finishes because the `config-svc` Service it is waiting on does not exist, so the main container
never starts.

Investigate with `kubectl describe pod` and/or `kubectl logs -c wait-for-config`, then fix the
situation so the pod reaches `Running`:

- create a plain `ClusterIP` Service named `config-svc` in namespace
  `q107-20-init-container-blocking-app` that exposes port `80` and selects pods matching label
  `app: report-gen`
- add the label `app: report-gen` to the existing `report-gen` pod's metadata (it has no such
  label yet, so the Service would otherwise have no matching endpoints)

Do not delete or recreate the `report-gen` pod - edit/patch it in place so its init container's
next retry succeeds. Once `config-svc` resolves, the init container should exit successfully and
the main container should start.

## Hint

Search kubernetes.io/docs for **"Debug Init Containers"** - the Debug Pods task shows how to read
an init container's status and logs with `kubectl describe pod` and `kubectl logs -c
<init-container-name>` to find out what it's actually waiting on.
