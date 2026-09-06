# q108-09: Resolve a Service's DNS name across namespaces

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-09-dns-resolve-cross-namespace`

`setup.sh` already created a Pod named `netshoot` (image `nicolaka/netshoot:latest`, which stays
running) in namespace `q108-09-dns-resolve-cross-namespace`. Every cluster also has a built-in
Service named `kubernetes` in the `default` namespace, fronting the API server.

A plain `nslookup kubernetes` from `netshoot` will fail, because unqualified Service names only
resolve within the querying pod's own namespace - reaching a Service that lives in a *different*
namespace requires at least the `<service>.<namespace>` form of its DNS name.

From inside the `netshoot` pod, resolve the `kubernetes` Service in the `default` namespace using
its fully qualified (or `<service>.<namespace>`) cluster-local DNS name. Create a ConfigMap named
`cross-ns-lookup-result` in this question's own namespace with a key `service-ip` whose value is
the resolved ClusterIP address.

## Hint

Search kubernetes.io/docs for **"DNS for Services and Pods"** - the DNS concept page's "What
things get DNS names" section covers the full `<service>.<namespace>.svc.cluster.local` form
needed to resolve a Service that lives in a different namespace than the querying pod.
