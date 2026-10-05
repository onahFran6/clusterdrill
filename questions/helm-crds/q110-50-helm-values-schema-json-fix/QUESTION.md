# q110-50-helm-values-schema-json-fix: Fix a values.schema.json constraint that's now too strict

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-50-helm-values-schema-json-fix`

A local Helm chart named `worker-pool` is on disk at
`$HOME/practice-work/q110-50-helm-values-schema-json-fix/chart`.
Its `values.schema.json` declares `replicaCount` as an integer with `"maximum": 3`. Installing
with `--set replicaCount=5` is rejected before anything reaches the cluster.

Raise `values.schema.json`'s `replicaCount.maximum` to `10` (leave every other schema field
alone), then install the chart into this namespace as release `demo` with
`--set replicaCount=5`.

## Hint

Search kubernetes.io/docs for **"helm values.schema.json"** - the Helm Charts Guide's "Schema
Files" section explains that a chart may ship a `values.schema.json` (standard JSON Schema) that
Helm validates the final merged values against before rendering any templates - a value that
would otherwise render into an invalid manifest is rejected up front instead, but a
too-strict constraint has to be fixed in the schema file itself, not worked around with a
different flag.
