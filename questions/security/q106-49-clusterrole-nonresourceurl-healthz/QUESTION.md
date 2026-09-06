# q106-49: Grant access to a non-resource API URL, not a Kubernetes resource

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-49-clusterrole-nonresourceurl-healthz`

A ServiceAccount named `health-prober` already exists in this namespace. Create a ClusterRole named
`q106-49-healthz-prober` and a ClusterRoleBinding that together let `health-prober` `GET` the
API server's `/healthz` endpoint and its subpaths (e.g. `/healthz/etcd`) - but nothing else, such
as `/metrics`. This endpoint is not a Kubernetes resource, so the grant must use `nonResourceURLs`,
not `resources`.

**Important:** label the ClusterRole and ClusterRoleBinding you create with
`clusterdrill-question: q106-49-clusterrole-nonresourceurl-healthz` so cleanup can find them -
they are cluster-scoped and will not be removed just by deleting the namespace.

## Hint

Search kubernetes.io/docs for **"referring to resources"** - the RBAC reference page shows that a
`ClusterRole` rule can grant `nonResourceURLs` instead of `resources`/`apiGroups`, for endpoints
like `/healthz` that aren't backed by a Kubernetes API resource, and that a trailing `*` matches
subpaths.
