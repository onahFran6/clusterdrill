# q106-49: Grant access to a non-resource API URL, not a Kubernetes resource

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-49-clusterrole-nonresourceurl-healthz`

A ServiceAccount named `health-prober` already exists in this namespace. Create a ClusterRole
named `q106-49-healthz-prober` and a ClusterRoleBinding that together let `health-prober` `GET`
`/healthz` and its subpaths (for example `/healthz/etcd`). Do not grant anything else, such as
`/metrics`.

Label the ClusterRole and ClusterRoleBinding with
`clusterdrill-question: q106-49-clusterrole-nonresourceurl-healthz`. They are cluster-scoped and
will not be removed just by deleting the namespace.

## Hint

Search kubernetes.io/docs for **"referring to resources"** - the RBAC reference page shows that a
`ClusterRole` rule can grant `nonResourceURLs` instead of `resources` and `apiGroups`. `/healthz`
is not a Kubernetes resource. A trailing `*` matches subpaths such as `/healthz/etcd`. A rule on
`resources` will not cover this endpoint.
