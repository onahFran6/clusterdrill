# q104-42-blue-green-secret-config-cutover: Fix a config drift bug before a blue/green cutover

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-42-blue-green-secret-config-cutover`

`setup.sh` already created, in namespace `q104-42-blue-green-secret-config-cutover`:

- Secret `app-config-blue` (key `FEATURE_FLAG=off`) and Secret `app-config-green` (key
  `FEATURE_FLAG=on`).
- Deployment `billing-blue` (3 replicas, image `nginx:1.24-alpine`, labels `app=billing,
  version=blue`) - the current live version, loading its environment from `app-config-blue` via
  `envFrom`.
- Deployment `billing-green` (3 replicas, image `nginx:1.25-alpine`, labels `app=billing,
  version=green`) - the new version, already running with all 3 replicas Ready, but it has a bug:
  its `envFrom` still points at `app-config-blue` instead of `app-config-green`, a config drift
  left over from when it was cloned off the blue Deployment.
- Service `billing-svc` currently routes to blue via the selector `app=billing, version=blue`.

Before cutting traffic over, fix the config drift: change `billing-green`'s `envFrom` to reference
`app-config-green` instead of `app-config-blue`, and wait for it to finish rolling out with all 3
replicas Ready. Only then perform the blue/green cutover: change `billing-svc`'s selector to
`app=billing, version=green`. Do not touch `billing-blue` or either Secret.

## Hint

Search kubernetes.io/docs for **"envFrom secretRef"** - the "Define container environment
variables using Secret data" task shows how a container's `envFrom.secretRef.name` picks which
Secret its environment comes from, and how changing it (like changing an image) triggers a new
rollout.
