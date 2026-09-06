# q110-30-crd-crossnamespace-count-and-cleanup: Audit CRD instances across namespaces and delete only invalid ones

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-30-crd-crossnamespace-count-and-cleanup`

A namespaced CustomResourceDefinition `endpointprobes.monitoring.clusterdrill.io` (group `monitoring.clusterdrill.io/v1`, kind `EndpointProbe`, plural `endpointprobes`) is already installed on the cluster.
Its schema requires `spec.url` (string) and `spec.intervalSeconds` (integer, minimum `5`).

Two namespaces contain `EndpointProbe` instances: the primary namespace `q110-30-crd-crossnamespace-count-and-cleanup` and a second namespace `q110-30-crd-crossnamespace-count-and-cleanup-b`.
Some of these instances were force-created before the CRD's `minimum: 5` constraint existed, so they currently violate it even though the CRD itself now enforces the rule for any new writes.

Find every `EndpointProbe` object across **both** namespaces whose `spec.intervalSeconds` is less than `5`, and delete only those objects.
Every `EndpointProbe` with `spec.intervalSeconds` of `5` or greater must be left untouched in whichever namespace it lives in.
Do not delete, edit, or recreate the CRD itself, and do not delete any namespace.

## Hint

Search kubernetes.io/docs for **"kubectl get customresourcedefinition"** and **"custom resources across namespaces"** - `kubectl get <plural> -A -o jsonpath` (or `-o json` piped through `jq`) lets you list every instance of a custom resource cluster-wide along with its namespace and a specific spec field, so you can filter on `spec.intervalSeconds` before deleting the matching ones with `kubectl delete <plural> <name> -n <namespace>`.
