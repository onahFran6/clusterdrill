# q108-08: Prove in-cluster DNS resolution from another pod

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-08-dns-resolve-same-namespace`

`setup.sh` already created a Deployment named `inventory` (image `httpd:2.4-alpine`, 2 replicas,
container port `80`, pod-template label `app=inventory`), a ClusterIP Service named
`inventory-svc` selecting it, and a separate Pod named `netshoot` (image
`nicolaka/netshoot:latest`, which stays running by sleeping) - all in namespace
`q108-08-dns-resolve-same-namespace`.

From inside the `netshoot` pod, resolve the Service's cluster-local DNS name and record the
result. Create a ConfigMap named `dns-lookup-result` in the same namespace with a key `service-ip`
whose value is the ClusterIP address that `nslookup inventory-svc` (run from the `netshoot` pod)
resolves to.

## Hint

Search kubernetes.io/docs for **"DNS for Services and Pods"** - the DNS concept page explains that
a Service gets an A/AAAA record of the form `<service>.<namespace>.svc.cluster.local`, and that a
plain `nslookup <service-name>` from a pod in the same namespace resolves it directly.
