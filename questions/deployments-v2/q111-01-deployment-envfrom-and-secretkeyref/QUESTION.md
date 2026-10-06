# q111-01: Build a fully configured Deployment

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-01-deployment-envfrom-and-secretkeyref`

Team Apollo is moving its API onto Kubernetes. Their config lives in ConfigMap `api-config` and
their credentials in Secret `api-creds`, both already seeded in this namespace.

- Create Deployment `api` with **3** replicas of `nginx:1.27`. The container must be named `api`,
  and pods must carry the extra label `tier: backend`.
- Every key in `api-config` must become an env var with the same name.
- Only the Secret's `DB_PASSWORD` key may reach the container, as env var `DATABASE_PASSWORD`.
- Add env var `APP_ENV=staging`.
- Each container requests **100m** CPU and **64Mi** memory, and is limited to **128Mi** memory.
- Verify all four end up visible inside a running pod: `LOG_LEVEL`, `REGION`, `APP_ENV`,
  `DATABASE_PASSWORD`.

## Hint

Search kubernetes.io/docs for **"envFrom"** - the "Define Container Environment Variables Using
ConfigMap Data" and "Define Container Environment Variables Using Secret Data" tasks show both
patterns side by side. One of them imports every key at once; the other lets you pick a single
key and rename it with `secretKeyRef`. Scaffold with `kubectl create deployment --dry-run=client
-o yaml` first - the container name it generates is not `api`.
