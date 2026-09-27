# q108-09: Resolve a Service's DNS name across namespaces

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-09-dns-resolve-cross-namespace`

A Pod named `netshoot` (image `nicolaka/netshoot:latest`, which stays
running) already exists in namespace `q108-09-dns-resolve-cross-namespace`. Every cluster also
has a built-in Service named `kubernetes` in the `default` namespace, fronting the API server.

From inside the `netshoot` pod, resolve that `kubernetes` Service. Create a ConfigMap named
`cross-ns-lookup-result` in this question's own namespace with a key `service-ip` whose value is
the resolved ClusterIP address.

## Hint

Search kubernetes.io/docs for **"DNS for Services and Pods"** - the DNS concept page's "What
things get DNS names" section covers the `<service>.<namespace>` and full
`<service>.<namespace>.svc.cluster.local` forms. An unqualified name such as `kubernetes` only
resolves inside the querying pod's own namespace.
