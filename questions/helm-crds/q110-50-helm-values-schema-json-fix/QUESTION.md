# q110-50-helm-values-schema-json-fix: Fix a values.schema.json constraint that's now too strict

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-50-helm-values-schema-json-fix`

`setup.sh` staged a local Helm chart named `worker-pool` on disk at
`questions/helm-crds/q110-50-helm-values-schema-json-fix/chart` (relative to the
`practice-bank/` directory). Its `values.schema.json` declares `replicaCount` as an integer with
`"maximum": 3` - a limit set back when this chart's workload was small. The team now needs to
scale it to `5` replicas for a traffic spike, but `helm install ... --set replicaCount=5` is
rejected outright before anything even reaches the cluster: `values don't meet the
specifications of the schema(s)`.

Raise `values.schema.json`'s `replicaCount.maximum` to `10` (leave every other field in the
schema alone), then install the chart into namespace `q110-50-helm-values-schema-json-fix` under
release name `demo` with `--set replicaCount=5`.

## Hint

Search kubernetes.io/docs for **"helm values.schema.json"** - the Helm Charts Guide's "Schema
Files" section explains that a chart may ship a `values.schema.json` (standard JSON Schema) that
Helm validates the final merged values against before rendering any templates - a value that
would otherwise render into an invalid manifest is rejected up front instead, but a
too-strict constraint has to be fixed in the schema file itself, not worked around with a
different flag.
