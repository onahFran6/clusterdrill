# q108-08: Prove in-cluster DNS resolution from another pod

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-08-dns-resolve-same-namespace`

A Deployment named `inventory` (image `httpd:2.4-alpine`, 2 replicas,
container port `80`, pod-template label `app=inventory`), a ClusterIP Service named
`inventory-svc` selecting it, and a separate Pod named `netshoot` (image
`nicolaka/netshoot:latest`, which stays running by sleeping) already exist in namespace
`q108-08-dns-resolve-same-namespace`.

From inside the `netshoot` pod, resolve `inventory-svc` and record the result. Create a ConfigMap
named `dns-lookup-result` in the same namespace with a key `service-ip` whose value is the
ClusterIP that name resolves to.

## Hint

Search kubernetes.io/docs for **"DNS for Services and Pods"** - the DNS concept page explains that
a Service gets an A/AAAA record of the form `<service>.<namespace>.svc.cluster.local`, and that
`nslookup inventory-svc` from a pod in the same namespace returns the Service's ClusterIP.
