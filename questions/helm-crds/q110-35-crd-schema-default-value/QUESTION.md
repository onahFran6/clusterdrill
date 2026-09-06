# q110-35-crd-schema-default-value: Add a schema default so an omitted field still gets a value

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-35-crd-schema-default-value`

`setup.sh` already registered a CustomResourceDefinition `queues.jobs.clusterdrill.io` (kind
`Queue`, plural `queues`, group `jobs.clusterdrill.io/v1`, namespaced) whose schema requires
`spec.name` (string) but leaves `spec.priority` (integer) **optional with no default** - so an
instance that omits `spec.priority` simply has no `priority` field at all afterward, and every
consumer has to handle that missing-field case itself.

Patch the CRD so `spec.priority`'s schema carries `default: 5` (keep it optional - do not add it
to `required`). Do not change `spec.name`'s schema.

Once the schema is fixed, create an instance named `batch-job` in namespace
`q110-35-crd-schema-default-value` with only `spec.name: "batch-job"` set - **do not set
`spec.priority` yourself** - and confirm the API server fills in `spec.priority: 5`
automatically.

## Hint

Search kubernetes.io/docs for **"CustomResourceDefinition" "defaulting"** - the CRD docs'
Defaulting section shows `default` as a standard OpenAPI schema keyword the API server applies
to a field the moment an object is created (or updated) without that field set, exactly the way
built-in resources default fields like `spec.replicas`.
