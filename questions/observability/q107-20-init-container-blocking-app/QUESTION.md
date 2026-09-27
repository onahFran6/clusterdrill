# q107-20: Diagnose an init container stuck in Init state blocking app startup

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-20-init-container-blocking-app`

A pod named `report-gen` already exists in namespace `q107-20-init-container-blocking-app`. It
has one init container named `wait-for-config` (image `busybox:1.36`) and one main container
named `app` (image `nginx:1.25-alpine`). The pod is stuck at `Init:0/1`, so the main container
never starts.

Get the pod to `Running`:

- create a `ClusterIP` Service named `config-svc` in this namespace that exposes port `80` and
  selects pods with label `app: report-gen`
- add the label `app: report-gen` to the `report-gen` pod
- do not delete the pod; patch it in place

## Hint

Search kubernetes.io/docs for **"Debug Init Containers"** - the Debug Pods task shows how to read
an init container's status and logs with `kubectl describe pod` and `kubectl logs -c
<init-container-name>` to find out what it's actually waiting on. `wait-for-config` loops on an
`nslookup` of `config-svc` in this namespace, and that Service does not exist yet. The pod also
has no `app: report-gen` label, so the Service would have no matching endpoints until you add it.
Once the name resolves, the init container's next retry can finish and the main container can
start.
