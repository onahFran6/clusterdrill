# q108-04: Alias an external hostname with an ExternalName Service

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-04-externalname-service`

An application in namespace `q108-04-externalname-service` needs to reach a managed database at
the external hostname `db.internal.example.com`, but the application's config already hardcodes
the in-cluster name `billing-db` and cannot be changed.

Create a Service named `billing-db` in this namespace that maps the in-cluster DNS name
`billing-db.q108-04-externalname-service.svc.cluster.local` to `db.internal.example.com`, with no
selector and no ports.

## Hint

Search kubernetes.io/docs for **"ExternalName"** - the Service concept page's ExternalName
section shows `spec.type` and `spec.externalName`. This Service type only creates a DNS alias
(a CNAME record); it does not select pods or proxy traffic.
