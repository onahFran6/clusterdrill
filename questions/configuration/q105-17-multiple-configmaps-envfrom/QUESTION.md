# q105-17: Combine two ConfigMaps into one container's environment

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-17-multiple-configmaps-envfrom`

Two ConfigMaps already exist in namespace `q105-17-multiple-configmaps-envfrom`:

- `db-config` with key `DB_HOST=db.internal`
- `cache-config` with key `CACHE_HOST=cache.internal`

A running Pod named `api-gateway` (image `nginx:1.25-alpine`) is also there, with no environment
configuration yet.

Edit the pod so its container ends up with both `DB_HOST=db.internal` and
`CACHE_HOST=cache.internal` available as environment variables at the same time, importing every
key from both ConfigMaps without listing the keys one by one. The pod will need to be recreated
for the change to take effect.

## Hint

Search kubernetes.io/docs for **"envFrom"** - the EnvFromSource API reference shows that a
container's `envFrom` field takes a list, so more than one ConfigMap (or Secret) source can be
combined in a single container spec.
