# q110-35-crd-schema-default-value: Add a schema default so an omitted field still gets a value

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-35-crd-schema-default-value`

A CustomResourceDefinition `queues.jobs.clusterdrill.io` (kind *Queue*, plural `queues`, group
`jobs.clusterdrill.io/v1`, namespaced) is registered. Its schema requires `spec.name` (string)
and leaves `spec.priority` (integer) optional with no default.

Patch the CRD so `spec.priority` defaults to `5` while staying optional (do not add it to
`required`). Leave `spec.name`'s schema unchanged. Then create a *Queue* named `batch-job` in
this namespace with only `spec.name: "batch-job"` - do not set `spec.priority` yourself - and
confirm the API server fills in `spec.priority: 5`.

## Hint

Search kubernetes.io/docs for **"CustomResourceDefinition" "defaulting"** - the CRD docs'
Defaulting section shows `default` as a standard OpenAPI schema keyword the API server applies
to a field the moment an object is created (or updated) without that field set, exactly the way
built-in resources default fields like `spec.replicas`.
