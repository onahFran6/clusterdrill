# q108-25: Add a missing readinessProbe so a Service starts reporting endpoints

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-25-add-readiness-gate-to-populate-endpoints`

A Deployment named `search-index` (image `nginx:1.25`, 2 replicas,
container port `80`) already exists in namespace
`q108-25-add-readiness-gate-to-populate-endpoints`, along with a Service named `search-index-svc`
whose selector matches the pod template's labels. The pods stay `Running` but are never marked
`Ready`, and `search-index-svc` has zero ready endpoints.

Fix the container's `readinessProbe` so it succeeds: set `httpGet.path` to `/` (the path
`nginx:1.25` serves with a `200` response). Do not change the probe's port and do not remove the
probe. Once the pods pass their readiness checks, `kubectl get endpoints search-index-svc` should
list 2 ready addresses.

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup probes"** - the "Define a
readiness probe" example shows `readinessProbe.httpGet.path`. A probe that requests a path the
image does not serve (this one currently uses `/health`) keeps the pod out of the Ready condition,
and a Service only puts Ready addresses into its endpoints.
