# q108-25-add-readiness-gate-to-populate-endpoints: Add a missing readinessProbe so a Service starts reporting endpoints

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-25-add-readiness-gate-to-populate-endpoints`

`setup.sh` already created a Deployment named `search-index` (image `nginx:1.25`, 2 replicas,
container port `80`) in namespace `q108-25-add-readiness-gate-to-populate-endpoints`, along with a
Service named `search-index-svc` whose selector correctly matches the pod template's labels.

The container's `readinessProbe` sends an HTTP GET to path `/health` on port `80`, but the
`nginx:1.25` image never serves that path, so every probe fails. The pods stay `Running` but are
never marked `Ready`, and `search-index-svc` ends up with zero ready endpoints even though the
Service's selector is fine.

Fix the `readinessProbe` so it succeeds: change the probe's `httpGet.path` to `/` (the path nginx
actually serves with a `200` response). Do not change the probe's port and do not remove the
probe. Once the pods pass their readiness checks, `kubectl get endpoints search-index-svc` should
list 2 ready addresses.

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup probes"** - the "Define a
readiness probe" example shows the `readinessProbe.httpGet.path` field you need to edit here.
