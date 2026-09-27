# q101-46: Unstick a Deployment whose Pods never become Ready

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-46-fix-stuck-rollout-bad-readiness-probe`

A Deployment named `web-front` (image `nginx:1.25-alpine`, 3 replicas) already exists in
namespace `q101-46-fix-stuck-rollout-bad-readiness-probe`. Every Pod is `Running` but none ever
turn `Ready`, so the Deployment never finishes rolling out.

Investigate with `kubectl describe pod` on one of `web-front`'s Pods and/or `kubectl get events`,
then fix it imperatively so that:

- `web-front` keeps the same image, replica count, and container name.
- The readiness probe's HTTP path points at a path nginx actually serves (`/`).
- `web-front` reaches `status.readyReplicas=3`.

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup probes"** - the Configure
Probes task page shows the `httpGet.path`/`port` fields a readiness probe checks, and how a wrong
path leaves every container `Running` but perpetually not `Ready`.
