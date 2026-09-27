# q110-30-crd-crossnamespace-count-and-cleanup: Audit CRD instances across namespaces and delete only invalid ones

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-30-crd-crossnamespace-count-and-cleanup`

A namespaced CustomResourceDefinition `endpointprobes.monitoring.clusterdrill.io` (group
`monitoring.clusterdrill.io/v1`, kind `EndpointProbe`, plural `endpointprobes`) is installed.
Its schema requires `spec.url` (string) and `spec.intervalSeconds` (integer, minimum `5`).

EndpointProbe instances exist in this namespace and in
`q110-30-crd-crossnamespace-count-and-cleanup-b`. Some were created before the minimum
constraint existed and still violate it.

Find every EndpointProbe across both namespaces whose `spec.intervalSeconds` is less than `5`,
and delete only those. Leave every probe with `intervalSeconds` of `5` or greater untouched.
Do not delete, edit, or recreate the CRD, and do not delete any namespace.

## Hint

Search kubernetes.io/docs for **"kubectl get customresourcedefinition"** and **"custom resources
across namespaces"** - `kubectl get <plural> -A -o jsonpath` (or `-o json` piped through `jq`)
lists every instance cluster-wide with its namespace and a spec field, so you can filter on
`spec.intervalSeconds` before deleting matches with `kubectl delete <plural> <name> -n
<namespace>`.
