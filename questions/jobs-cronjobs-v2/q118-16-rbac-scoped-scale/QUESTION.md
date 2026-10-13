# q118-16: Give the night scaler only scale access

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-16-rbac-scoped-scale`

Team Triton has *Deployment* `web` with three replicas.
Create *ServiceAccount* `night-scaler`, a same-named namespaced *Role* allowing only `get` and `patch` on `deployments/scale`, and bind it to that account.
Create *CronJob* `night-scale` using `curlimages/curl:8.10.1` at **22:00 Lagos time** daily.
Using its own ServiceAccount token and the Kubernetes API scale endpoint, it must set `web` to one replica.
Trigger *Job* `night-scale-now`, confirm an HTTP 200 log, and verify the replica count.
Do not grant cluster-wide access or access to whole Deployments.

## Hint

Search kubernetes.io/docs for "RBAC referring to resources" and "access API from a Pod"; the scale subresource has its own resource name.
