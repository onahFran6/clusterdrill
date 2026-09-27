# q104-42: Fix green's config, then cut traffic over

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-42-blue-green-secret-config-cutover`

You'll find, in namespace `q104-42-blue-green-secret-config-cutover`:

- Secrets `app-config-blue` (`FEATURE_FLAG=off`) and `app-config-green` (`FEATURE_FLAG=on`)
- Deployment `billing-blue` (3 replicas, image `nginx:1.24-alpine`, labels `app=billing,
  version=blue`) - live; loads env from `app-config-blue` via `envFrom`
- Deployment `billing-green` (3 replicas, image `nginx:1.25-alpine`, labels `app=billing,
  version=green`) - Ready, but still loading env from `app-config-blue` instead of
  `app-config-green`
- Service `billing-svc` selecting `app=billing, version=blue`

Point `billing-green`'s `envFrom` at `app-config-green`, wait until all 3 green replicas are Ready
again, then change `billing-svc`'s selector to `app=billing, version=green`. Do not touch
`billing-blue` or either Secret.

## Hint

Search kubernetes.io/docs for **"envFrom secretRef"** - the "Define container environment
variables using Secret data" task shows how `envFrom.secretRef.name` picks which Secret a
container's environment comes from. Changing that field updates the pod template and triggers a
rollout, same as an image change - finish that before flipping the Service selector.
